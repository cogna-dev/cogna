// Package ir defines the intermediate representation shared by all emitters.
// It is intentionally proto-agnostic after construction so emitters stay decoupled.
package ir

// File is one .proto file worth of declarations.
type File struct {
	ProtoPackage string
	ProtoPath    string
	MoonPkg      string
	TsModule     string

	Enums    []*EnumDef
	Messages []*MessageDef
}

// EnumDef describes a proto enum.
type EnumDef struct {
	Name    string
	Values  []*EnumValue
	Comment string
}

// EnumValue is one variant of an enum.
type EnumValue struct {
	Name    string
	Number  int32
	Comment string
}

// MessageDef describes a proto message.
type MessageDef struct {
	Name    string
	Fields  []*FieldDef
	Oneofs  []*OneofDef
	Comment string
}

type OneofDef struct {
	Name     string
	MoonName string
	TsName   string
	Fields   []*FieldDef
}

// FieldDef is one field inside a message.
type FieldDef struct {
	ProtoName  string
	MoonName   string
	JSONName   string
	Kind       FieldKind
	TypeName   string
	TypeModule string
	Repeated   bool
	Optional   bool
	OneofName  string
	Map        *MapDef
	Comment    string
}

type MapDef struct {
	KeyKind         FieldKind
	ValueKind       FieldKind
	ValueTypeName   string
	ValueTypeModule string
}

// FieldKind classifies the scalar or composite kind of a field.
type FieldKind int

const (
	KindString FieldKind = iota
	KindBool
	KindInt32
	KindInt64
	KindUInt32
	KindUInt64
	KindFloat
	KindDouble
	KindBytes
	KindMessage
	KindEnum
	KindAny
	KindNullValue
	KindMap
)
