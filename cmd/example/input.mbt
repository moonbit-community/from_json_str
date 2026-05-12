///|
#json.from_json_str
pub(all) struct GeneratedBox[T] {
  x : T
  name : String
}

///|
pub impl[T : Show] Show for GeneratedBox[T] with output(self, logger) {
  logger.write_string("{x: ")
  logger.write_object(self.x)
  logger.write_string(", name: ")
  logger.write_object(self.name)
  logger.write_string("}")
}

///|
#json.from_json_str
pub(all) struct GeneratedPair[T](T, String)

///|
#json.from_json_str
pub(all) enum GeneratedExpr {
  Done
  Val(Int)
  Add(GeneratedExpr, GeneratedExpr)
}
