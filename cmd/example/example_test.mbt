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
