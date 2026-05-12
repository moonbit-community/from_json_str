///|
test "stream primitives and arrays" {
  let values : Array[Int] = @from_json_str.from_str("[1, 2, 3]")
  inspect(values, content="[1, 2, 3]")
  let ok : Bool = @from_json_str.from_str("true")
  inspect(ok, content="true")
  let s : String = @from_json_str.from_str("\"hello\"")
  inspect(s, content="hello")
}

///|
test "stream object into map" {
  let m : Map[String, Int] = @from_json_str.from_str("{\"a\": 1, \"b\": 2}")
  inspect(m["a"], content="1")
  inspect(m["b"], content="2")
}

///|
test "manual derived-style struct decoder skips unknown fields" {
  let value : @from_json_str.S[Int] = @from_json_str.from_str(
    "{\"ignored\": {\"deep\": [true, false]}, \"x\": 42}",
  )
  inspect(value, content="{x: 42}")
}

///|
test "fallback read_json path remains available" {
  let value : Json = @from_json_str.from_str("{\"x\": [1, true, null]}")
  inspect(value.stringify(), content="{\"x\":[1,true,null]}")
}

///|
test "reports missing field with path" {
  let result : Result[@from_json_str.S[Int], @from_json_str.JsonDecodeError] = try? @from_json_str.from_str(
    "{}",
  )
  inspect(result, content="Err(JsonDecodeError((, \"Missing field x\")))")
}
