package ir

import (
	"path"
	"strings"

	"google.golang.org/protobuf/compiler/protogen"
	"google.golang.org/protobuf/reflect/protoreflect"
)

func BuildFiles(plugin *protogen.Plugin) ([]*File, error) {
	files := make([]*File, 0, len(plugin.Files))
	for _, file := range plugin.Files {
		if !file.Generate {
			continue
		}
		files = append(files, buildFile(file))
	}
	return files, nil
}

func buildFile(file *protogen.File) *File {
	protoPath := file.Desc.Path()
	tsModule := strings.TrimSuffix(path.Base(protoPath), ".proto")
	moonPkg := "src/sdk"

	out := &File{
		ProtoPackage: string(file.Desc.Package()),
		ProtoPath:    protoPath,
		MoonPkg:      moonPkg,
		TsModule:     tsModule,
	}

	for _, enum := range file.Enums {
		if enum.Desc.Parent() != file.Desc {
			continue
		}
		out.Enums = append(out.Enums, buildEnum(enum))
	}

	for _, message := range file.Messages {
		if message.Desc.Parent() != file.Desc || message.Desc.IsMapEntry() {
			continue
		}
		out.Messages = append(out.Messages, buildMessage(message, out))
	}

	return out
}

func buildEnum(enum *protogen.Enum) *EnumDef {
	out := &EnumDef{Name: string(enum.Desc.Name())}
	for _, value := range enum.Values {
		out.Values = append(out.Values, &EnumValue{
			Name:   string(value.Desc.Name()),
			Number: int32(value.Desc.Number()),
		})
	}
	return out
}

func buildMessage(message *protogen.Message, file *File) *MessageDef {
	oneofs := map[protoreflect.Name]*OneofDef{}
	oneofOrder := make([]*OneofDef, 0, len(message.Oneofs))
	for _, oneof := range message.Oneofs {
		if oneof.Desc.IsSynthetic() {
			continue
		}
		def := &OneofDef{
			Name:     string(oneof.Desc.Name()),
			MoonName: sanitizeMoonFieldName(string(oneof.Desc.Name())),
			TsName:   protoJSONName(string(oneof.Desc.Name())),
		}
		oneofs[oneof.Desc.Name()] = def
		oneofOrder = append(oneofOrder, def)
	}

	out := &MessageDef{
		Name:   string(message.Desc.Name()),
		Oneofs: oneofOrder,
	}

	for _, field := range message.Fields {
		if field.Desc.IsWeak() {
			continue
		}
		def := buildField(field, file)
		if oneof := field.Oneof; oneof != nil && !oneof.Desc.IsSynthetic() {
			oneofName := string(oneof.Desc.Name())
			def.OneofName = oneofName
			if oneofDef, ok := oneofs[oneof.Desc.Name()]; ok {
				oneofDef.Fields = append(oneofDef.Fields, def)
			}
			continue
		}
		out.Fields = append(out.Fields, def)
	}

	filtered := out.Oneofs[:0]
	for _, oneof := range out.Oneofs {
		if len(oneof.Fields) > 0 {
			filtered = append(filtered, oneof)
		}
	}
	out.Oneofs = filtered

	return out
}

func buildField(field *protogen.Field, file *File) *FieldDef {
	out := &FieldDef{
		ProtoName: string(field.Desc.Name()),
		MoonName:  sanitizeMoonFieldName(string(field.Desc.Name())),
		JSONName:  field.Desc.JSONName(),
		Repeated:  field.Desc.Cardinality() == protoreflect.Repeated && !field.Desc.IsMap(),
		Optional:  field.Desc.HasPresence() && !field.Desc.IsList() && !field.Desc.IsMap() && field.Oneof == nil,
	}

	if field.Desc.IsMap() {
		out.Kind = KindMap
		out.Map = buildMap(field)
		return out
	}

	assignFieldKind(out, field, file)
	return out
}

func buildMap(field *protogen.Field) *MapDef {
	entry := field.Message
	keyField := entry.Fields[0]
	valueField := entry.Fields[1]
	key := &FieldDef{}
	assignFieldKind(key, keyField, nil)
	value := &FieldDef{}
	assignFieldKind(value, valueField, nil)
	return &MapDef{
		KeyKind:         key.Kind,
		ValueKind:       value.Kind,
		ValueTypeName:   value.TypeName,
		ValueTypeModule: value.TypeModule,
	}
}

func assignFieldKind(out *FieldDef, field *protogen.Field, file *File) {
	switch field.Desc.Kind() {
	case protoreflect.StringKind:
		out.Kind = KindString
	case protoreflect.BoolKind:
		out.Kind = KindBool
	case protoreflect.Int32Kind, protoreflect.Sint32Kind, protoreflect.Sfixed32Kind:
		out.Kind = KindInt32
	case protoreflect.Int64Kind, protoreflect.Sint64Kind, protoreflect.Sfixed64Kind:
		out.Kind = KindInt64
	case protoreflect.Uint32Kind, protoreflect.Fixed32Kind:
		out.Kind = KindUInt32
	case protoreflect.Uint64Kind, protoreflect.Fixed64Kind:
		out.Kind = KindUInt64
	case protoreflect.FloatKind:
		out.Kind = KindFloat
	case protoreflect.DoubleKind:
		out.Kind = KindDouble
	case protoreflect.BytesKind:
		out.Kind = KindBytes
	case protoreflect.EnumKind:
		if isWellKnownNull(string(field.Enum.Desc.FullName())) {
			out.Kind = KindNullValue
			return
		}
		out.Kind = KindEnum
		out.TypeName = string(field.Enum.Desc.Name())
		out.TypeModule = typeModule(file, field.Enum.Desc.ParentFile())
	case protoreflect.MessageKind:
		fullName := string(field.Message.Desc.FullName())
		if isDynamicJSON(fullName) {
			out.Kind = KindAny
			return
		}
		out.Kind = KindMessage
		out.TypeName = string(field.Message.Desc.Name())
		out.TypeModule = typeModule(file, field.Message.Desc.ParentFile())
	default:
		out.Kind = KindAny
	}
}

func typeModule(file *File, parent protoreflect.FileDescriptor) string {
	if file == nil || string(parent.Path()) == file.ProtoPath {
		return ""
	}
	return strings.TrimSuffix(path.Base(string(parent.Path())), ".proto")
}

func isDynamicJSON(typeName string) bool {
	switch typeName {
	case "google.protobuf.Struct", "google.protobuf.Value", "google.protobuf.ListValue", "google.protobuf.Any":
		return true
	default:
		return false
	}
}

func isWellKnownNull(typeName string) bool {
	return typeName == "google.protobuf.NullValue"
}

func sanitizeMoonFieldName(name string) string {
	name = strings.ToLower(name)
	if moonReservedWords[name] {
		return name + "_"
	}
	return name
}

func protoJSONName(name string) string {
	parts := strings.Split(name, "_")
	if len(parts) == 0 {
		return name
	}
	var out strings.Builder
	out.WriteString(parts[0])
	for _, part := range parts[1:] {
		if part == "" {
			continue
		}
		out.WriteString(strings.ToUpper(part[:1]))
		if len(part) > 1 {
			out.WriteString(part[1:])
		}
	}
	return out.String()
}

var moonReservedWords = map[string]bool{
	"as":     true,
	"alias":  true,
	"else":   true,
	"enum":   true,
	"for":    true,
	"if":     true,
	"impl":   true,
	"let":    true,
	"match":  true,
	"mut":    true,
	"pub":    true,
	"raise":  true,
	"ref":    true,
	"return": true,
	"self":   true,
	"struct": true,
	"type":   true,
	"type_":  true,
	"unsafe": true,
	"while":  true,
}
