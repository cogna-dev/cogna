package cogna.compat

default deny = []

has_finding(change, code) if {
  some finding in change.semanticDiff.findings
  finding.code == code
}

component_upgrade(change, kind) if {
  change.componentDiff.upgradeKind == kind
}

deny contains out if {
  change := input.changes[_]
  has_finding(change, "removed-declaration")
  out := {
    "rule_id": "compat.core.removed-declaration",
    "level": "error",
    "message": "Public declaration was removed and callers will break.",
    "path": change.path,
    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-core-removed-declaration"
  }
}

deny contains out if {
  change := input.changes[_]
  has_finding(change, "new-declaration")
  out := {
    "rule_id": "compat.core.new-declaration",
    "level": "note",
    "message": "Public declaration was added.",
    "path": change.path,
    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-core-new-declaration"
  }
}

deny contains out if {
  change := input.changes[_]
  has_finding(change, "deprecated-declaration")
  out := {
    "rule_id": "compat.core.deprecated-declaration",
    "level": "note",
    "message": "Public declaration became deprecated.",
    "path": change.path,
    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-core-deprecated-declaration"
  }
}

deny contains out if {
  change := input.changes[_]
  has_finding(change, "go-pointer-receiver-changed")
  out := {
    "rule_id": "compat.go.pointer-receiver-changed",
    "level": "error",
    "message": "Go pointer receiver compatibility changed.",
    "path": change.path,
    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-go-pointer-receiver-changed"
  }
}

deny contains out if {
  change := input.changes[_]
  has_finding(change, "go-receiver-changed")
  out := {
    "rule_id": "compat.go.receiver-changed",
    "level": "error",
    "message": "Go receiver type changed.",
    "path": change.path,
    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-go-receiver-changed"
  }
}

deny contains out if {
  change := input.changes[_]
  has_finding(change, "go-method-set-shrunk")
  out := {
    "rule_id": "compat.go.method-set-shrunk",
    "level": "error",
    "message": "Go method set shrank.",
    "path": change.path,
    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-go-method-set-shrunk"
  }
}

deny contains out if {
  change := input.changes[_]
  has_finding(change, "go-method-set-expanded")
  out := {
    "rule_id": "compat.go.method-set-expanded",
    "level": "warning",
    "message": "Go method set expanded and needs review.",
    "path": change.path,
    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-go-method-set-expanded"
  }
}

deny contains out if {
  change := input.changes[_]
  has_finding(change, "go-signature-changed")
  out := {
    "rule_id": "compat.go.signature-changed",
    "level": "warning",
    "message": "Go public signature changed.",
    "path": change.path,
    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-go-signature-changed"
  }
}

deny contains out if {
  change := input.changes[_]
  has_finding(change, "rust-became-unsafe")
  out := {
    "rule_id": "compat.rust.became-unsafe",
    "level": "error",
    "message": "Rust public item became unsafe.",
    "path": change.path,
    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-rust-became-unsafe"
  }
}

deny contains out if {
  change := input.changes[_]
  has_finding(change, "rust-extern-abi-added")
  out := {
    "rule_id": "compat.rust.extern-abi-added",
    "level": "error",
    "message": "Rust extern ABI was added.",
    "path": change.path,
    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-rust-extern-abi-added"
  }
}

deny contains out if {
  change := input.changes[_]
  has_finding(change, "rust-extern-abi-changed")
  out := {
    "rule_id": "compat.rust.extern-abi-changed",
    "level": "error",
    "message": "Rust extern ABI changed.",
    "path": change.path,
    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-rust-extern-abi-changed"
  }
}

deny contains out if {
  change := input.changes[_]
  has_finding(change, "rust-where-clause-changed")
  out := {
    "rule_id": "compat.rust.where-clause-changed",
    "level": "warning",
    "message": "Rust where-clause changed.",
    "path": change.path,
    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-rust-where-clause-changed"
  }
}

deny contains out if {
  change := input.changes[_]
  has_finding(change, "rust-signature-changed")
  out := {
    "rule_id": "compat.rust.signature-changed",
    "level": "warning",
    "message": "Rust public signature changed.",
    "path": change.path,
    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-rust-signature-changed"
  }
}

deny contains out if {
  change := input.changes[_]
  has_finding(change, "terraform-provider-ref-changed")
  out := {
    "rule_id": "compat.terraform.provider-ref-changed",
    "level": "error",
    "message": "Terraform provider reference changed.",
    "path": change.path,
    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-terraform-provider-ref-changed"
  }
}

deny contains out if {
  change := input.changes[_]
  has_finding(change, "terraform-prevent-destroy-added")
  out := {
    "rule_id": "compat.terraform.prevent-destroy-added",
    "level": "warning",
    "message": "Terraform prevent_destroy was added.",
    "path": change.path,
    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-terraform-prevent-destroy-added"
  }
}

deny contains out if {
  change := input.changes[_]
  has_finding(change, "terraform-create-before-destroy-added")
  out := {
    "rule_id": "compat.terraform.create-before-destroy-added",
    "level": "warning",
    "message": "Terraform create_before_destroy was added.",
    "path": change.path,
    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-terraform-create-before-destroy-added"
  }
}

deny contains out if {
  change := input.changes[_]
  has_finding(change, "terraform-ignore-changes-expanded")
  out := {
    "rule_id": "compat.terraform.ignore-changes-expanded",
    "level": "note",
    "message": "Terraform ignore_changes expanded.",
    "path": change.path,
    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-terraform-ignore-changes-expanded"
  }
}

deny contains out if {
  change := input.changes[_]
  has_finding(change, "terraform-lifecycle-changed")
  out := {
    "rule_id": "compat.terraform.lifecycle-changed",
    "level": "warning",
    "message": "Terraform lifecycle metadata changed.",
    "path": change.path,
    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-terraform-lifecycle-changed"
  }
}

deny contains out if {
  change := input.changes[_]
  has_finding(change, "terraform-input-became-required")
  out := {
    "rule_id": "compat.terraform.input-became-required",
    "level": "error",
    "message": "Terraform input became required and callers must update configuration.",
    "path": change.path,
    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-terraform-input-became-required"
  }
}

deny contains out if {
  change := input.changes[_]
  has_finding(change, "terraform-output-removed")
  out := {
    "rule_id": "compat.terraform.output-removed",
    "level": "error",
    "message": "Terraform output was removed and downstream references can break.",
    "path": change.path,
    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-terraform-output-removed"
  }
}

deny contains out if {
  change := input.changes[_]
  has_finding(change, "openapi-http-method-changed")
  out := {
    "rule_id": "compat.openapi.http-method-changed",
    "level": "error",
    "message": "OpenAPI HTTP method changed.",
    "path": change.path,
    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-openapi-http-method-changed"
  }
}

deny contains out if {
  change := input.changes[_]
  has_finding(change, "openapi-became-required")
  out := {
    "rule_id": "compat.openapi.became-required",
    "level": "error",
    "message": "OpenAPI field or parameter became required.",
    "path": change.path,
    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-openapi-became-required"
  }
}

deny contains out if {
  change := input.changes[_]
  has_finding(change, "openapi-status-codes-added")
  out := {
    "rule_id": "compat.openapi.status-codes-added",
    "level": "warning",
    "message": "OpenAPI status codes were added.",
    "path": change.path,
    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-openapi-status-codes-added"
  }
}

deny contains out if {
  change := input.changes[_]
  has_finding(change, "openapi-media-types-added")
  out := {
    "rule_id": "compat.openapi.media-types-added",
    "level": "note",
    "message": "OpenAPI media types were added.",
    "path": change.path,
    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-openapi-media-types-added"
  }
}

deny contains out if {
  change := input.changes[_]
  has_finding(change, "openapi-operation-changed")
  out := {
    "rule_id": "compat.openapi.operation-changed",
    "level": "warning",
    "message": "OpenAPI operation changed.",
    "path": change.path,
    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-openapi-operation-changed"
  }
}

deny contains out if {
  change := input.changes[_]
  has_finding(change, "openapi-response-status-removed")
  out := {
    "rule_id": "compat.openapi.response-status-removed",
    "level": "error",
    "message": "OpenAPI response status code was removed.",
    "path": change.path,
    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-openapi-response-status-removed"
  }
}

deny contains out if {
  change := input.changes[_]
  has_finding(change, "openapi-response-schema-narrowed")
  out := {
    "rule_id": "compat.openapi.response-schema-narrowed",
    "level": "error",
    "message": "OpenAPI response schema narrowed and clients may fail to parse it.",
    "path": change.path,
    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-openapi-response-schema-narrowed"
  }
}

deny contains out if {
  change := input.componentChanges[_]
  component_upgrade(change, "version-upgrade")
  out := {
    "rule_id": "compat.component.version-upgrade",
    "level": "warning",
    "message": "Software component version changed.",
    "path": change.path,
    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-component-version-upgrade"
  }
}

deny contains out if {
  change := input.componentChanges[_]
  component_upgrade(change, "metadata-change")
  out := {
    "rule_id": "compat.component.metadata-changed",
    "level": "warning",
    "message": "Software component metadata changed.",
    "path": change.path,
    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-component-metadata-changed"
  }
}
