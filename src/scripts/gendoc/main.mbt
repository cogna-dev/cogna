///|
pub(all) struct PolicyDocsParams {
  output_dir : String
  index_file : String
} derive(Eq)

///|
pub impl Show for PolicyDocsParams with output(self, logger) {
  logger.write_string("{output_dir: ")
  logger.write_object(self.output_dir)
  logger.write_string(", index_file: ")
  logger.write_object(self.index_file)
  logger.write_char('}')
}

///|
pub(all) struct PolicyDocsResult {
  output_dir : String
  index_file : String
  summary : String
} derive(Eq)

///|
pub impl Show for PolicyDocsResult with output(self, logger) {
  logger.write_string("{output_dir: ")
  logger.write_object(self.output_dir)
  logger.write_string(", index_file: ")
  logger.write_object(self.index_file)
  logger.write_string(", summary: ")
  logger.write_object(self.summary)
  logger.write_char('}')
}

///|
pub impl @cli.Display for PolicyDocsResult with display(self : PolicyDocsResult) -> String {
  self.summary
}

///|
fn policy_docs_error(message : String) -> @cli.CliError {
  @cli.command_error("policy-docs failed: \{message}")
}

///|
fn ensure_dir(path : String) -> Result[Unit, @cli.CliError] {
  if @fs.path_exists(path) {
    Ok(())
  } else {
    @fs.create_dir(path) catch {
      err =>
        return Err(
          policy_docs_error("cannot create directory \{path}: \{err.to_string()}"),
        )
    }
    Ok(())
  }
}

///|
fn ensure_nested_dir(path : String) -> Result[Unit, @cli.CliError] {
  let parts = path.split("/").to_array()
  let mut current = if path.has_prefix("/") { "/" } else { "" }
  for i in 0..<parts.length() {
    let segment = parts[i].to_string()
    if segment == "" {
      continue
    }
    current = if current == "" || current == "/" {
      if current == "/" { "/\{segment}" } else { segment }
    } else {
      "\{current}/\{segment}"
    }
    let out = ensure_dir(current)
    guard out is Ok(_) else { return Err(out.unwrap_err()) }
  }
  Ok(())
}

///|
fn remove_tree(path : String) -> Result[Unit, @cli.CliError] {
  if !@fs.path_exists(path) {
    return Ok(())
  }
  let is_dir = try? @fs.is_dir(path)
  if is_dir is Ok(true) {
    let entries = @fs.read_dir(path) catch {
      err =>
        return Err(
          policy_docs_error("cannot read directory \{path}: \{err.to_string()}"),
        )
    }
    for i in 0..<entries.length() {
      let out = remove_tree("\{path}/\{entries[i]}")
      guard out is Ok(_) else { return Err(out.unwrap_err()) }
    }
    @fs.remove_dir(path) catch {
      err =>
        return Err(
          policy_docs_error("cannot remove directory \{path}: \{err.to_string()}"),
        )
    }
    Ok(())
  } else {
    @fs.remove_file(path) catch {
      err =>
        return Err(
          policy_docs_error("cannot remove file \{path}: \{err.to_string()}"),
        )
    }
    Ok(())
  }
}

///|
fn write_text(path : String, content : String) -> Result[Unit, @cli.CliError] {
  @fs.write_string_to_file(path, content) catch {
    err =>
      return Err(
        policy_docs_error("cannot write file \{path}: \{err.to_string()}"),
      )
  }
  Ok(())
}

///|
fn parent_dir(path : String) -> String {
  let parts = path.split("/").to_array()
  if parts.length() <= 1 {
    "."
  } else {
    let mut out = ""
    for i in 0..<(parts.length() - 1) {
      if i > 0 {
        out = "\{out}/"
      }
      out = "\{out}\{parts[i]}"
    }
    if out == "" {
      "."
    } else {
      out
    }
  }
}

///|
fn yaml_quoted(value : String) -> String {
  let escaped = value
    .replace_all(old="\\", new="\\\\")
    .replace_all(old="\"", new="\\\"")
    .replace_all(old="\n", new=" ")
  "\"\{escaped}\""
}

///|
fn ecosystem_href(family : String) -> String {
  match family {
    "go" => "/docs/go"
    "rust" => "/docs/rust"
    "terraform" => "/docs/terraform"
    "openapi" => "/docs/openapi"
    "component" => "/docs/sca-spdx"
    "core" => "/docs/analyze-changes"
    _ => "/docs/policy"
  }
}

///|
fn ecosystem_label(family : String) -> String {
  match family {
    "go" => "Go"
    "rust" => "Rust"
    "terraform" => "Terraform"
    "openapi" => "OpenAPI"
    "component" => "SCA / SBOM"
    "core" => "变更分析"
    _ => "自定义策略"
  }
}

///|
fn rule_trigger_text(rule : @policy_catalog.Rule) -> String {
  match rule.finding_code {
    Some(code) =>
      "当 `semanticDiff.findings[]` 中出现 `\{code}` 时，这条规则会在 `\{rule.entrypoint}` 下产生命中。"
    None =>
      match rule.component_upgrade_kind {
        Some(kind) =>
          "当组件级 diff 的 `componentDiff.upgradeKind` 等于 `\{kind}` 时，这条规则会在 `\{rule.entrypoint}` 下产生命中。"
        None => "当 OPA compatibility policy 命中该规则的谓词时，会在 `\{rule.entrypoint}` 下返回结果。"
      }
  }
}

///|
fn rule_page_content(rule : @policy_catalog.Rule) -> String {
  let trigger_text = rule_trigger_text(rule)
  let ecosystem_doc_href = ecosystem_href(rule.family)
  let ecosystem_doc_label = ecosystem_label(rule.family)
  (
    $|---
    $|title: \{yaml_quoted(rule.id)}
    $|description: \{yaml_quoted(rule.summary)}
    $|order: 999
    $|---
    $|
    $|# \{rule.id}
    $|
    $|## 摘要
    $|
    $|\{rule.summary}
    $|
    $|## 元数据
    $|
    $|| 字段 | 值 |
    $||------|----|
    $|| `ruleId` | `\{rule.id}` |
    $|| `family` | `\{rule.family}` |
    $|| `defaultLevel` | `\{rule.default_level}` |
    $|| `entrypoint` | `\{rule.entrypoint}` |
    $|| `helpUri` | `\{rule.docs}` |
    $|
    $|## 触发条件
    $|
    $|\{trigger_text}
    $|
    $|## SARIF 示例
    $|
    $|```json
    $|{
    $|  "ruleId": "\{rule.id}",
    $|  "level": "\{rule.default_level}",
    $|  "message": { "text": "\{rule.summary}" },
    $|  "helpUri": "\{rule.docs}"
    $|}
    $|```
    $|
    $|## 相关文档
    $|
    $|- [内置策略规则总览](/docs/policies)
    $|- [\{ecosystem_doc_label} 生态说明](\{ecosystem_doc_href})
    $|- [自定义 OPA 自动审查策略](/docs/policy)
  )
}

///|
fn index_content(rules : Array[@policy_catalog.Rule]) -> String {
  let families : Array[String] = []
  let rules_by_family : Map[String, Array[@policy_catalog.Rule]] = {}
  for i in 0..<rules.length() {
    let rule = rules[i]
    if !rules_by_family.contains(rule.family) {
      families.push(rule.family)
      rules_by_family[rule.family] = []
    }
    rules_by_family[rule.family].push(rule)
  }
  let sections : Array[String] = []
  for i in 0..<families.length() {
    let family = families[i]
    let items = rules_by_family[family]
    let lines : Array[String] = ["## \{family}", ""]
    for j in 0..<items.length() {
      let rule = items[j]
      lines.push(
        "- [\{rule.id}](\{@policy_catalog.rule_path(rule)}) — \{rule.summary}",
      )
    }
    sections.push(lines.join("\n"))
  }
  (
    $|---
    $|title: "内置策略规则"
    $|description: "CodeIQ 内置 compatibility policy 的规则目录与 canonical helpUri 入口。"
    $|order: 25
    $|---
    $|
    $|# 内置策略规则
    $|
    $|这组页面由仓库内置 policy catalog 自动生成，是 GitHub Code Scanning、SARIF viewer 与未来 VSCode 插件使用的 canonical `helpUri` 文档源。
    $|
    $|- 规则总数：`\{rules.length()}`
    $|- 规则家族：`\{families.length()}`
    $|- 入口：`data.codeiq.compat.deny`
    $|
    $|\{sections.join("\n\n")}
  )
}

///|
fn generated_page_path(output_dir : String, rule : @policy_catalog.Rule) -> String {
  "\{output_dir}/\{rule.family}/\{@policy_catalog.rule_slug(rule.id)}.mdx"
}

///|
pub fn run(
  params : PolicyDocsParams,
) -> @cli.CliResult[PolicyDocsResult, @cli.CliError] {
  let output_dir = if params.output_dir == "" {
    "docs/src/content/docs/policies/generated"
  } else {
    params.output_dir
  }
  let index_file = if params.index_file == "" {
    "docs/src/content/docs/policies.mdx"
  } else {
    params.index_file
  }

  let parent_out = ensure_nested_dir(parent_dir(index_file))
  guard parent_out is Ok(_) else { return Err(parent_out.unwrap_err()) }
  let cleanup_out = remove_tree(output_dir)
  guard cleanup_out is Ok(_) else { return Err(cleanup_out.unwrap_err()) }
  let output_out = ensure_nested_dir(output_dir)
  guard output_out is Ok(_) else { return Err(output_out.unwrap_err()) }

  let rules = @policy_catalog.builtin_rules()
  let index_out = write_text(index_file, index_content(rules))
  guard index_out is Ok(_) else { return Err(index_out.unwrap_err()) }

  for i in 0..<rules.length() {
    let rule = rules[i]
    let family_out = ensure_nested_dir("\{output_dir}/\{rule.family}")
    guard family_out is Ok(_) else { return Err(family_out.unwrap_err()) }
    let page_out = write_text(generated_page_path(output_dir, rule), rule_page_content(rule))
    guard page_out is Ok(_) else { return Err(page_out.unwrap_err()) }
  }

  Ok({
    output_dir,
    index_file,
    summary: "Generated built-in policy docs at \{index_file} and \{output_dir}",
  })
}
