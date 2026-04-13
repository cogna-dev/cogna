///|
fn main {
  let out = @gendoc.run({ output_dir: "", index_file: "" })
  match out {
    Ok(result) => println(@cli.display(result))
    Err(error) => println(@cli.to_text(error))
  }
}
