///|
fn main {
  let result : Result[@lib.S[Array[Int]], @lib.JsonDecodeError] = try? @lib.from_str(
    "{\"x\": [1, 2, 3], \"ignored\": {\"nested\": true}}",
  )
  println(result)
}
