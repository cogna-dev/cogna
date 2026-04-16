package emitter

import (
	"fmt"
	"path"
	"strings"

	"github.com/yufeiminds/codeiq/tools/protoc-gen-codeiq/internal/ir"
)

func EmitMoonBit(file *ir.File, version string) (string, string) {
	var sb strings.Builder
	if file.TsModule == "bundle" {
		writeGeneratedHeader(&sb, version, file.ProtoPath)
	}

	for _, enum := range file.Enums {
		writeMoonEnum(&sb, enum)
	}

	for _, message := range file.Messages {
		writeMoonOneofs(&sb, message)
		writeMoonMessage(&sb, message)
	}

	filename := path.Join(file.MoonPkg, file.TsModule+".mbt")
	return filename, sb.String()
}

func writeMoonEnum(sb *strings.Builder, enum *ir.EnumDef) {
	sb.WriteString("///|\n")
	sb.WriteString(fmt.Sprintf("pub(all) enum %s {\n", enum.Name))
	for _, value := range enum.Values {
		sb.WriteString(fmt.Sprintf("  %s\n", enumVariantName(value.Name)))
	}
	sb.WriteString("} derive(Eq, Debug)\n\n")

	sb.WriteString("///|\n")
	sb.WriteString(fmt.Sprintf("pub fn %s::to_json(self : %s) -> Json {\n", enum.Name, enum.Name))
	sb.WriteString("  match self {\n")
	for _, value := range enum.Values {
		sb.WriteString(fmt.Sprintf("    %s::%s => Json::string(\"%s\")\n", enum.Name, enumVariantName(value.Name), value.Name))
	}
	sb.WriteString("  }\n")
	sb.WriteString("}\n\n")

	sb.WriteString("///|\n")
	sb.WriteString(fmt.Sprintf("pub fn %s::from_json(j : Json) -> %s? {\n", enum.Name, enum.Name))
	sb.WriteString("  match j {\n")
	for _, value := range enum.Values {
		sb.WriteString(fmt.Sprintf("    String(\"%s\") => Some(%s::%s)\n", value.Name, enum.Name, enumVariantName(value.Name)))
	}
	sb.WriteString("    _ => None\n")
	sb.WriteString("  }\n")
	sb.WriteString("}\n\n")
}

func writeMoonOneofs(sb *strings.Builder, message *ir.MessageDef) {
	for _, oneof := range message.Oneofs {
		sb.WriteString("///|\n")
		sb.WriteString(fmt.Sprintf("pub(all) enum %s%s {\n", message.Name, oneofTypeName(oneof)))
		for _, field := range oneof.Fields {
			sb.WriteString(fmt.Sprintf("  %s(%s)\n", oneofVariantName(field), moonFieldTypeForOneof(field)))
		}
		sb.WriteString("} derive(Eq)\n\n")
	}
}

func writeMoonMessage(sb *strings.Builder, message *ir.MessageDef) {
	sb.WriteString("///|\n")
	sb.WriteString(fmt.Sprintf("pub(all) struct %s {\n", message.Name))
	for _, field := range message.Fields {
		sb.WriteString(fmt.Sprintf("  %s : %s\n", field.MoonName, moonFieldType(field)))
	}
	for _, oneof := range message.Oneofs {
		sb.WriteString(fmt.Sprintf("  %s : %s?\n", oneof.MoonName, oneofQualifiedType(message, oneof)))
	}
	sb.WriteString("} derive(Eq)\n\n")

	writeMoonMessageToJSON(sb, message)
	writeMoonMessageFromJSON(sb, message)
	writeMoonMessageStringWrappers(sb, message.Name)

	for _, oneof := range message.Oneofs {
		writeMoonOneofJSON(sb, message, oneof)
	}
}

func writeMoonMessageToJSON(sb *strings.Builder, message *ir.MessageDef) {
	sb.WriteString("///|\n")
	sb.WriteString(fmt.Sprintf("pub fn %s::to_json(self : %s) -> Json {\n", message.Name, message.Name))
	sb.WriteString("  let obj : Map[String, Json] = {}\n")
	for _, field := range message.Fields {
		writeMoonToJSONField(sb, "self.", field)
	}
	for _, oneof := range message.Oneofs {
		sb.WriteString(fmt.Sprintf("  match self.%s {\n", oneof.MoonName))
		sb.WriteString("    Some(v) => {\n")
		sb.WriteString("      let oneof_obj = v.to_json()\n")
		sb.WriteString("      guard oneof_obj is Object(oneof_fields) else { return Json::object(obj) }\n")
		sb.WriteString("      for key, value in oneof_fields {\n")
		sb.WriteString("        obj[key] = value\n")
		sb.WriteString("      }\n")
		sb.WriteString("    }\n")
		sb.WriteString("    None => ()\n")
		sb.WriteString("  }\n")
	}
	sb.WriteString("  Json::object(obj)\n")
	sb.WriteString("}\n\n")
}

func writeMoonMessageFromJSON(sb *strings.Builder, message *ir.MessageDef) {
	sb.WriteString("///|\n")
	sb.WriteString(fmt.Sprintf("pub fn %s::from_json(j : Json) -> %s? {\n", message.Name, message.Name))
	needsObjectBinding := len(message.Fields) > 0
	for _, field := range message.Fields {
		if field.OneofName == "" {
			needsObjectBinding = true
			break
		}
	}
	if needsObjectBinding {
		sb.WriteString("  guard j is Object(obj) else { return None }\n")
	} else {
		sb.WriteString("  guard j is Object(_) else { return None }\n")
	}
	for _, field := range message.Fields {
		writeMoonFromJSONField(sb, field)
	}
	for _, oneof := range message.Oneofs {
		sb.WriteString(fmt.Sprintf("  let %s : %s? = %s::from_json(j)\n", oneof.MoonName, oneofQualifiedType(message, oneof), oneofQualifiedType(message, oneof)))
	}
	sb.WriteString(fmt.Sprintf("  Some({ %s })\n", moonConstructorFields(message)))
	sb.WriteString("}\n\n")
}

func writeMoonMessageStringWrappers(sb *strings.Builder, typeName string) {
	sb.WriteString("///|\n")
	sb.WriteString(fmt.Sprintf("pub fn %s::to_json_string(self : %s) -> Result[String, String] {\n", typeName, typeName))
	sb.WriteString("  Ok(self.to_json().stringify())\n")
	sb.WriteString("}\n\n")
	sb.WriteString("///|\n")
	sb.WriteString(fmt.Sprintf("pub fn %s::from_json_string(s : String) -> Result[%s, String] {\n", typeName, typeName))
	sb.WriteString("  let parsed = try? @json.parse(s)\n")
	sb.WriteString("  guard parsed is Ok(value) else { return Err(\"invalid json\") }\n")
	sb.WriteString(fmt.Sprintf("  match %s::from_json(value) {\n", typeName))
	sb.WriteString("    Some(out) => Ok(out)\n")
	sb.WriteString("    None => Err(\"type mismatch\")\n")
	sb.WriteString("  }\n")
	sb.WriteString("}\n\n")
}

func writeMoonOneofJSON(sb *strings.Builder, message *ir.MessageDef, oneof *ir.OneofDef) {
	typeName := oneofQualifiedType(message, oneof)
	sb.WriteString("///|\n")
	sb.WriteString(fmt.Sprintf("pub fn %s::to_json(self : %s) -> Json {\n", typeName, typeName))
	sb.WriteString("  match self {\n")
	for _, field := range oneof.Fields {
		sb.WriteString(fmt.Sprintf("    %s::%s(value) => {\n", typeName, oneofVariantName(field)))
		sb.WriteString("      let obj : Map[String, Json] = {}\n")
		sb.WriteString(fmt.Sprintf("      obj[\"%s\"] = %s\n", field.JSONName, moonToJSONExpr("value", field)))
		sb.WriteString("      Json::object(obj)\n")
		sb.WriteString("    }\n")
	}
	sb.WriteString("  }\n")
	sb.WriteString("}\n\n")

	sb.WriteString("///|\n")
	sb.WriteString(fmt.Sprintf("pub fn %s::from_json(j : Json) -> %s? {\n", typeName, typeName))
	sb.WriteString("  guard j is Object(obj) else { return None }\n")
	for _, field := range oneof.Fields {
		sb.WriteString(fmt.Sprintf("  match obj.get(\"%s\") {\n", field.JSONName))
		sb.WriteString(fmt.Sprintf("    Some(value) => match (%s) {\n", moonParseExpr("value", field)))
		sb.WriteString(fmt.Sprintf("      Some(parsed) => return Some(%s::%s(parsed))\n", typeName, oneofVariantName(field)))
		sb.WriteString("      None => return None\n")
		sb.WriteString("    }\n")
		sb.WriteString("    None => ()\n")
		sb.WriteString("  }\n")
	}
	sb.WriteString("  None\n")
	sb.WriteString("}\n\n")
}

func writeMoonToJSONField(sb *strings.Builder, prefix string, field *ir.FieldDef) {
	fieldExpr := prefix + field.MoonName
	if field.Optional {
		sb.WriteString(fmt.Sprintf("  match %s {\n", fieldExpr))
		sb.WriteString(fmt.Sprintf("    Some(value) => obj[\"%s\"] = %s\n", field.JSONName, moonToJSONExpr("value", field)))
		sb.WriteString("    None => ()\n")
		sb.WriteString("  }\n")
		return
	}
	if field.Kind == ir.KindMap {
		sb.WriteString(fmt.Sprintf("  obj[\"%s\"] = %s\n", field.JSONName, moonMapToJSONExpr(fieldExpr, field.Map)))
		return
	}
	if field.Repeated {
		sb.WriteString(fmt.Sprintf("  obj[\"%s\"] = Json::array(%s.map(fn(item) { %s }))\n", field.JSONName, fieldExpr, moonToJSONExpr("item", field)))
		return
	}
	sb.WriteString(fmt.Sprintf("  obj[\"%s\"] = %s\n", field.JSONName, moonToJSONExpr(fieldExpr, field)))
}

func writeMoonFromJSONField(sb *strings.Builder, field *ir.FieldDef) {
	if field.Optional {
		sb.WriteString(fmt.Sprintf("  let %s : %s = match obj.get(\"%s\") {\n", field.MoonName, moonFieldType(field), field.JSONName))
		sb.WriteString(fmt.Sprintf("    Some(value) => (%s)\n", moonParseExpr("value", field)))
		sb.WriteString("    None => None\n")
		sb.WriteString("  }\n")
		return
	}
	sb.WriteString(fmt.Sprintf("  let %s : %s = match obj.get(\"%s\") {\n", field.MoonName, moonFieldType(field), field.JSONName))
	sb.WriteString(fmt.Sprintf("    Some(value) => match (%s) {\n", moonParseExpr("value", field)))
	sb.WriteString("      Some(parsed) => parsed\n")
	sb.WriteString("      None => return None\n")
	sb.WriteString("    }\n")
	sb.WriteString("    None => return None\n")
	sb.WriteString("  }\n")
}

func moonToJSONExpr(valueExpr string, field *ir.FieldDef) string {
	switch field.Kind {
	case ir.KindString:
		return fmt.Sprintf("Json::string(%s)", valueExpr)
	case ir.KindBool:
		return fmt.Sprintf("Json::boolean(%s)", valueExpr)
	case ir.KindInt32, ir.KindUInt32:
		return fmt.Sprintf("Json::number((%s).to_double(), repr=\"\\{%s}\")", valueExpr, valueExpr)
	case ir.KindInt64:
		return fmt.Sprintf("Json::number((%s).to_double(), repr=\"\\{%s}\")", valueExpr, valueExpr)
	case ir.KindUInt64:
		return fmt.Sprintf("Json::number((%s).to_int64().to_double(), repr=\"\\{%s}\")", valueExpr, valueExpr)
	case ir.KindFloat, ir.KindDouble:
		return fmt.Sprintf("Json::number(%s, repr=\"\\{%s}\")", valueExpr, valueExpr)
	case ir.KindBytes:
		return fmt.Sprintf("Json::string(url_encode_bytes(%s))", valueExpr)
	case ir.KindEnum:
		return fmt.Sprintf("%s.to_json()", valueExpr)
	case ir.KindMessage:
		return fmt.Sprintf("%s.to_json()", valueExpr)
	case ir.KindAny, ir.KindNullValue:
		return valueExpr
	case ir.KindMap:
		return moonMapToJSONExpr(valueExpr, field.Map)
	default:
		return valueExpr
	}
}

func moonParseExpr(valueExpr string, field *ir.FieldDef) string {
	if field.Repeated {
		base := *field
		base.Repeated = false
		return fmt.Sprintf(`match %s {
    Array(items) => {
      let parsed : Array[%s] = []
      for item in items {
        match (%s) {
          Some(value) => parsed.push(value)
          None => return None
        }
      }
      Some(parsed)
    }
    _ => None
  }`, valueExpr, moonFieldTypeForOneof(&base), moonParseExpr("item", &base))
	}
	switch field.Kind {
	case ir.KindString:
		return fmt.Sprintf("match %s { String(text) => Some(text) ; _ => None }", valueExpr)
	case ir.KindBool:
		return fmt.Sprintf("match %s { True => Some(true) ; False => Some(false) ; _ => None }", valueExpr)
	case ir.KindInt32, ir.KindUInt32:
		return fmt.Sprintf("match %s { Number(value, ..) => Some(value.to_int()) ; _ => None }", valueExpr)
	case ir.KindInt64:
		return fmt.Sprintf("match %s { Number(value, ..) => Some(value.to_int64()) ; _ => None }", valueExpr)
	case ir.KindUInt64:
		return fmt.Sprintf("match %s { Number(value, ..) => Some(value.to_int64().reinterpret_as_uint()) ; _ => None }", valueExpr)
	case ir.KindFloat, ir.KindDouble:
		return fmt.Sprintf("match %s { Number(value, ..) => Some(value) ; _ => None }", valueExpr)
	case ir.KindBytes:
		return fmt.Sprintf("match %s { String(text) => decode_url_bytes(text) ; _ => None }", valueExpr)
	case ir.KindEnum:
		return fmt.Sprintf("%s::from_json(%s)", moonQualifiedType(field.TypeName), valueExpr)
	case ir.KindMessage:
		return fmt.Sprintf("%s::from_json(%s)", moonQualifiedType(field.TypeName), valueExpr)
	case ir.KindAny, ir.KindNullValue:
		return fmt.Sprintf("Some(%s)", valueExpr)
	case ir.KindMap:
		return moonParseMapExpr(valueExpr, field.Map)
	default:
		return fmt.Sprintf("Some(%s)", valueExpr)
	}
}

func moonMapToJSONExpr(valueExpr string, mapping *ir.MapDef) string {
	if mapping == nil {
		return valueExpr
	}
	return fmt.Sprintf(`{
    let out : Map[String, Json] = {}
    for key, value in %s {
      out[key] = %s
    }
    Json::object(out)
  }`, valueExpr, moonMapValueToJSONExpr("value", mapping))
}

func moonMapValueToJSONExpr(valueExpr string, mapping *ir.MapDef) string {
	field := &ir.FieldDef{Kind: mapping.ValueKind, TypeName: mapping.ValueTypeName, TypeModule: mapping.ValueTypeModule}
	return moonToJSONExpr(valueExpr, field)
}

func moonParseMapExpr(valueExpr string, mapping *ir.MapDef) string {
	if mapping == nil {
		return fmt.Sprintf("Some(%s)", valueExpr)
	}
	field := &ir.FieldDef{Kind: mapping.ValueKind, TypeName: mapping.ValueTypeName, TypeModule: mapping.ValueTypeModule}
	return fmt.Sprintf(`match %s {
    Object(entries) => {
      let parsed : Map[String, %s] = {}
      for key, item in entries {
        match (%s) {
          Some(value) => parsed[key] = value
          None => return None
        }
      }
      Some(parsed)
    }
    _ => None
  }`, valueExpr, moonMapValueType(mapping), moonParseExpr("item", field))
}

func moonFieldType(field *ir.FieldDef) string {
	base := moonBaseType(field)
	if field.Repeated {
		base = fmt.Sprintf("Array[%s]", base)
	}
	if field.Optional {
		return base + "?"
	}
	return base
}

func moonFieldTypeForOneof(field *ir.FieldDef) string {
	base := moonBaseType(field)
	if field.Repeated {
		return fmt.Sprintf("Array[%s]", base)
	}
	return base
}

func moonBaseType(field *ir.FieldDef) string {
	switch field.Kind {
	case ir.KindString:
		return "String"
	case ir.KindBool:
		return "Bool"
	case ir.KindInt32, ir.KindUInt32:
		return "Int"
	case ir.KindInt64:
		return "Int64"
	case ir.KindUInt64:
		return "UInt64"
	case ir.KindFloat, ir.KindDouble:
		return "Double"
	case ir.KindBytes:
		return "Bytes"
	case ir.KindEnum, ir.KindMessage:
		return moonQualifiedType(field.TypeName)
	case ir.KindAny, ir.KindNullValue:
		return "Json"
	case ir.KindMap:
		return fmt.Sprintf("Map[String, %s]", moonMapValueType(field.Map))
	default:
		return "Json"
	}
}

func moonMapValueType(mapping *ir.MapDef) string {
	if mapping == nil {
		return "Json"
	}
	field := &ir.FieldDef{Kind: mapping.ValueKind, TypeName: mapping.ValueTypeName, TypeModule: mapping.ValueTypeModule}
	return moonBaseType(field)
}

func moonConstructorFields(message *ir.MessageDef) string {
	parts := make([]string, 0, len(message.Fields)+len(message.Oneofs))
	for _, field := range message.Fields {
		parts = append(parts, field.MoonName)
	}
	for _, oneof := range message.Oneofs {
		parts = append(parts, oneof.MoonName)
	}
	joined := strings.Join(parts, ", ")
	if len(parts) == 1 {
		joined += ","
	}
	return joined
}

func writeGeneratedHeader(sb *strings.Builder, version string, protoPath string) {
	sb.WriteString(fmt.Sprintf("// Code generated by protoc-gen-codeiq %s. DO NOT EDIT.\n", version))
	sb.WriteString(fmt.Sprintf("// Source: %s\n\n", protoPath))
	sb.WriteString("///|\n")
	sb.WriteString("fn hex_digit(value : Int) -> String {\n")
	sb.WriteString("  if value < 10 {\n")
	sb.WriteString("    \"\\{value}\"\n")
	sb.WriteString("  } else {\n")
	sb.WriteString("    match value {\n")
	sb.WriteString("      10 => \"A\"\n")
	sb.WriteString("      11 => \"B\"\n")
	sb.WriteString("      12 => \"C\"\n")
	sb.WriteString("      13 => \"D\"\n")
	sb.WriteString("      14 => \"E\"\n")
	sb.WriteString("      _ => \"F\"\n")
	sb.WriteString("    }\n")
	sb.WriteString("  }\n")
	sb.WriteString("}\n\n")
	sb.WriteString("///|\n")
	sb.WriteString("fn hex_value(code : UInt16) -> Int? {\n")
	sb.WriteString("  if code >= '0' && code <= '9' {\n")
	sb.WriteString("    Some(code.to_int() - '0')\n")
	sb.WriteString("  } else if code >= 'A' && code <= 'F' {\n")
	sb.WriteString("    Some(code.to_int() - 'A' + 10)\n")
	sb.WriteString("  } else if code >= 'a' && code <= 'f' {\n")
	sb.WriteString("    Some(code.to_int() - 'a' + 10)\n")
	sb.WriteString("  } else {\n")
	sb.WriteString("    None\n")
	sb.WriteString("  }\n")
	sb.WriteString("}\n\n")
	sb.WriteString("///|\n")
	sb.WriteString("fn url_encode_bytes(value : Bytes) -> String {\n")
	sb.WriteString("  let encoded = StringBuilder::new()\n")
	sb.WriteString("  for i in 0..<value.length() {\n")
	sb.WriteString("    let byte = value[i].to_int()\n")
	sb.WriteString("    let keep = (byte >= 'a'.to_int() && byte <= 'z'.to_int()) ||\n")
	sb.WriteString("      (byte >= 'A'.to_int() && byte <= 'Z'.to_int()) ||\n")
	sb.WriteString("      (byte >= '0'.to_int() && byte <= '9'.to_int()) ||\n")
	sb.WriteString("      byte == '-'.to_int() ||\n")
	sb.WriteString("      byte == '_'.to_int() ||\n")
	sb.WriteString("      byte == '.'.to_int() ||\n")
	sb.WriteString("      byte == '~'.to_int()\n")
	sb.WriteString("    if keep {\n")
	sb.WriteString("      encoded.write_char(byte.unsafe_to_char())\n")
	sb.WriteString("    } else {\n")
	sb.WriteString("      encoded.write_char('%')\n")
	sb.WriteString("      encoded.write_string(hex_digit(byte / 16))\n")
	sb.WriteString("      encoded.write_string(hex_digit(byte % 16))\n")
	sb.WriteString("    }\n")
	sb.WriteString("  }\n")
	sb.WriteString("  encoded.to_string()\n")
	sb.WriteString("}\n\n")
	sb.WriteString("///|\n")
	sb.WriteString("fn decode_url_bytes(value : String) -> Bytes? {\n")
	sb.WriteString("  let out : Array[Byte] = []\n")
	sb.WriteString("  let mut i = 0\n")
	sb.WriteString("  while i < value.length() {\n")
	sb.WriteString("    let code = value[i]\n")
	sb.WriteString("    if code == '%' {\n")
	sb.WriteString("      if i + 2 >= value.length() {\n")
	sb.WriteString("        return None\n")
	sb.WriteString("      }\n")
	sb.WriteString("      let hi = hex_value(value[i + 1]).unwrap_or(-1)\n")
	sb.WriteString("      let lo = hex_value(value[i + 2]).unwrap_or(-1)\n")
	sb.WriteString("      if hi < 0 || lo < 0 {\n")
	sb.WriteString("        return None\n")
	sb.WriteString("      }\n")
	sb.WriteString("      out.push((hi * 16 + lo).to_byte())\n")
	sb.WriteString("      i += 3\n")
	sb.WriteString("    } else {\n")
	sb.WriteString("      out.push(code.to_int().to_byte())\n")
	sb.WriteString("      i += 1\n")
	sb.WriteString("    }\n")
	sb.WriteString("  }\n")
	sb.WriteString("  Some(Bytes::from_array(out))\n")
	sb.WriteString("}\n\n")
}

func wrapMoonOptionExpr(expr string) string {
	return fmt.Sprintf("(%s)", expr)
}

func enumVariantName(name string) string {
	parts := strings.Split(name, "_")
	var out strings.Builder
	for _, part := range parts {
		if part == "" {
			continue
		}
		out.WriteString(strings.ToUpper(part[:1]))
		if len(part) > 1 {
			out.WriteString(strings.ToLower(part[1:]))
		}
	}
	return out.String()
}

func moonQualifiedType(typeName string) string {
	return typeName
}

func oneofTypeName(oneof *ir.OneofDef) string {
	return enumVariantName(oneof.Name)
}

func oneofQualifiedType(message *ir.MessageDef, oneof *ir.OneofDef) string {
	return message.Name + oneofTypeName(oneof)
}

func oneofVariantName(field *ir.FieldDef) string {
	return enumVariantName(field.ProtoName)
}
