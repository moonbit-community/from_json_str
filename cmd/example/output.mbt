///|
#json.generated
pub impl[T : @from_json_str.FromJson] @from_json_str.FromJson for GeneratedBox[
  T,
] with from_json(json, path) {
  match json {
    Object(obj) => {
      let x = match obj.get("x") {
        Some(value) =>
          @from_json_str.FromJson::from_json(value, path.add_key("x"))
        None => raise @from_json_str.JsonDecodeError((path, "Missing field x"))
      }
      let name = match obj.get("name") {
        Some(value) =>
          @from_json_str.FromJson::from_json(value, path.add_key("name"))
        None =>
          raise @from_json_str.JsonDecodeError((path, "Missing field name"))
      }
      { x, name }
    }
    _ =>
      raise @from_json_str.JsonDecodeError(
        (path, "GeneratedBox::from_json: expected object"),
      )
  }
}

///|
#json.generated
pub impl[T : @from_json_str.FromJson] @from_json_str.FromJson for GeneratedBox[
  T,
] with decode_json(decoder, path) {
  let mut x = None
  let mut name = None
  decoder.begin_object(path)
  while true {
    match decoder.next_object_key(path) {
      None => break
      Some("x") => {
        x = Some(
          @from_json_str.FromJson::decode_json(decoder, path.add_key("x")),
        )
        continue
      }
      Some("name") => {
        name = Some(
          @from_json_str.FromJson::decode_json(decoder, path.add_key("name")),
        )
        continue
      }
      Some(_) => {
        decoder.skip_value(path)
        continue
      }
    }
  }
  let x = match x {
    Some(value) => value
    None => raise @from_json_str.JsonDecodeError((path, "Missing field x"))
  }
  let name = match name {
    Some(value) => value
    None => raise @from_json_str.JsonDecodeError((path, "Missing field name"))
  }
  { x, name }
}

///|
#json.generated
pub impl[T : @from_json_str.FromJson] @from_json_str.FromJson for GeneratedPair[
  T,
] with from_json(json, path) {
  match json {
    ["GeneratedPair", json0, json1] => {
      let arg0 = @from_json_str.FromJson::from_json(json0, path.add_index(1))
      let arg1 = @from_json_str.FromJson::from_json(json1, path.add_index(2))
      GeneratedPair(arg0, arg1)
    }
    _ =>
      raise @from_json_str.JsonDecodeError(
        (path, "GeneratedPair::from_json: expected tuple struct array"),
      )
  }
}

///|
#json.generated
pub impl[T : @from_json_str.FromJson] @from_json_str.FromJson for GeneratedPair[
  T,
] with decode_json(decoder, path) {
  match decoder.read_variant_tag(path) {
    @from_json_str.Payload("GeneratedPair") => {
      let arg0 = if decoder.next_array_value(path) {
        @from_json_str.FromJson::decode_json(decoder, path.add_index(1))
      } else {
        raise @from_json_str.JsonDecodeError(
          (path, "GeneratedPair::decode_json: missing field 0"),
        )
      }
      let arg1 = if decoder.next_array_value(path) {
        @from_json_str.FromJson::decode_json(decoder, path.add_index(2))
      } else {
        raise @from_json_str.JsonDecodeError(
          (path, "GeneratedPair::decode_json: missing field 1"),
        )
      }
      if decoder.next_array_value(path) {
        raise @from_json_str.JsonDecodeError(
          (path, "GeneratedPair::decode_json: too many fields"),
        )
      } else {
        GeneratedPair(arg0, arg1)
      }
    }
    _ =>
      raise @from_json_str.JsonDecodeError(
        (path, "GeneratedPair::decode_json: expected tuple struct array"),
      )
  }
}

///|
#json.generated
pub impl @from_json_str.FromJson for GeneratedExpr with from_json(json, path) {
  match json {
    "Done" => Done
    ["Val", json0] => {
      let arg0 = @from_json_str.FromJson::from_json(json0, path.add_index(1))
      Val(arg0)
    }
    ["Add", json0, json1] => {
      let arg0 = @from_json_str.FromJson::from_json(json0, path.add_index(1))
      let arg1 = @from_json_str.FromJson::from_json(json1, path.add_index(2))
      Add(arg0, arg1)
    }
    _ =>
      raise @from_json_str.JsonDecodeError(
        (path, "GeneratedExpr::from_json: expected enum value"),
      )
  }
}

///|
#json.generated
pub impl @from_json_str.FromJson for GeneratedExpr with decode_json(
  decoder,
  path,
) {
  match decoder.read_variant_tag(path) {
    @from_json_str.Plain("Done") => Done
    @from_json_str.Payload("Val") => {
      let arg0 = if decoder.next_array_value(path) {
        @from_json_str.FromJson::decode_json(decoder, path.add_index(1))
      } else {
        raise @from_json_str.JsonDecodeError(
          (path, "GeneratedExpr::decode_json: missing constructor field 0"),
        )
      }
      if decoder.next_array_value(path) {
        raise @from_json_str.JsonDecodeError(
          (path, "GeneratedExpr::decode_json: too many constructor fields"),
        )
      } else {
        Val(arg0)
      }
    }
    @from_json_str.Payload("Add") => {
      let arg0 = if decoder.next_array_value(path) {
        @from_json_str.FromJson::decode_json(decoder, path.add_index(1))
      } else {
        raise @from_json_str.JsonDecodeError(
          (path, "GeneratedExpr::decode_json: missing constructor field 0"),
        )
      }
      let arg1 = if decoder.next_array_value(path) {
        @from_json_str.FromJson::decode_json(decoder, path.add_index(2))
      } else {
        raise @from_json_str.JsonDecodeError(
          (path, "GeneratedExpr::decode_json: missing constructor field 1"),
        )
      }
      if decoder.next_array_value(path) {
        raise @from_json_str.JsonDecodeError(
          (path, "GeneratedExpr::decode_json: too many constructor fields"),
        )
      } else {
        Add(arg0, arg1)
      }
    }
    _ =>
      raise @from_json_str.JsonDecodeError(
        (path, "GeneratedExpr::decode_json: expected enum value"),
      )
  }
}

///|
#json.generated
pub impl @from_json_str.FromJson for GeneratedNamedExpr with from_json(
  json,
  path,
) {
  match json {
    ["Named", json1, named_json] => {
      let arg1 = @from_json_str.FromJson::from_json(json1, path.add_index(1))
      match named_json {
        Object(named_obj) => {
          let arg0 = match named_obj.get("x") {
            Some(value) =>
              @from_json_str.FromJson::from_json(
                value,
                path.add_index(2).add_key("x"),
              )
            None =>
              raise @from_json_str.JsonDecodeError(
                (path.add_index(2).add_key("x"), "Missing field x"),
              )
          }
          let arg2 = match named_obj.get("y") {
            Some(value) =>
              @from_json_str.FromJson::from_json(
                value,
                path.add_index(2).add_key("y"),
              )
            None =>
              raise @from_json_str.JsonDecodeError(
                (path.add_index(2).add_key("y"), "Missing field y"),
              )
          }
          Named(x=arg0, arg1, y=arg2)
        }
        _ =>
          raise @from_json_str.JsonDecodeError(
            (
              path.add_index(2),
              "Named::from_json: expected named payload object",
            ),
          )
      }
    }
    _ =>
      raise @from_json_str.JsonDecodeError(
        (path, "GeneratedNamedExpr::from_json: expected enum value"),
      )
  }
}

///|
#json.generated
pub impl @from_json_str.FromJson for GeneratedNamedExpr with decode_json(
  decoder,
  path,
) {
  match decoder.read_variant_tag(path) {
    @from_json_str.Payload("Named") => {
      let arg1 = if decoder.next_array_value(path) {
        @from_json_str.FromJson::decode_json(decoder, path.add_index(1))
      } else {
        raise @from_json_str.JsonDecodeError(
          (path, "GeneratedNamedExpr::decode_json: missing constructor field 1"),
        )
      }
      if decoder.next_array_value(path) {
        let mut arg0 = None
        let mut arg2 = None
        decoder.begin_object(path.add_index(2))
        while true {
          match decoder.next_object_key(path.add_index(2)) {
            None => break
            Some("x") => {
              arg0 = Some(
                @from_json_str.FromJson::decode_json(
                  decoder,
                  path.add_index(2).add_key("x"),
                ),
              )
              continue
            }
            Some("y") => {
              arg2 = Some(
                @from_json_str.FromJson::decode_json(
                  decoder,
                  path.add_index(2).add_key("y"),
                ),
              )
              continue
            }
            Some(_) => {
              decoder.skip_value(path.add_index(2))
              continue
            }
          }
        }
        let arg0 = match arg0 {
          Some(value) => value
          None =>
            raise @from_json_str.JsonDecodeError(
              (path.add_index(2).add_key("x"), "Missing field x"),
            )
        }
        let arg2 = match arg2 {
          Some(value) => value
          None =>
            raise @from_json_str.JsonDecodeError(
              (path.add_index(2).add_key("y"), "Missing field y"),
            )
        }
        if decoder.next_array_value(path) {
          raise @from_json_str.JsonDecodeError(
            (
              path, "GeneratedNamedExpr::decode_json: too many constructor fields",
            ),
          )
        } else {
          Named(x=arg0, arg1, y=arg2)
        }
      } else {
        raise @from_json_str.JsonDecodeError(
          (
            path, "GeneratedNamedExpr::decode_json: missing constructor field named payload",
          ),
        )
      }
    }
    _ =>
      raise @from_json_str.JsonDecodeError(
        (path, "GeneratedNamedExpr::decode_json: expected enum value"),
      )
  }
}

///|
#json.generated
pub impl @from_json_str.FromJson for GeneratedProblem with from_json(json, path) {
  match json {
    "Finished" => Finished
    ["Bad", json0] => {
      let arg0 = @from_json_str.FromJson::from_json(json0, path.add_index(1))
      Bad(arg0)
    }
    ["Mixed", json1, named_json] => {
      let arg1 = @from_json_str.FromJson::from_json(json1, path.add_index(1))
      match named_json {
        Object(named_obj) => {
          let arg0 = match named_obj.get("x") {
            Some(value) =>
              @from_json_str.FromJson::from_json(
                value,
                path.add_index(2).add_key("x"),
              )
            None =>
              raise @from_json_str.JsonDecodeError(
                (path.add_index(2).add_key("x"), "Missing field x"),
              )
          }
          Mixed(x=arg0, arg1)
        }
        _ =>
          raise @from_json_str.JsonDecodeError(
            (
              path.add_index(2),
              "Mixed::from_json: expected named payload object",
            ),
          )
      }
    }
    _ =>
      raise @from_json_str.JsonDecodeError(
        (path, "GeneratedProblem::from_json: expected enum value"),
      )
  }
}

///|
#json.generated
pub impl @from_json_str.FromJson for GeneratedProblem with decode_json(
  decoder,
  path,
) {
  match decoder.read_variant_tag(path) {
    @from_json_str.Plain("Finished") => Finished
    @from_json_str.Payload("Bad") => {
      let arg0 = if decoder.next_array_value(path) {
        @from_json_str.FromJson::decode_json(decoder, path.add_index(1))
      } else {
        raise @from_json_str.JsonDecodeError(
          (path, "GeneratedProblem::decode_json: missing constructor field 0"),
        )
      }
      if decoder.next_array_value(path) {
        raise @from_json_str.JsonDecodeError(
          (path, "GeneratedProblem::decode_json: too many constructor fields"),
        )
      } else {
        Bad(arg0)
      }
    }
    @from_json_str.Payload("Mixed") => {
      let arg1 = if decoder.next_array_value(path) {
        @from_json_str.FromJson::decode_json(decoder, path.add_index(1))
      } else {
        raise @from_json_str.JsonDecodeError(
          (path, "GeneratedProblem::decode_json: missing constructor field 1"),
        )
      }
      if decoder.next_array_value(path) {
        let mut arg0 = None
        decoder.begin_object(path.add_index(2))
        while true {
          match decoder.next_object_key(path.add_index(2)) {
            None => break
            Some("x") => {
              arg0 = Some(
                @from_json_str.FromJson::decode_json(
                  decoder,
                  path.add_index(2).add_key("x"),
                ),
              )
              continue
            }
            Some(_) => {
              decoder.skip_value(path.add_index(2))
              continue
            }
          }
        }
        let arg0 = match arg0 {
          Some(value) => value
          None =>
            raise @from_json_str.JsonDecodeError(
              (path.add_index(2).add_key("x"), "Missing field x"),
            )
        }
        if decoder.next_array_value(path) {
          raise @from_json_str.JsonDecodeError(
            (path, "GeneratedProblem::decode_json: too many constructor fields"),
          )
        } else {
          Mixed(x=arg0, arg1)
        }
      } else {
        raise @from_json_str.JsonDecodeError(
          (
            path, "GeneratedProblem::decode_json: missing constructor field named payload",
          ),
        )
      }
    }
    _ =>
      raise @from_json_str.JsonDecodeError(
        (path, "GeneratedProblem::decode_json: expected enum value"),
      )
  }
}
