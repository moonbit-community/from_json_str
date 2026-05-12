///|
test "generated streaming FromJson impl" {
  let value : GeneratedBox[Int] = @from_json_str.from_str(
    "{\"ignored\": [true, false], \"x\": 42, \"name\": \"answer\"}",
  )
  inspect(value, content="{x: 42, name: \"answer\"}")
}

///|
test "generated tuple struct streaming FromJson impl" {
  let value : GeneratedPair[Int] = @from_json_str.from_str(
    "[\"GeneratedPair\", 7, \"seven\"]",
  )
  guard value is GeneratedPair(7, "seven") else {
    fail("expected GeneratedPair(7, \"seven\")")
  }
}

///|
test "generated enum streaming FromJson impl" {
  let value : GeneratedExpr = @from_json_str.from_str(
    "[\"Add\", [\"Val\", 1], \"Done\"]",
  )
  guard value is Add(Val(1), Done) else { fail("expected Add(Val(1), Done)") }
}

///|
test "generated named enum streaming FromJson impl" {
  let value : GeneratedNamedExpr = @from_json_str.from_str(
    "[\"Named\", \"payload\", {\"ignored\": true, \"x\": 1, \"y\": 2.5}]",
  )
  guard value is Named(x=1, "payload", y=2.5) else {
    fail("expected Named(x=1, \"payload\", y=2.5)")
  }
}

///|
test "generated suberror streaming FromJson impl" {
  let value : GeneratedProblem = @from_json_str.from_str(
    "[\"Mixed\", \"payload\", {\"x\": 1}]",
  )
  guard value is Mixed(x=1, "payload") else {
    fail("expected Mixed(x=1, \"payload\")")
  }
}
