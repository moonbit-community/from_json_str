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
