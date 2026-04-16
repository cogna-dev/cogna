package main

import (
	"fmt"
	"io"
	"os"
	"path"
	"strings"

	"github.com/yufeiminds/codeiq/tools/protoc-gen-codeiq/internal/emitter"
	"github.com/yufeiminds/codeiq/tools/protoc-gen-codeiq/internal/ir"
	"google.golang.org/protobuf/compiler/protogen"
	"google.golang.org/protobuf/proto"
	descriptorpb "google.golang.org/protobuf/types/descriptorpb"
	pluginpb "google.golang.org/protobuf/types/pluginpb"
)

const generatorVersion = "v0.2.0"

func main() {
	request := &pluginpb.CodeGeneratorRequest{}
	if err := proto.Unmarshal(readAll(), request); err != nil {
		fail(err)
	}

	targetsFlag := newTargetFlag()
	params := appendSyntheticMappings(request.GetParameter(), request.GetProtoFile())
	options := protogen.Options{ParamFunc: targetsFlag.SetParam}
	plugin, err := options.New(&pluginpb.CodeGeneratorRequest{
		FileToGenerate:  request.FileToGenerate,
		Parameter:       proto.String(params),
		ProtoFile:       request.ProtoFile,
		CompilerVersion: request.CompilerVersion,
	})
	if err != nil {
		fail(err)
	}

	targets, err := targetsFlag.Targets()
	if err != nil {
		fail(err)
	}

	files, err := ir.BuildFiles(plugin)
	if err != nil {
		fail(err)
	}

	for _, file := range files {
		if targets.moonbit {
			name, content := emitter.EmitMoonBit(file, generatorVersion)
			writeGeneratedFile(plugin, emitter.GeneratedFile{Name: name, Content: content})
		}
		if targets.nodeTS {
			name, content := emitter.EmitTypeScript(file, generatorVersion)
			writeGeneratedFile(plugin, emitter.GeneratedFile{Name: name, Content: content})
		}
	}

	response := plugin.Response()
	encoded, err := proto.Marshal(response)
	if err != nil {
		fail(err)
	}
	if _, err := os.Stdout.Write(encoded); err != nil {
		fail(err)
	}
}

type generationTargets struct {
	moonbit bool
	nodeTS  bool
}

type targetFlag struct {
	values   []string
	explicit bool
}

func newTargetFlag() *targetFlag {
	return &targetFlag{}
}

func (flag *targetFlag) SetParam(name, value string) error {
	switch name {
	case "target":
		if !flag.explicit {
			flag.values = nil
			flag.explicit = true
		}
		flag.values = append(flag.values, value)
		return nil
	case "moonbit", "node-ts":
		if !flag.explicit {
			flag.values = nil
			flag.explicit = true
		}
		if value == "" || value == "true" {
			flag.values = append(flag.values, name)
		}
		return nil
	case "paths":
		return nil
	default:
		if strings.HasPrefix(name, "M") {
			return nil
		}
		return fmt.Errorf("unknown parameter %q", name)
	}
}

func (flag *targetFlag) Targets() (generationTargets, error) {
	if len(flag.values) == 0 {
		flag.values = []string{"moonbit", "node-ts"}
	}
	return parseTargets(flag.values)
}

func parseTargets(values []string) (generationTargets, error) {
	targets := generationTargets{}
	for _, raw := range values {
		for _, part := range strings.Split(raw, ",") {
			switch strings.TrimSpace(part) {
			case "", "none":
			case "moonbit":
				targets.moonbit = true
			case "node-ts":
				targets.nodeTS = true
			default:
				return generationTargets{}, fmt.Errorf("unknown target %q", part)
			}
		}
	}
	if !targets.moonbit && !targets.nodeTS {
		return generationTargets{}, fmt.Errorf("at least one target must be enabled")
	}
	return targets, nil
}

func appendSyntheticMappings(raw string, files []*descriptorpb.FileDescriptorProto) string {
	parts := []string{"paths=source_relative"}
	if raw != "" {
		parts = append(parts, raw)
	}
	for _, file := range files {
		pkgPath := path.Join("github.com/yufeiminds/codeiq/proto", path.Dir(file.GetName()))
		parts = append(parts, fmt.Sprintf("M%s=%s", file.GetName(), pkgPath))
	}
	return strings.Join(parts, ",")
}

func writeGeneratedFile(plugin *protogen.Plugin, file emitter.GeneratedFile) {
	generated := plugin.NewGeneratedFile(path.Clean(file.Name), "")
	generated.P(file.Content)
}

func readAll() []byte {
	data, err := io.ReadAll(os.Stdin)
	if err != nil {
		fail(err)
	}
	return data
}

func fail(err error) {
	fmt.Fprintf(os.Stderr, "protoc-gen-codeiq: %v\n", err)
	os.Exit(1)
}
