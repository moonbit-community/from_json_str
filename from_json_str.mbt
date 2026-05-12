///|
pub(open) trait FromJson {
  from_json(Json, JsonPath) -> Self raise JsonDecodeError
  decode_json(Decoder, JsonPath) -> Self raise JsonDecodeError = _
}

///|
pub(all) enum JsonPath {
  Root
  Key(JsonPath, mut key~ : String)
  Index(JsonPath, mut index~ : Int)
} derive(Eq, Debug)

///|
pub fn JsonPath::add_index(self : JsonPath, index : Int) -> JsonPath {
  Index(self, index~)
}

///|
pub fn JsonPath::add_key(self : JsonPath, key : String) -> JsonPath {
  Key(self, key~)
}

///|
pub impl Show for JsonPath with output(self, logger) {
  fn write_token(logger : &Logger, token : String) -> Unit {
    if !token.contains_any(chars="~/") {
      logger.write_string(token)
      return
    }
    for ch in token.iter() {
      match ch {
        '~' => logger.write_string("~0")
        '/' => logger.write_string("~1")
        _ => logger.write_char(ch)
      }
    }
  }

  fn build_path(path : JsonPath, logger : &Logger) -> Unit {
    match path {
      Root => ()
      Key(parent, key~) => {
        build_path(parent, logger)
        logger.write_char('/')
        write_token(logger, key)
      }
      Index(parent, index~) => {
        build_path(parent, logger)
        logger.write_char('/')
        logger.write_object(index)
      }
    }
  }

  build_path(self, logger)
}

///|
pub(all) suberror JsonDecodeError {
  JsonDecodeError((JsonPath, String))
} derive(Eq, Debug)

///|
pub impl Show for JsonDecodeError with output(self, logger) {
  match self {
    JsonDecodeError((path, msg)) => {
      logger.write_string("JsonDecodeError((")
      logger.write_object(path)
      logger.write_string(", ")
      logger.write_object(msg)
      logger.write_string("))")
    }
  }
}

///|
impl FromJson with decode_json(decoder, path) {
  let json = decoder.read_json(path)
  FromJson::from_json(json, path)
}

///|
pub fn[T : FromJson] from_json(
  json : Json,
  path? : JsonPath = Root,
) -> T raise JsonDecodeError {
  FromJson::from_json(json, path)
}

///|
pub fn[T : FromJson] from_str(
  input : StringView,
  max_nesting_depth? : Int = 1024,
) -> T raise JsonDecodeError {
  let decoder = Decoder::new(input, max_nesting_depth~)
  let value = FromJson::decode_json(decoder, Root)
  decoder.finish(path=Root)
  value
}

///|
fn[T] decode_error(path : JsonPath, msg : String) -> T raise JsonDecodeError {
  raise JsonDecodeError((path, msg))
}

///|
fn[T] syntax_error(path : JsonPath, msg : String) -> T raise JsonDecodeError {
  decode_error(path, "JSON syntax error: \{msg}")
}

///|
priv enum Token {
  Null
  True
  False
  Number(Double, String?)
  String(String)
  LBrace
  RBrace
  LBracket
  RBracket
  Comma
}

///|
priv enum Frame {
  Array(mut first~ : Bool)
  Object(mut first~ : Bool)
}

///|
pub(all) enum VariantTag {
  Plain(String)
  Payload(String)
} derive(Eq, Debug)

///|
pub struct Decoder {
  priv mut offset : Int
  priv input : StringView
  priv end_offset : Int
  priv mut remaining_available_depth : Int
  priv stack : Array[Frame]
}

///|
pub fn Decoder::new(
  input : StringView,
  max_nesting_depth? : Int = 1024,
) -> Decoder {
  {
    offset: 0,
    input,
    end_offset: input.length(),
    remaining_available_depth: max_nesting_depth,
    stack: [],
  }
}

///|
pub fn Decoder::finish(
  self : Decoder,
  path? : JsonPath = Root,
) -> Unit raise JsonDecodeError {
  if !self.stack.is_empty() {
    decode_error(path, "Decoder::finish: unclosed JSON container")
  }
  self.lex_skip_whitespace()
  if self.offset < self.end_offset {
    self.invalid_char(path)
  }
}

///|
pub fn Decoder::read_string(
  self : Decoder,
  path : JsonPath,
) -> String raise JsonDecodeError {
  match self.lex_value(path, allow_rbracket=false) {
    String(s) => s
    _ => decode_error(path, "String::decode_json: expected string")
  }
}

///|
pub fn Decoder::read_bool(
  self : Decoder,
  path : JsonPath,
) -> Bool raise JsonDecodeError {
  match self.lex_value(path, allow_rbracket=false) {
    True => true
    False => false
    _ => decode_error(path, "Bool::decode_json: expected boolean")
  }
}

///|
pub fn Decoder::read_int(
  self : Decoder,
  path : JsonPath,
) -> Int raise JsonDecodeError {
  guard self.lex_value(path, allow_rbracket=false) is Number(n, _) &&
    n != @double.infinity &&
    n != @double.neg_infinity else {
    decode_error(path, "Int::decode_json: expected number")
  }
  let max_ok = 2147483647.0
  let min_ok = -2147483648.0
  if n > max_ok || n < min_ok {
    decode_error(path, "Int::decode_json: overflow")
  }
  n.to_int()
}

///|
pub fn Decoder::read_double(
  self : Decoder,
  path : JsonPath,
) -> Double raise JsonDecodeError {
  match self.lex_value(path, allow_rbracket=false) {
    Number(n, _) if n != @double.infinity && n != @double.neg_infinity => n
    _ => decode_error(path, "Double::decode_json: expected number")
  }
}

///|
pub fn Decoder::read_null(
  self : Decoder,
  path : JsonPath,
) -> Unit raise JsonDecodeError {
  match self.lex_value(path, allow_rbracket=false) {
    Null => ()
    _ => decode_error(path, "Unit::decode_json: expected null")
  }
}

///|
pub fn Decoder::read_variant_tag(
  self : Decoder,
  path : JsonPath,
) -> VariantTag raise JsonDecodeError {
  self.lex_skip_whitespace()
  match self.read_char() {
    Some('"') => Plain(self.lex_string(path))
    Some('[') => {
      self.enter_container(path)
      self.stack.push(Array(first=true))
      if self.next_array_value(path) {
        Payload(self.read_string(path.add_index(0)))
      } else {
        decode_error(path, "Variant::decode_json: expected constructor tag")
      }
    }
    Some(_) => self.invalid_char(path, shift=-1)
    None => syntax_error(path, "unexpected end of input")
  }
}

///|
pub fn Decoder::begin_array(
  self : Decoder,
  path : JsonPath,
) -> Unit raise JsonDecodeError {
  match self.lex_value(path, allow_rbracket=false) {
    LBracket => {
      self.enter_container(path)
      self.stack.push(Array(first=true))
    }
    _ => decode_error(path, "Array::decode_json: expected array")
  }
}

///|
pub fn Decoder::next_array_value(
  self : Decoder,
  path : JsonPath,
) -> Bool raise JsonDecodeError {
  match self.stack {
    [.., Array(first~) as frame] =>
      if first {
        self.lex_skip_whitespace()
        match self.read_char() {
          Some(']') => {
            ignore(self.stack.pop())
            self.leave_container()
            false
          }
          Some(_) => {
            self.offset -= 1
            frame.first = false
            true
          }
          None => syntax_error(path, "unexpected end of input")
        }
      } else {
        match self.lex_after_array_value(path) {
          Comma => true
          RBracket => {
            ignore(self.stack.pop())
            self.leave_container()
            false
          }
          _ => abort("unreachable")
        }
      }
    _ => decode_error(path, "Decoder::next_array_value: not in array")
  }
}

///|
pub fn Decoder::begin_object(
  self : Decoder,
  path : JsonPath,
) -> Unit raise JsonDecodeError {
  match self.lex_value(path, allow_rbracket=false) {
    LBrace => {
      self.enter_container(path)
      self.stack.push(Object(first=true))
    }
    _ => decode_error(path, "Object::decode_json: expected object")
  }
}

///|
pub fn Decoder::next_object_key(
  self : Decoder,
  path : JsonPath,
) -> String? raise JsonDecodeError {
  match self.stack {
    [.., Object(first~) as frame] =>
      if first {
        self.lex_skip_whitespace()
        match self.read_char() {
          Some('}') => {
            ignore(self.stack.pop())
            self.leave_container()
            None
          }
          Some('"') => {
            frame.first = false
            let key = self.lex_string(path)
            self.lex_after_property_name(path)
            Some(key)
          }
          Some(_) => self.invalid_char(path, shift=-1)
          None => syntax_error(path, "unexpected end of input")
        }
      } else {
        match self.lex_after_object_value(path) {
          RBrace => {
            ignore(self.stack.pop())
            self.leave_container()
            None
          }
          Comma => {
            self.lex_skip_whitespace()
            match self.read_char() {
              Some('"') => {
                let key = self.lex_string(path)
                self.lex_after_property_name(path)
                Some(key)
              }
              Some(_) => self.invalid_char(path, shift=-1)
              None => syntax_error(path, "unexpected end of input")
            }
          }
          _ => abort("unreachable")
        }
      }
    _ => decode_error(path, "Decoder::next_object_key: not in object")
  }
}

///|
pub fn Decoder::skip_value(
  self : Decoder,
  path : JsonPath,
) -> Unit raise JsonDecodeError {
  self.skip_value_at(path)
}

///|
pub fn Decoder::read_json(
  self : Decoder,
  path : JsonPath,
) -> Json raise JsonDecodeError {
  let tok = self.lex_value(path, allow_rbracket=false)
  self.parse_value2(tok, path)
}

///|
fn Decoder::parse_value2(
  self : Decoder,
  tok : Token,
  path : JsonPath,
) -> Json raise JsonDecodeError {
  match tok {
    Null => null
    True => Json::boolean(true)
    False => Json::boolean(false)
    Number(n, repr) => Json::number(n, repr?)
    String(s) => Json::string(s)
    LBrace => self.parse_object(path)
    LBracket => self.parse_array(path)
    RBracket | RBrace | Comma => abort("unreachable")
  }
}

///|
fn Decoder::parse_object(
  self : Decoder,
  path : JsonPath,
) -> Json raise JsonDecodeError {
  self.enter_container(path)
  let map = Map([])
  let mut first = true
  for ;; {
    self.lex_skip_whitespace()
    if !first {
      match self.read_char() {
        Some(',') => ()
        Some('}') => {
          self.leave_container()
          return Json::object(map)
        }
        Some(_) => self.invalid_char(path, shift=-1)
        None => syntax_error(path, "unexpected end of input")
      }
      self.lex_skip_whitespace()
    }
    match self.read_char() {
      Some('}') if first => {
        self.leave_container()
        return Json::object(map)
      }
      Some('"') => {
        let key = self.lex_string(path)
        self.lex_after_property_name(path)
        map[key] = self.read_json(path.add_key(key))
        first = false
      }
      Some(_) => self.invalid_char(path, shift=-1)
      None => syntax_error(path, "unexpected end of input")
    }
  }
}

///|
fn Decoder::parse_array(
  self : Decoder,
  path : JsonPath,
) -> Json raise JsonDecodeError {
  self.enter_container(path)
  let values = []
  let mut first = true
  let mut index = 0
  for ;; {
    self.lex_skip_whitespace()
    if !first {
      match self.read_char() {
        Some(',') => ()
        Some(']') => {
          self.leave_container()
          return Json::array(values)
        }
        Some(_) => self.invalid_char(path, shift=-1)
        None => syntax_error(path, "unexpected end of input")
      }
      self.lex_skip_whitespace()
    }
    match self.read_char() {
      Some(']') if first => {
        self.leave_container()
        return Json::array(values)
      }
      Some(_) => {
        self.offset -= 1
        values.push(self.read_json(path.add_index(index)))
        index += 1
        first = false
      }
      None => syntax_error(path, "unexpected end of input")
    }
  }
}

///|
fn Decoder::skip_value_at(
  self : Decoder,
  path : JsonPath,
) -> Unit raise JsonDecodeError {
  match self.lex_value(path, allow_rbracket=false) {
    LBrace => {
      self.enter_container(path)
      let mut first = true
      for ;; {
        self.lex_skip_whitespace()
        if !first {
          match self.read_char() {
            Some(',') => ()
            Some('}') => {
              self.leave_container()
              return
            }
            Some(_) => self.invalid_char(path, shift=-1)
            None => syntax_error(path, "unexpected end of input")
          }
          self.lex_skip_whitespace()
        }
        match self.read_char() {
          Some('}') if first => {
            self.leave_container()
            return
          }
          Some('"') => {
            let key = self.lex_string(path)
            self.lex_after_property_name(path)
            self.skip_value_at(path.add_key(key))
            first = false
          }
          Some(_) => self.invalid_char(path, shift=-1)
          None => syntax_error(path, "unexpected end of input")
        }
      }
    }
    LBracket => {
      self.enter_container(path)
      let mut first = true
      let mut index = 0
      for ;; {
        self.lex_skip_whitespace()
        if !first {
          match self.read_char() {
            Some(',') => ()
            Some(']') => {
              self.leave_container()
              return
            }
            Some(_) => self.invalid_char(path, shift=-1)
            None => syntax_error(path, "unexpected end of input")
          }
          self.lex_skip_whitespace()
        }
        match self.read_char() {
          Some(']') if first => {
            self.leave_container()
            return
          }
          Some(_) => {
            self.offset -= 1
            self.skip_value_at(path.add_index(index))
            index += 1
            first = false
          }
          None => syntax_error(path, "unexpected end of input")
        }
      }
    }
    _ => ()
  }
}

///|
fn Decoder::enter_container(
  self : Decoder,
  path : JsonPath,
) -> Unit raise JsonDecodeError {
  if self.remaining_available_depth <= 0 {
    decode_error(path, "JSON syntax error: depth limit exceeded")
  }
  self.remaining_available_depth -= 1
}

///|
fn Decoder::leave_container(self : Decoder) -> Unit {
  self.remaining_available_depth += 1
}

///|
fn Decoder::read_char(self : Decoder) -> Char? {
  if self.offset < self.end_offset {
    let c1 = self.input.unsafe_get(self.offset).to_int()
    self.offset += 1
    if c1 >= 0xD800 && c1 <= 0xDBFF {
      if self.offset < self.end_offset {
        let c2 = self.input.unsafe_get(self.offset).to_int()
        if c2 >= 0xDC00 && c2 <= 0xDFFF {
          self.offset += 1
          let c3 = (c1 << 10) + c2 - 0x35fdc00
          return Some(c3.unsafe_to_char())
        }
      }
    }
    Some(c1.unsafe_to_char())
  } else {
    None
  }
}

///|
fn Decoder::expect_ascii_char(
  self : Decoder,
  path : JsonPath,
  c : Byte,
) -> Unit raise JsonDecodeError {
  guard self.offset < self.end_offset else {
    syntax_error(path, "unexpected end of input")
  }
  let c1 = self.input.unsafe_get(self.offset).to_int()
  self.offset += 1
  if c.to_int() != c1 {
    self.invalid_char(path, shift=-1)
  }
}

///|
fn Decoder::lex_skip_whitespace(self : Decoder) -> Unit {
  let rest = self.input.view(
    start_offset=self.offset,
    end_offset=self.end_offset,
  )
  lexmatch rest with longest {
    ("[ \t\r\n]+", next) => self.offset = self.end_offset - next.length()
    _ => ()
  }
}

///|
fn Decoder::lex_after_array_value(
  self : Decoder,
  path : JsonPath,
) -> Token raise JsonDecodeError {
  self.lex_skip_whitespace()
  match self.read_char() {
    Some(']') => RBracket
    Some(',') => Comma
    Some(_) => self.invalid_char(path, shift=-1)
    None => syntax_error(path, "unexpected end of input")
  }
}

///|
fn Decoder::lex_after_property_name(
  self : Decoder,
  path : JsonPath,
) -> Unit raise JsonDecodeError {
  self.lex_skip_whitespace()
  match self.read_char() {
    Some(':') => ()
    Some(_) => self.invalid_char(path, shift=-1)
    None => syntax_error(path, "unexpected end of input")
  }
}

///|
fn Decoder::lex_after_object_value(
  self : Decoder,
  path : JsonPath,
) -> Token raise JsonDecodeError {
  self.lex_skip_whitespace()
  match self.read_char() {
    Some('}') => RBrace
    Some(',') => Comma
    Some(_) => self.invalid_char(path, shift=-1)
    None => syntax_error(path, "unexpected end of input")
  }
}

///|
fn Decoder::lex_value(
  self : Decoder,
  path : JsonPath,
  allow_rbracket~ : Bool,
) -> Token raise JsonDecodeError {
  self.lex_skip_whitespace()
  match self.read_char() {
    Some('{') => LBrace
    Some('[') => LBracket
    Some(']') =>
      if allow_rbracket {
        RBracket
      } else {
        self.invalid_char(path, shift=-1)
      }
    Some('n') => {
      self.expect_ascii_char(path, b'u')
      self.expect_ascii_char(path, b'l')
      self.expect_ascii_char(path, b'l')
      Null
    }
    Some('t') => {
      self.expect_ascii_char(path, b'r')
      self.expect_ascii_char(path, b'u')
      self.expect_ascii_char(path, b'e')
      True
    }
    Some('f') => {
      self.expect_ascii_char(path, b'a')
      self.expect_ascii_char(path, b'l')
      self.expect_ascii_char(path, b's')
      self.expect_ascii_char(path, b'e')
      False
    }
    Some('-') =>
      match self.read_char() {
        Some('0') => {
          let (n, repr) = self.lex_zero(path, start=self.offset - 2)
          Number(n, repr.map(repr => repr.to_owned()))
        }
        Some(c2) =>
          if c2 is ('1'..='9') {
            let (n, repr) = self.lex_decimal_integer(
              path,
              start=self.offset - 2,
            )
            Number(n, repr.map(repr => repr.to_owned()))
          } else {
            self.invalid_char(path, shift=-1)
          }
        None => syntax_error(path, "unexpected end of input")
      }
    Some('0') => {
      let (n, repr) = self.lex_zero(path, start=self.offset - 1)
      Number(n, repr.map(repr => repr.to_owned()))
    }
    Some('1'..='9') => {
      let (n, repr) = self.lex_decimal_integer(path, start=self.offset - 1)
      Number(n, repr.map(repr => repr.to_owned()))
    }
    Some('"') => String(self.lex_string(path))
    Some(c) => {
      let shift = -c.utf16_len()
      self.invalid_char(path, shift~)
    }
    None => syntax_error(path, "unexpected end of input")
  }
}

///|
fn Decoder::lex_string(
  self : Decoder,
  path : JsonPath,
) -> String raise JsonDecodeError {
  let buf = StringBuilder::new()
  let mut start = self.offset
  fn flush(end : Int) {
    if start > 0 && end > start {
      buf.write_view(self.input[start:end])
    }
  }

  for ;; {
    match self.read_char() {
      Some('"') => {
        flush(self.offset - 1)
        break
      }
      Some('\n' | '\r') => self.invalid_char(path, shift=-1)
      Some('\\') => {
        flush(self.offset - 1)
        match self.read_char() {
          Some('b') => buf.write_char('\b')
          Some('f') => buf.write_char('\u{0C}')
          Some('n') => buf.write_char('\n')
          Some('r') => buf.write_char('\r')
          Some('t') => buf.write_char('\t')
          Some('"') => buf.write_char('"')
          Some('\\') => buf.write_char('\\')
          Some('/') => buf.write_char('/')
          Some('u') => {
            let c = self.lex_hex_digits(path, 4)
            buf.write_char(c.unsafe_to_char())
          }
          Some(_) => self.invalid_char(path, shift=-1)
          None => syntax_error(path, "unexpected end of input")
        }
        start = self.offset
      }
      Some(ch) =>
        if ch.to_int() < 32 {
          self.invalid_char(path, shift=-1)
        } else {
          continue
        }
      None => syntax_error(path, "unexpected end of input")
    }
  }
  buf.to_string()
}

///|
fn Decoder::lex_hex_digits(
  self : Decoder,
  path : JsonPath,
  n : Int,
) -> Int raise JsonDecodeError {
  for _ in 0..<n; r = 0 {
    match self.read_char() {
      Some(c) =>
        if c >= 'A' {
          let d = (c.to_int() & (32).lnot()) - 'A'.to_int() + 10
          if d > 15 {
            self.invalid_char(path, shift=-1)
          }
          continue (r << 4) | d
        } else if c >= '0' {
          let d = c.to_int() - '0'.to_int()
          if d > 9 {
            self.invalid_char(path, shift=-1)
          }
          continue (r << 4) | d
        } else {
          self.invalid_char(path, shift=-1)
        }
      None => syntax_error(path, "unexpected end of input")
    }
  } nobreak {
    r
  }
}

///|
fn Decoder::lex_decimal_integer(
  self : Decoder,
  path : JsonPath,
  start~ : Int,
) -> (Double, StringView?) raise JsonDecodeError {
  for ;; {
    match self.read_char() {
      Some('.') => return self.lex_decimal_point(path, start~)
      Some('e' | 'E') => return self.lex_decimal_exponent(path, start~)
      Some(c) => {
        if c >= '0' && c <= '9' {
          continue
        }
        self.offset -= 1
        return self.lex_number_end(start, self.offset)
      }
      None => return self.lex_number_end(start, self.offset)
    }
  }
}

///|
fn Decoder::lex_decimal_point(
  self : Decoder,
  path : JsonPath,
  start~ : Int,
) -> (Double, StringView?) raise JsonDecodeError {
  match self.read_char() {
    Some(c) =>
      if c >= '0' && c <= '9' {
        self.lex_decimal_fraction(path, start~)
      } else {
        self.invalid_char(path, shift=-1)
      }
    None => syntax_error(path, "unexpected end of input")
  }
}

///|
fn Decoder::lex_decimal_fraction(
  self : Decoder,
  path : JsonPath,
  start~ : Int,
) -> (Double, StringView?) raise JsonDecodeError {
  for ;; {
    match self.read_char() {
      Some('e' | 'E') => return self.lex_decimal_exponent(path, start~)
      Some(c) => {
        if c >= '0' && c <= '9' {
          continue
        }
        self.offset -= 1
        return self.lex_number_end(start, self.offset)
      }
      None => return self.lex_number_end(start, self.offset)
    }
  }
}

///|
fn Decoder::lex_decimal_exponent(
  self : Decoder,
  path : JsonPath,
  start~ : Int,
) -> (Double, StringView?) raise JsonDecodeError {
  match self.read_char() {
    Some('+') | Some('-') => self.lex_decimal_exponent_sign(path, start~)
    Some(c) =>
      if c >= '0' && c <= '9' {
        self.lex_decimal_exponent_integer(start~)
      } else {
        self.offset -= 1
        self.invalid_char(path)
      }
    None => syntax_error(path, "unexpected end of input")
  }
}

///|
fn Decoder::lex_decimal_exponent_sign(
  self : Decoder,
  path : JsonPath,
  start~ : Int,
) -> (Double, StringView?) raise JsonDecodeError {
  match self.read_char() {
    Some(c) =>
      if c >= '0' && c <= '9' {
        self.lex_decimal_exponent_integer(start~)
      } else {
        self.offset -= 1
        self.invalid_char(path)
      }
    None => syntax_error(path, "unexpected end of input")
  }
}

///|
fn Decoder::lex_decimal_exponent_integer(
  self : Decoder,
  start~ : Int,
) -> (Double, StringView?) {
  for ;; {
    match self.read_char() {
      Some(c) => {
        if c >= '0' && c <= '9' {
          continue
        }
        self.offset -= 1
        return self.lex_number_end(start, self.offset)
      }
      None => return self.lex_number_end(start, self.offset)
    }
  }
}

///|
fn Decoder::lex_zero(
  self : Decoder,
  path : JsonPath,
  start~ : Int,
) -> (Double, StringView?) raise JsonDecodeError {
  match self.read_char() {
    Some('.') => self.lex_decimal_point(path, start~)
    Some('e' | 'E') => self.lex_decimal_exponent(path, start~)
    Some(c) => {
      if c >= '0' && c <= '9' {
        self.offset -= 1
        self.invalid_char(path)
      }
      self.offset -= 1
      self.lex_number_end(start, self.offset)
    }
    None => self.lex_number_end(start, self.offset)
  }
}

///|
fn Decoder::lex_number_end(
  self : Decoder,
  start : Int,
  end : Int,
) -> (Double, StringView?) {
  let s = self.input.view(start_offset=start, end_offset=end)
  if !s.contains(".") && !s.contains("e") && !s.contains("E") {
    let parsed_int = try? @string.parse_int64(s)
    match parsed_int {
      Ok(i) if i <= 9007199254740991 && i >= -9007199254740991 =>
        (i.to_double(), None)
      _ =>
        if s is ['-', ..] {
          (@double.neg_infinity, Some(s))
        } else {
          (@double.infinity, Some(s))
        }
    }
  } else {
    let parsed_double = try? @string.parse_double(s)
    match parsed_double {
      Ok(d) => (d, None)
      Err(_) =>
        if s is ['-', ..] {
          (@double.neg_infinity, Some(s))
        } else {
          (@double.infinity, Some(s))
        }
    }
  }
}

///|
fn[T] Decoder::invalid_char(
  self : Decoder,
  path : JsonPath,
  shift? : Int = 0,
) -> T raise JsonDecodeError {
  let offset = self.offset + shift
  let char_text = if offset >= 0 && offset < self.end_offset {
    self.input.unsafe_get(offset).to_int().unsafe_to_char().escape()
  } else {
    "<eof>"
  }
  syntax_error(path, "invalid character \{char_text}")
}

///|
pub impl FromJson for Bool with from_json(json, path) {
  match json {
    true => true
    false => false
    _ => decode_error(path, "Bool::from_json: expected boolean")
  }
}

///|
pub impl FromJson for Bool with decode_json(decoder, path) {
  decoder.read_bool(path)
}

///|
pub impl FromJson for Int with from_json(json, path) {
  guard json is Number(n, ..) &&
    n != @double.infinity &&
    n != @double.neg_infinity else {
    decode_error(path, "Int::from_json: expected number")
  }
  let max_ok = 2147483647.0
  let min_ok = -2147483648.0
  if n > max_ok || n < min_ok {
    decode_error(path, "Int::from_json: overflow")
  }
  n.to_int()
}

///|
pub impl FromJson for Int with decode_json(decoder, path) {
  decoder.read_int(path)
}

///|
pub impl FromJson for Double with from_json(json, path) {
  match json {
    Number(n, ..) if n != @double.infinity && n != @double.neg_infinity => n
    _ => decode_error(path, "Double::from_json: expected number")
  }
}

///|
pub impl FromJson for Double with decode_json(decoder, path) {
  decoder.read_double(path)
}

///|
pub impl FromJson for String with from_json(json, path) {
  guard json is String(s) else {
    decode_error(path, "String::from_json: expected string")
  }
  s
}

///|
pub impl FromJson for String with decode_json(decoder, path) {
  decoder.read_string(path)
}

///|
pub impl FromJson for Unit with from_json(json, path) {
  guard json is Null else {
    decode_error(path, "Unit::from_json: expected null")
  }
}

///|
pub impl FromJson for Unit with decode_json(decoder, path) {
  decoder.read_null(path)
}

///|
pub impl FromJson for Json with from_json(json, _path) {
  json
}

///|
pub impl FromJson for Json with decode_json(decoder, path) {
  decoder.read_json(path)
}

///|
pub impl[X : FromJson] FromJson for Array[X] with from_json(json, path) {
  guard json is Array(a) else {
    decode_error(path, "Array::from_json: expected array")
  }
  a.mapi((i, x) => FromJson::from_json(x, path.add_index(i)))
}

///|
pub impl[X : FromJson] FromJson for Array[X] with decode_json(decoder, path) {
  decoder.begin_array(path)
  let xs = []
  let mut i = 0
  while decoder.next_array_value(path) {
    xs.push(FromJson::decode_json(decoder, path.add_index(i)))
    i += 1
  }
  xs
}

///|
pub impl[V : FromJson] FromJson for Map[String, V] with from_json(json, path) {
  guard json is Object(obj) else {
    decode_error(path, "Map::from_json: expected object")
  }
  let res = {}
  for k, v in obj {
    res[k] = FromJson::from_json(v, path.add_key(k))
  }
  res
}

///|
pub impl[V : FromJson] FromJson for Map[String, V] with decode_json(
  decoder,
  path,
) {
  decoder.begin_object(path)
  let res = {}
  for key = decoder.next_object_key(path) {
    match key {
      None => break
      Some(key) => {
        res[key] = FromJson::decode_json(decoder, path.add_key(key))
        continue decoder.next_object_key(path)
      }
    }
  }
  res
}

///|
pub(all) struct S[T] {
  x : T
} derive(Eq, Debug)

///|
pub impl[T : Show] Show for S[T] with output(self, logger) {
  logger.write_string("{x: ")
  logger.write_object(self.x)
  logger.write_string("}")
}

///|
pub impl[T : FromJson] FromJson for S[T] with from_json(json, path) {
  guard json is Object(obj) else {
    decode_error(path, "S::from_json: expected object")
  }
  let x = match obj.get("x") {
    Some(v) => FromJson::from_json(v, path.add_key("x"))
    None => decode_error(path, "Missing field x")
  }
  { x, }
}

///|
pub impl[T : FromJson] FromJson for S[T] with decode_json(decoder, path) {
  decoder.begin_object(path)
  let mut x = None
  for key = decoder.next_object_key(path) {
    match key {
      None => break
      Some("x") => {
        x = Some(FromJson::decode_json(decoder, path.add_key("x")))
        continue decoder.next_object_key(path)
      }
      Some(_) => {
        decoder.skip_value(path)
        continue decoder.next_object_key(path)
      }
    }
  }
  let x = match x {
    Some(v) => v
    None => decode_error(path, "Missing field x")
  }
  { x, }
}
