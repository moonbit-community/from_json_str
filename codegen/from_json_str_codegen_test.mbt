///|
fn parse_source(source : String) -> @syntax.Impls raise {
  let (ast, report) = @parser.parse_string(source)
  guard report is [] else { fail("parse failed") }
  ast
}

///|
fn expect_derive_failure(source : String, message : String) -> Unit raise {
  let result = try? derive_from_json_str(parse_source(source))
  match result {
    Err(Failure::Failure(msg)) => {
      let msg = if msg =~ (re"FAILED: ", after=rest) { rest } else { msg }
      inspect(msg, content=message)
    }
    Err(err) => fail("expected Failure, got \{err}")
    Ok(_) => fail("expected derive failure")
  }
}

///|
test "derive #json.from_json_str for generic record" {
  let source =
    #|#json.from_json_str
    #|pub(all) struct Box[T] {
    #|  x : T
    #|  name : String
    #|}
  let generated = derive_from_json_str(parse_source(source))
  let formatted = @formatter.impls_to_string(generated)
  inspect(
    formatted,
    content=(
      #|///|
      #|#json.generated
      #|pub impl[T :  @from_json_str.FromJson] @from_json_str.FromJson for Box[T] with from_json(
      #|  json,
      #|  path,
      #|) {
      #|  match json {
      #|    Object(obj) => {
      #|      let x = match obj.get("x") {
      #|        Some(value) => 
      #|          @from_json_str.FromJson::from_json(value, path.add_key("x"))
      #|        None => raise  @from_json_str.JsonDecodeError((path, "Missing field x"))
      #|      }
      #|      let name = match obj.get("name") {
      #|        Some(value) => 
      #|          @from_json_str.FromJson::from_json(value, path.add_key("name"))
      #|        None => {
      #|          raise  @from_json_str.JsonDecodeError((path, "Missing field name"))
      #|        }
      #|      }
      #|      { x, name }
      #|    }
      #|    _ => {
      #|      raise  @from_json_str.JsonDecodeError(
      #|        (path, "Box::from_json: expected object"),
      #|      )
      #|    }
      #|  }
      #|}
      #|
      #|///|
      #|#json.generated
      #|pub impl[T :  @from_json_str.FromJson] @from_json_str.FromJson for Box[T] with decode_json(
      #|  decoder,
      #|  path,
      #|) {
      #|  let mut x = None
      #|  let mut name = None
      #|  decoder.begin_object(path)
      #|  while true {
      #|    match decoder.next_object_key(path) {
      #|      None => break 
      #|      Some("x") => {
      #|        x = 
      #|          Some(@from_json_str.FromJson::decode_json(decoder, path.add_key("x")))
      #|        continue
      #|      }
      #|      Some("name") => {
      #|        name = Some(
      #|          @from_json_str.FromJson::decode_json(decoder, path.add_key("name")),
      #|        )
      #|        continue
      #|      }
      #|      Some(_) => {
      #|        decoder.skip_value(path)
      #|        continue
      #|      }
      #|    }
      #|  }
      #|  let x = match x {
      #|    Some(value) => value
      #|    None => raise  @from_json_str.JsonDecodeError((path, "Missing field x"))
      #|  }
      #|  let name = match name {
      #|    Some(value) => value
      #|    None => raise  @from_json_str.JsonDecodeError((path, "Missing field name"))
      #|  }
      #|  { x, name }
      #|}
      #|
      #|
    ),
  )
}

///|
test "derive #json.private_from_json_str emits private impls" {
  let source =
    #|#json.private_from_json_str
    #|struct PrivateBox {
    #|  x : Int
    #|}
  let generated = derive_from_json_str(parse_source(source))
  let formatted = @formatter.impls_to_string(generated)
  inspect(
    formatted,
    content=(
      #|///|
      #|#json.generated
      #|priv impl @from_json_str.FromJson for PrivateBox with from_json(json, path) {
      #|  match json {
      #|    Object(obj) => {
      #|      let x = match obj.get("x") {
      #|        Some(value) => 
      #|          @from_json_str.FromJson::from_json(value, path.add_key("x"))
      #|        None => raise  @from_json_str.JsonDecodeError((path, "Missing field x"))
      #|      }
      #|      { x, }
      #|    }
      #|    _ => {
      #|      raise  @from_json_str.JsonDecodeError(
      #|        (path, "PrivateBox::from_json: expected object"),
      #|      )
      #|    }
      #|  }
      #|}
      #|
      #|///|
      #|#json.generated
      #|priv impl @from_json_str.FromJson for PrivateBox with decode_json(decoder, path) {
      #|  let mut x = None
      #|  decoder.begin_object(path)
      #|  while true {
      #|    match decoder.next_object_key(path) {
      #|      None => break 
      #|      Some("x") => {
      #|        x = 
      #|          Some(@from_json_str.FromJson::decode_json(decoder, path.add_key("x")))
      #|        continue
      #|      }
      #|      Some(_) => {
      #|        decoder.skip_value(path)
      #|        continue
      #|      }
      #|    }
      #|  }
      #|  let x = match x {
      #|    Some(value) => value
      #|    None => raise  @from_json_str.JsonDecodeError((path, "Missing field x"))
      #|  }
      #|  { x, }
      #|}
      #|
      #|
    ),
  )
}

///|
test "derive ignores unannotated declarations" {
  let generated = derive_from_json_str(parse_source("struct Plain { x : Int }"))
  inspect(@formatter.impls_to_string(generated), content="")
}

///|
test "derive #json.from_json_str for tuple struct" {
  let source =
    #|#json.from_json_str
    #|pub(all) struct PairBox[T](T, String)
  let generated = derive_from_json_str(parse_source(source))
  let formatted = @formatter.impls_to_string(generated)
  inspect(formatted.contains("for PairBox[T] with from_json"), content="true")
  inspect(formatted.contains("[\"PairBox\", json0, json1]"), content="true")
  inspect(formatted.contains("PairBox(arg0, arg1)"), content="true")
  inspect(formatted.contains("with decode_json"), content="true")
  inspect(
    formatted.contains("@from_json_str.Payload(\"PairBox\")"),
    content="true",
  )
}

///|
test "derive #json.from_json_str for enum" {
  let source =
    #|#json.from_json_str
    #|pub(all) enum Expr {
    #|  Done
    #|  Val(Int)
    #|  Add(Expr, Expr)
    #|}
  let generated = derive_from_json_str(parse_source(source))
  let formatted = @formatter.impls_to_string(generated)
  inspect(formatted.contains("\"Done\" => Done"), content="true")
  inspect(formatted.contains("[\"Val\", json0]"), content="true")
  inspect(formatted.contains("Val(arg0)"), content="true")
  inspect(formatted.contains("[\"Add\", json0, json1]"), content="true")
  inspect(formatted.contains("Add(arg0, arg1)"), content="true")
  inspect(formatted.contains("@from_json_str.Plain(\"Done\")"), content="true")
  inspect(formatted.contains("@from_json_str.Payload(\"Val\")"), content="true")
}

///|
test "derive #json.from_json_str for named enum payload" {
  let source =
    #|#json.from_json_str
    #|pub(all) enum Expr {
    #|  Mixed(x~ : Int, String, y~ : Double)
    #|}
  let generated = derive_from_json_str(parse_source(source))
  let formatted = @formatter.impls_to_string(generated)
  inspect(formatted.contains("[\"Mixed\", json1, named_json]"), content="true")
  inspect(
    formatted.contains("path.add_index(2).add_key(\"x\")"),
    content="true",
  )
  inspect(
    formatted.contains("path.add_index(2).add_key(\"y\")"),
    content="true",
  )
  inspect(formatted.contains("Mixed(x=arg0, arg1, y=arg2)"), content="true")
  inspect(
    formatted.contains("@from_json_str.Payload(\"Mixed\")"),
    content="true",
  )
}

///|
test "derive #json.from_json_str for suberror" {
  let source =
    #|#json.from_json_str
    #|pub(all) suberror Problem {
    #|  Finished
    #|  Bad(Int)
    #|  Mixed(x~ : Int, String)
    #|}
  let generated = derive_from_json_str(parse_source(source))
  let formatted = @formatter.impls_to_string(generated)
  inspect(formatted.contains("for Problem with from_json"), content="true")
  inspect(formatted.contains("\"Finished\" => Finished"), content="true")
  inspect(formatted.contains("[\"Bad\", json0]"), content="true")
  inspect(formatted.contains("Bad(arg0)"), content="true")
  inspect(formatted.contains("[\"Mixed\", json1, named_json]"), content="true")
  inspect(formatted.contains("Mixed(x=arg0, arg1)"), content="true")
}

///|
test "derive rejects unsupported declaration shapes" {
  expect_derive_failure(
    (
      #|#json.from_json_str
      #|type Alias = Int
    ),
    "from_json_str derive does not support type aliases",
  )
  expect_derive_failure(
    (
      #|#json.from_json_str
      #|type Abstract
    ),
    "from_json_str derive does not support abstract types",
  )
  expect_derive_failure(
    (
      #|#json.from_json_str
      #|extern type Extern
    ),
    "from_json_str derive does not support extern types",
  )
  expect_derive_failure(
    (
      #|#json.from_json_str(rename="x")
      #|struct Box {
      #|  x : Int
      #|}
    ),
    "Unsupported property in #json.from_json_str",
  )
  expect_derive_failure(
    (
      #|#json.private_from_json_str(rename="x")
      #|struct Box {
      #|  x : Int
      #|}
    ),
    "Unsupported property in #json.private_from_json_str",
  )
}
