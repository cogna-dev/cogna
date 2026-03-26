///|
pub(all) struct ComponentHash {
  alg : String
  content : String
} derive(Show, Eq)

///|
pub(all) struct SoftwareComponent {
  id : String
  name : String
  version : String?
  purl : String?
  component_type : String
  scope : String
  evidence_path : String
  hashes : Array[ComponentHash]
} derive(Show, Eq)

///|
pub(all) struct SbomArtifacts {
  components_ndjson : String
  cyclonedx_json : String
  spdx_json : String
} derive(Show, Eq)

///|
fn string_json(value : String?) -> Json {
  match value {
    Some(text) => Json::string(text)
    None => Json::null()
  }
}

///|
fn hash_json(hash : ComponentHash) -> Json {
  { "alg": hash.alg, "content": hash.content }
}

///|
pub fn component_signature(component : SoftwareComponent) -> String {
  let version = match component.version {
    Some(value) if value != "" => "@\{value}"
    _ => ""
  }
  "\{component.component_type} \{component.name}\{version}"
}

///|
pub fn component_record_json(component : SoftwareComponent) -> Json {
  let hashes : Array[Json] = []
  for i in 0..<component.hashes.length() {
    hashes.push(hash_json(component.hashes[i]))
  }
  {
    "id": component.id,
    "kind": "component",
    "path": component.evidence_path,
    "signature": component_signature(component),
    "name": component.name,
    "componentType": component.component_type,
    "scope": component.scope,
    "version": string_json(component.version),
    "purl": string_json(component.purl),
    "hashes": Json::array(hashes),
    "location": {
      "uri": component.evidence_path,
      "startLine": 1,
      "endLine": 1,
    },
  }
}

///|
pub fn components_ndjson(components : Array[SoftwareComponent]) -> String {
  let lines : Array[String] = []
  for i in 0..<components.length() {
    lines.push(component_record_json(components[i]).stringify())
  }
  if lines.is_empty() {
    ""
  } else {
    lines.join("\n") + "\n"
  }
}

///|
fn cyclonedx_type(component : SoftwareComponent) -> String {
  match component.component_type {
    "application" => "application"
    "file" => "file"
    _ => "library"
  }
}

///|
fn cyclonedx_component_json(component : SoftwareComponent) -> Json {
  let object : Map[String, Json] = {
    "type": Json::string(cyclonedx_type(component)),
    "bom-ref": Json::string(component.id),
    "name": Json::string(component.name),
  }
  match component.version {
    Some(value) if value != "" => object["version"] = Json::string(value)
    _ => ()
  }
  match component.purl {
    Some(value) if value != "" => object["purl"] = Json::string(value)
    _ => ()
  }
  if !component.hashes.is_empty() {
    let hashes : Array[Json] = []
    for i in 0..<component.hashes.length() {
      hashes.push({
        "alg": component.hashes[i].alg,
        "content": component.hashes[i].content,
      })
    }
    object["hashes"] = Json::array(hashes)
  }
  Json::object(object)
}

///|
pub fn cyclonedx_json(components : Array[SoftwareComponent]) -> String {
  let metadata_component : Json = if components.is_empty() {
    Json::object({
      "type": Json::string("application"),
      "name": Json::string("unknown"),
    })
  } else {
    cyclonedx_component_json(components[0])
  }
  let listed_components : Array[Json] = []
  let depends_on : Array[String] = []
  for i in 1..<components.length() {
    listed_components.push(cyclonedx_component_json(components[i]))
    if components[i].scope != "source-file" {
      depends_on.push(components[i].id)
    }
  }
  let dependencies : Array[Json] = []
  if !components.is_empty() {
    dependencies.push({
      "ref": components[0].id,
      "dependsOn": Json::array(depends_on.map(Json::string)),
    })
  }
  let document : Json = Json::object({
    "bomFormat": Json::string("CycloneDX"),
    "specVersion": Json::string("1.7"),
    "version": Json::number(1),
    "metadata": Json::object({
      "timestamp": Json::string("2026-03-25T19:00:00Z"),
      "component": metadata_component,
    }),
    "components": Json::array(listed_components),
    "dependencies": Json::array(dependencies),
  })
  document.stringify(indent=2)
}

///|
fn spdx_element_id(index : Int) -> String {
  "https://codeiq.local/spdx/element/\{index}"
}

///|
pub fn spdx_json(components : Array[SoftwareComponent]) -> String {
  let graph : Array[Json] = []
  let creation_id = "_:creationinfo"
  let document_id = "https://codeiq.local/spdx/document"
  let bom_id = "https://codeiq.local/spdx/bom"
  graph.push({
    "type": "CreationInfo",
    "@id": creation_id,
    "createdBy": ["https://codeiq.local/tool/codeiq"],
    "specVersion": "3.0.0",
    "created": "2026-03-25T19:00:00Z",
  })
  graph.push({
    "type": "SpdxDocument",
    "spdxId": document_id,
    "creationInfo": creation_id,
    "rootElement": [bom_id],
    "profileConformance": ["core", "software"],
  })
  let root_elements : Array[String] = []
  let dependency_ids : Array[String] = []
  for i in 0..<components.length() {
    let component = components[i]
    let element_id = spdx_element_id(i)
    root_elements.push(element_id)
    if i > 0 && component.scope != "source-file" {
      dependency_ids.push(element_id)
    }
    let package_json : Map[String, Json] = {
      "type": Json::string("software_Package"),
      "spdxId": Json::string(element_id),
      "creationInfo": Json::string(creation_id),
      "name": Json::string(component.name),
      "software_downloadLocation": Json::string(component.evidence_path),
    }
    match component.version {
      Some(value) if value != "" =>
        package_json["software_packageVersion"] = Json::string(value)
      _ => ()
    }
    match component.purl {
      Some(value) if value != "" => package_json["externalRefs"] = Json::array([
        { "referenceType": "purl", "referenceLocator": value },
      ])
      _ => ()
    }
    if !component.hashes.is_empty() {
      package_json["verifiedUsing"] = Json::array(component.hashes.map(hash => {
        "algorithm": hash.alg,
        "hashValue": hash.content,
      }))
    }
    graph.push(Json::object(package_json))
  }
  graph.push({
    "type": "software_Sbom",
    "spdxId": bom_id,
    "creationInfo": creation_id,
    "rootElement": Json::array(root_elements.map(Json::string)),
    "software_sbomType": ["build"],
  })
  if components.length() > 1 {
    graph.push({
      "type": "Relationship",
      "from": spdx_element_id(0),
      "relationshipType": "dependsOn",
      "to": Json::array(dependency_ids.map(Json::string)),
    })
  }
  let document : Json = Json::object({
    "@context": Json::string("https://spdx.org/rdf/3.0.1/spdx-context.jsonld"),
    "@graph": Json::array(graph),
  })
  document.stringify(indent=2)
}

///|
pub fn build_sbom_artifacts(components : Array[SoftwareComponent]) -> SbomArtifacts {
  {
    components_ndjson: components_ndjson(components),
    cyclonedx_json: cyclonedx_json(components),
    spdx_json: spdx_json(components),
  }
}
