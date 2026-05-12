///|
using @list {type List}

///|
const NAMESPACE = "json"

///|
const ATTR_FROM_JSON_STR = "from_json_str"

///|
const ATTR_PRIVATE_FROM_JSON_STR = "private_from_json_str"

///|
const RUNTIME = "from_json_str"

///|
let pos : @basic.Position = { cnum: 0, fname: "", lnum: 0, bol: 0 }

///|
let loc : @basic.Location = { start: pos, end: pos }

///|
fn is_from_json_str_derive(attrs : List[@attribute.Attribute]) -> Bool? raise {
  for attr in attrs {
    match attr.parsed {
      Some(Ident({ qual: Some(NAMESPACE), name: ATTR_FROM_JSON_STR })) =>
        return Some(false)
      Some(Ident({ qual: Some(NAMESPACE), name: ATTR_PRIVATE_FROM_JSON_STR })) =>
        return Some(true)
      Some(Apply({ qual: Some(NAMESPACE), name: ATTR_FROM_JSON_STR }, props)) => {
        guard props is Empty else {
          fail("Unsupported property in #\{NAMESPACE}.\{ATTR_FROM_JSON_STR}")
        }
        return Some(false)
      }
      Some(
        Apply(
          { qual: Some(NAMESPACE), name: ATTR_PRIVATE_FROM_JSON_STR },
          props
        )
      ) => {
        guard props is Empty else {
          fail(
            "Unsupported property in #\{NAMESPACE}.\{ATTR_PRIVATE_FROM_JSON_STR}",
          )
        }
        return Some(true)
      }
      _ => ()
    }
  }
  None
}

///|
fn generated_attr() -> @attribute.Attribute {
  {
    parsed: Some(Ident({ qual: Some(NAMESPACE), name: "generated" })),
    raw: "",
    loc,
  }
}

///|
fn type_param_names(
  params : List[@syntax.TypeDeclBinder],
) -> Array[String] raise {
  let names = []
  for param in params {
    match param.name {
      Some(name) => names.push(name)
      None =>
        fail("from_json_str derive does not support anonymous type params")
    }
  }
  names
}

///|
fn runtime_ident(name : String) -> @syntax.LongIdent {
  Dot(pkg=RUNTIME, id=name)
}

///|
fn local_ident(name : String) -> @syntax.LongIdent {
  Ident(name~)
}

///|
fn binder(name : String) -> @syntax.Binder {
  { name, loc }
}

///|
fn label(name : String) -> @syntax.Label {
  { name, loc }
}

///|
fn mk_var(name : String, pkg? : String) -> @syntax.Var {
  let name = match pkg {
    None => local_ident(name)
    Some(pkg) => Dot(pkg~, id=name)
  }
  { name, loc }
}

///|
fn e_id(name : String, pkg? : String) -> @syntax.Expr {
  Ident(id=mk_var(name, pkg?), loc~)
}

///|
fn e_string(s : String) -> @syntax.Expr {
  Constant(c=String(s), loc~)
}

///|
fn e_int(i : Int) -> @syntax.Expr {
  Constant(c=Int(i.to_string()), loc~)
}

///|
fn e_tuple(es : Array[@syntax.Expr]) -> @syntax.Expr {
  Tuple(exprs=List::from_array(es), loc~)
}

///|
fn p_any() -> @syntax.Pattern {
  Any(loc~)
}

///|
fn p_var(name : String) -> @syntax.Pattern {
  Var(binder(name))
}

///|
fn p_string(s : String) -> @syntax.Pattern {
  Constant(c=String(s), loc~)
}

///|
fn p_array(pats : Array[@syntax.Pattern]) -> @syntax.Pattern {
  @syntax.Pattern::Array(
    pats=Closed(
      List::from_array(pats.map(pat => @syntax.ArrayPattern::Pattern(pat))),
    ),
    loc~,
  )
}

///|
fn p_constr(
  name : String,
  args? : Array[@syntax.Pattern] = [],
  pkg? : String,
  ty? : String,
) -> @syntax.Pattern {
  let extra_info : @syntax.ConstructorExtraInfo = match (pkg, ty) {
    (Some(pkg), Some(id)) =>
      TypeName({ name: Dot(pkg~, id~), loc, is_object: false })
    (Some(pkg), None) => Package(pkg)
    (None, Some(id)) =>
      TypeName({ name: Ident(name=id), loc, is_object: false })
    (None, None) => NoExtraInfo
  }
  let args = match args {
    [] => None
    _ =>
      Some(
        List::from_array(
          args.map(pat => @syntax.ConstrPatArg::{ pat, kind: Positional }),
        ),
      )
  }
  Constr(
    constr={ extra_info, name: @syntax.ConstrName::{ name, loc }, loc },
    args~,
    is_open=false,
    loc~,
  )
}

///|
fn e_constr(name : String, pkg? : String, ty? : String) -> @syntax.Expr {
  let extra_info : @syntax.ConstructorExtraInfo = match (pkg, ty) {
    (Some(pkg), Some(id)) =>
      TypeName({ name: Dot(pkg~, id~), loc, is_object: false })
    (Some(pkg), None) => Package(pkg)
    (None, Some(id)) =>
      TypeName({ name: Ident(name=id), loc, is_object: false })
    (None, None) => NoExtraInfo
  }
  Constr(
    constr={ name: @syntax.ConstrName::{ name, loc }, extra_info, loc },
    loc~,
  )
}

///|
fn e_apply(func : @syntax.Expr, args : Array[@syntax.Expr]) -> @syntax.Expr {
  Apply(
    func~,
    args=List::from_array(
      args.map(value => @syntax.Argument::{ value, kind: Positional }),
    ),
    attr=NoAttr,
    loc~,
  )
}

///|
fn e_apply_with_kinds(
  func : @syntax.Expr,
  args : Array[(@syntax.Expr, @syntax.ArgumentKind)],
) -> @syntax.Expr {
  Apply(
    func~,
    args=List::from_array(
      args.map(pair => {
        let (value, kind) = pair
        @syntax.Argument::{ value, kind }
      }),
    ),
    attr=NoAttr,
    loc~,
  )
}

///|
fn e_method(ty : String, name : String, pkg? : String) -> @syntax.Expr {
  let type_name = match pkg {
    None => local_ident(ty)
    Some(pkg) => Dot(pkg~, id=ty)
  }
  Method(
    type_name={ name: type_name, is_object: false, loc },
    method_name=label(name),
    loc~,
  )
}

///|
fn e_call_method(
  receiver : @syntax.Expr,
  method_name : String,
  args : Array[@syntax.Expr],
) -> @syntax.Expr {
  DotApply(
    self=receiver,
    method_name=label(method_name),
    args=List::from_array(
      args.map(value => @syntax.Argument::{ value, kind: Positional }),
    ),
    return_self=false,
    attr=NoAttr,
    loc~,
  )
}

///|
fn p_case(
  pattern : @syntax.Pattern,
  body : @syntax.Expr,
  guard_? : @syntax.Expr,
) -> @syntax.Case {
  { pattern, body, guard_ }
}

///|
fn e_match(expr : @syntax.Expr, cases : Array[@syntax.Case]) -> @syntax.Expr {
  Match(expr~, cases=List::from_array(cases), match_loc=loc, loc~)
}

///|
fn e_let(
  pattern : @syntax.Pattern,
  expr : @syntax.Expr,
  body : @syntax.Expr,
) -> @syntax.Expr {
  Let(pattern~, expr~, body~, loc~)
}

///|
fn e_seq(exprs : Array[@syntax.Expr], last : @syntax.Expr) -> @syntax.Expr {
  Sequence(exprs=List::from_array(exprs), last_expr=last, loc~)
}

///|
fn e_if(
  cond : @syntax.Expr,
  ifso : @syntax.Expr,
  ifnot : @syntax.Expr,
) -> @syntax.Expr {
  If(cond~, ifso~, ifnot=Some(ifnot), loc~)
}

///|
fn e_record(fields : Array[String]) -> @syntax.Expr {
  Record(
    type_name=None,
    fields=List::from_array(
      fields.map(name => @syntax.FieldDef::{
        label: label(name),
        expr: e_id(name),
        is_pun: true,
        loc,
      }),
    ),
    trailing=Comma,
    loc~,
  )
}

///|
fn e_raise_decode_error(message : String) -> @syntax.Expr {
  e_raise_decode_error_at(e_id("path"), message)
}

///|
fn e_raise_decode_error_at(
  path_expr : @syntax.Expr,
  message : String,
) -> @syntax.Expr {
  Raise(
    err_value=e_apply(e_constr("JsonDecodeError", pkg=RUNTIME), [
      e_tuple([path_expr, e_string(message)]),
    ]),
    loc~,
  )
}

///|
fn e_path_index(index : Int) -> @syntax.Expr {
  e_call_method(e_id("path"), "add_index", [e_int(index)])
}

///|
fn e_path_key(base_path : @syntax.Expr, key : String) -> @syntax.Expr {
  e_call_method(base_path, "add_key", [e_string(key)])
}

///|
fn e_from_json_at_path(
  value : @syntax.Expr,
  path_expr : @syntax.Expr,
) -> @syntax.Expr {
  e_apply(e_method("FromJson", "from_json", pkg=RUNTIME), [value, path_expr])
}

///|
fn e_from_json_call(value : @syntax.Expr, key : String) -> @syntax.Expr {
  e_from_json_at_path(value, e_path_key(e_id("path"), key))
}

///|
fn e_from_json_index_call(value : @syntax.Expr, index : Int) -> @syntax.Expr {
  e_from_json_at_path(value, e_path_index(index))
}

///|
fn e_decode_json_at_path(path_expr : @syntax.Expr) -> @syntax.Expr {
  e_apply(e_method("FromJson", "decode_json", pkg=RUNTIME), [
    e_id("decoder"),
    path_expr,
  ])
}

///|
fn e_decode_json_index_call(index : Int) -> @syntax.Expr {
  e_decode_json_at_path(e_path_index(index))
}

///|
fn e_option_some(value : @syntax.Expr) -> @syntax.Expr {
  e_apply(e_constr("Some"), [value])
}

///|
fn e_assign(name : String, expr : @syntax.Expr) -> @syntax.Expr {
  Assign(var_=mk_var(name), expr~, augmented_by=None, loc~)
}

///|
fn e_break() -> @syntax.Expr {
  Break(arg=None, label=None, loc~)
}

///|
fn e_continue() -> @syntax.Expr {
  Continue(args=List::empty(), label=None, loc~)
}

///|
fn e_while_true(body : @syntax.Expr) -> @syntax.Expr {
  While(
    loop_cond=Constant(c=Bool(true), loc~),
    loop_body=body,
    while_else=None,
    label=None,
    loc~,
  )
}

///|
fn e_let_mut(
  name : String,
  expr : @syntax.Expr,
  body : @syntax.Expr,
) -> @syntax.Expr {
  LetMut(binder=binder(name), ty=None, expr~, body~, loc~)
}

///|
fn e_begin_object() -> @syntax.Expr {
  e_begin_object_at(e_id("path"))
}

///|
fn e_begin_object_at(path_expr : @syntax.Expr) -> @syntax.Expr {
  e_call_method(e_id("decoder"), "begin_object", [path_expr])
}

///|
fn e_read_variant_tag() -> @syntax.Expr {
  e_call_method(e_id("decoder"), "read_variant_tag", [e_id("path")])
}

///|
fn e_next_array_value() -> @syntax.Expr {
  e_call_method(e_id("decoder"), "next_array_value", [e_id("path")])
}

///|
fn e_next_key() -> @syntax.Expr {
  e_next_key_at(e_id("path"))
}

///|
fn e_next_key_at(path_expr : @syntax.Expr) -> @syntax.Expr {
  e_call_method(e_id("decoder"), "next_object_key", [path_expr])
}

///|
fn e_skip_unknown() -> @syntax.Expr {
  e_skip_unknown_at(e_id("path"))
}

///|
fn e_skip_unknown_at(path_expr : @syntax.Expr) -> @syntax.Expr {
  e_seq(
    [e_call_method(e_id("decoder"), "skip_value", [path_expr])],
    e_continue(),
  )
}

///|
fn self_ty(tycon : String, params : Array[String]) -> @syntax.Type {
  Name(
    constr_id={ id: local_ident(tycon), loc },
    tys=List::from_array(
      params.map(name => {
        @syntax.Type::Name(
          constr_id={ id: local_ident(name), loc },
          tys=List::empty(),
          loc~,
        )
      }),
    ),
    loc~,
  )
}

///|
fn quantifiers(params : Array[String]) -> List[@syntax.TypeVarBinder] {
  List::from_array(
    params.map(name => @syntax.TypeVarBinder::{
      name,
      name_loc: loc,
      constraints: List::from_array([
        @syntax.TypeVarConstraint::{ trait_: runtime_ident("FromJson"), loc },
      ]),
    }),
  )
}

///|
fn top_impl(
  decl : @syntax.TypeDecl,
  method_name : String,
  params : Array[String],
  body : @syntax.Expr,
  private~ : Bool,
) -> @syntax.Impl {
  let vis : @syntax.Visibility = if private {
    Priv(loc~)
  } else {
    Pub(attr=None, loc~)
  }
  TopImpl(
    trait_={ name: runtime_ident("FromJson"), is_object: false, loc },
    self_ty=Some(self_ty(decl.tycon, params)),
    method_name=binder(method_name),
    has_error=None,
    quantifiers=quantifiers(params),
    params=List::from_array([
      @syntax.Parameter::Positional(
        binder=binder(
          if method_name == "from_json" {
            "json"
          } else {
            "decoder"
          },
        ),
        ty=None,
      ),
      @syntax.Parameter::Positional(binder=binder("path"), ty=None),
    ]),
    ret_ty=None,
    err_ty=NoErrorType,
    body=DeclBody(local_types=List::empty(), expr=body),
    vis~,
    loc~,
    attrs=List::from_array([generated_attr()]),
    doc=@syntax.DocString::empty(),
  )
}

///|
fn field_names(fields : List[@syntax.FieldDecl]) -> Array[String] {
  fields.map(field => field.name.label).to_array()
}

///|
fn fold_lets(
  bindings : Array[(String, @syntax.Expr)],
  last : @syntax.Expr,
) -> @syntax.Expr {
  let mut result = last
  for i in 0..<bindings.length() {
    let index = bindings.length() - 1 - i
    let (name, expr) = bindings[index]
    result = e_let(p_var(name), expr, result)
  }
  result
}

///|
fn derive_from_json_impl(
  decl : @syntax.TypeDecl,
  fields : List[@syntax.FieldDecl],
  private~ : Bool,
) -> @syntax.Impl raise {
  let params = type_param_names(decl.params)
  let bindings = fields
    .map(field => {
      let name = field.name.label
      (
        name,
        e_match(e_call_method(e_id("obj"), "get", [e_string(name)]), [
          p_case(
            p_constr("Some", args=[p_var("value")]),
            e_from_json_call(e_id("value"), name),
          ),
          p_case(
            p_constr("None"),
            e_raise_decode_error("Missing field \{name}"),
          ),
        ]),
      )
    })
    .to_array()
  let object_case = p_case(
    p_constr("Object", args=[p_var("obj")]),
    fold_lets(bindings, e_record(field_names(fields))),
  )
  let error_case = p_case(
    p_any(),
    e_raise_decode_error("\{decl.tycon}::from_json: expected object"),
  )
  top_impl(
    decl,
    "from_json",
    params,
    e_match(e_id("json"), [object_case, error_case]),
    private~,
  )
}

///|
fn e_decode_key_case(name : String) -> @syntax.Case {
  e_decode_key_case_at(name, name, e_id("path"))
}

///|
fn e_decode_key_case_at(
  key_name : String,
  target_name : String,
  base_path : @syntax.Expr,
) -> @syntax.Case {
  p_case(
    p_constr("Some", args=[p_string(key_name)]),
    e_seq(
      [
        e_assign(
          target_name,
          e_option_some(e_decode_json_at_path(e_path_key(base_path, key_name))),
        ),
      ],
      e_continue(),
    ),
  )
}

///|
fn e_bind_required_field(name : String, body : @syntax.Expr) -> @syntax.Expr {
  e_bind_required_field_at(name, name, e_id("path"), body)
}

///|
fn e_bind_required_field_at(
  var_name : String,
  field_name : String,
  path_expr : @syntax.Expr,
  body : @syntax.Expr,
) -> @syntax.Expr {
  e_let(
    p_var(var_name),
    e_match(e_id(var_name), [
      p_case(p_constr("Some", args=[p_var("value")]), e_id("value")),
      p_case(
        p_constr("None"),
        e_raise_decode_error_at(path_expr, "Missing field \{field_name}"),
      ),
    ]),
    body,
  )
}

///|
fn derive_decode_json_impl(
  decl : @syntax.TypeDecl,
  fields : List[@syntax.FieldDecl],
  private~ : Bool,
) -> @syntax.Impl raise {
  let params = type_param_names(decl.params)
  let names = field_names(fields)
  let cases = [p_case(p_constr("None"), e_break())]
  for name in names {
    cases.push(e_decode_key_case(name))
  }
  cases.push(p_case(p_constr("Some", args=[p_any()]), e_skip_unknown()))
  let loop_expr = e_while_true(e_match(e_next_key(), cases))
  let mut body = e_record(names)
  for i = names.length() - 1; i >= 0; i = i - 1 {
    body = e_bind_required_field(names[i], body)
  }
  body = e_seq([e_begin_object(), loop_expr], body)
  for i = names.length() - 1; i >= 0; i = i - 1 {
    body = e_let_mut(names[i], e_constr("None"), body)
  }
  top_impl(decl, "decode_json", params, body, private~)
}

///|
fn index_names(prefix : String, count : Int) -> Array[String] {
  let names = []
  for i in 0..<count {
    names.push("\{prefix}\{i}")
  }
  names
}

///|
fn e_construct_positional(
  name : String,
  arg_names : Array[String],
) -> @syntax.Expr {
  if arg_names.is_empty() {
    e_constr(name)
  } else {
    e_apply(e_constr(name), arg_names.map(name => e_id(name)))
  }
}

///|
priv struct CtorLayout {
  name : String
  labels : Array[String?]
}

///|
fn layout_from_constr(constr : @syntax.ConstrDecl) -> CtorLayout {
  let params = constr_params(constr)
  {
    name: constr.name.name,
    labels: params.map(param => {
      match param.label {
        None => None
        Some(label) => Some(label.name)
      }
    }),
  }
}

///|
fn positional_count(layout : CtorLayout) -> Int {
  let mut count = 0
  for label in layout.labels {
    if label is None {
      count += 1
    }
  }
  count
}

///|
fn has_named_params(layout : CtorLayout) -> Bool {
  for label in layout.labels {
    if label is Some(_) {
      return true
    }
  }
  false
}

///|
fn named_object_index(layout : CtorLayout) -> Int {
  1 + positional_count(layout)
}

///|
fn e_construct_layout(
  layout : CtorLayout,
  arg_names : Array[String],
) -> @syntax.Expr {
  if arg_names.is_empty() {
    e_constr(layout.name)
  } else {
    e_apply_with_kinds(
      e_constr(layout.name),
      arg_names.mapi((i, name) => {
        let kind = match layout.labels[i] {
          None => @syntax.ArgumentKind::Positional
          Some(label_name) => @syntax.ArgumentKind::Labelled(label(label_name))
        }
        (e_id(name), kind)
      }),
    )
  }
}

///|
fn layout_json_pattern(layout : CtorLayout) -> @syntax.Pattern {
  if layout.labels.is_empty() {
    p_string(layout.name)
  } else {
    let patterns = [p_string(layout.name)]
    for i in 0..<layout.labels.length() {
      match layout.labels[i] {
        None => patterns.push(p_var("json\{i}"))
        Some(_) => ()
      }
    }
    if has_named_params(layout) {
      patterns.push(p_var("named_json"))
    }
    p_array(patterns)
  }
}

///|
fn fold_layout_positional_from_json_bindings(
  layout : CtorLayout,
  arg_names : Array[String],
  last : @syntax.Expr,
) -> @syntax.Expr {
  let bindings = []
  let mut json_index = 1
  for i in 0..<layout.labels.length() {
    match layout.labels[i] {
      None => {
        bindings.push(
          (
            arg_names[i],
            e_from_json_at_path(e_id("json\{i}"), e_path_index(json_index)),
          ),
        )
        json_index += 1
      }
      Some(_) => ()
    }
  }
  fold_lets(bindings, last)
}

///|
fn e_named_object_from_json(
  layout : CtorLayout,
  arg_names : Array[String],
  body : @syntax.Expr,
) -> @syntax.Expr {
  if !has_named_params(layout) {
    body
  } else {
    let path_expr = e_path_index(named_object_index(layout))
    let bindings = []
    for i in 0..<layout.labels.length() {
      match layout.labels[i] {
        None => ()
        Some(field_name) =>
          bindings.push(
            (
              arg_names[i],
              e_match(
                e_call_method(e_id("named_obj"), "get", [e_string(field_name)]),
                [
                  p_case(
                    p_constr("Some", args=[p_var("value")]),
                    e_from_json_at_path(
                      e_id("value"),
                      e_path_key(path_expr, field_name),
                    ),
                  ),
                  p_case(
                    p_constr("None"),
                    e_raise_decode_error_at(
                      e_path_key(path_expr, field_name),
                      "Missing field \{field_name}",
                    ),
                  ),
                ],
              ),
            ),
          )
      }
    }
    e_match(e_id("named_json"), [
      p_case(
        p_constr("Object", args=[p_var("named_obj")]),
        fold_lets(bindings, body),
      ),
      p_case(
        p_any(),
        e_raise_decode_error_at(
          path_expr,
          "\{layout.name}::from_json: expected named payload object",
        ),
      ),
    ])
  }
}

///|
fn fold_decode_bindings(
  json_names : Array[String],
  arg_names : Array[String],
  start_index : Int,
  last : @syntax.Expr,
) -> @syntax.Expr {
  let bindings = []
  for i in 0..<json_names.length() {
    bindings.push(
      (
        arg_names[i],
        e_from_json_index_call(e_id(json_names[i]), start_index + i),
      ),
    )
  }
  fold_lets(bindings, last)
}

///|
fn e_stream_payload_body(
  arg_names : Array[String],
  start_index : Int,
  result_expr : @syntax.Expr,
  missing_prefix : String,
  too_many_message : String,
) -> @syntax.Expr {
  let mut body = e_if(
    e_next_array_value(),
    e_raise_decode_error(too_many_message),
    result_expr,
  )
  for i = arg_names.length() - 1; i >= 0; i = i - 1 {
    let index = start_index + i
    body = e_let(
      p_var(arg_names[i]),
      e_if(
        e_next_array_value(),
        e_decode_json_index_call(index),
        e_raise_decode_error("\{missing_prefix} \{i}"),
      ),
      body,
    )
  }
  body
}

///|
fn e_decode_named_payload_object(
  layout : CtorLayout,
  arg_names : Array[String],
  named_path : @syntax.Expr,
  body : @syntax.Expr,
) -> @syntax.Expr {
  let cases = [p_case(p_constr("None"), e_break())]
  for i in 0..<layout.labels.length() {
    match layout.labels[i] {
      None => ()
      Some(field_name) =>
        cases.push(e_decode_key_case_at(field_name, arg_names[i], named_path))
    }
  }
  cases.push(
    p_case(p_constr("Some", args=[p_any()]), e_skip_unknown_at(named_path)),
  )
  let loop_expr = e_while_true(e_match(e_next_key_at(named_path), cases))
  let mut result = body
  for i = layout.labels.length() - 1; i >= 0; i = i - 1 {
    match layout.labels[i] {
      None => ()
      Some(field_name) =>
        result = e_bind_required_field_at(
          arg_names[i],
          field_name,
          e_path_key(named_path, field_name),
          result,
        )
    }
  }
  result = e_seq([e_begin_object_at(named_path), loop_expr], result)
  for i = layout.labels.length() - 1; i >= 0; i = i - 1 {
    match layout.labels[i] {
      None => ()
      Some(_) => result = e_let_mut(arg_names[i], e_constr("None"), result)
    }
  }
  result
}

///|
fn e_stream_layout_payload_body(
  layout : CtorLayout,
  arg_names : Array[String],
  result_expr : @syntax.Expr,
  missing_prefix : String,
  too_many_message : String,
) -> @syntax.Expr {
  let mut body = e_if(
    e_next_array_value(),
    e_raise_decode_error(too_many_message),
    result_expr,
  )
  if has_named_params(layout) {
    let named_path = e_path_index(named_object_index(layout))
    body = e_if(
      e_next_array_value(),
      e_decode_named_payload_object(layout, arg_names, named_path, body),
      e_raise_decode_error("\{missing_prefix} named payload"),
    )
  }
  let mut positional_json_index = positional_count(layout)
  for i = layout.labels.length() - 1; i >= 0; i = i - 1 {
    match layout.labels[i] {
      None => {
        let json_index = positional_json_index
        body = e_let(
          p_var(arg_names[i]),
          e_if(
            e_next_array_value(),
            e_decode_json_index_call(json_index),
            e_raise_decode_error("\{missing_prefix} \{i}"),
          ),
          body,
        )
        positional_json_index -= 1
      }
      Some(_) => ()
    }
  }
  body
}

///|
fn derive_tuple_from_json_impl(
  decl : @syntax.TypeDecl,
  tys : List[@syntax.Type],
  private~ : Bool,
) -> @syntax.Impl raise {
  let params = type_param_names(decl.params)
  let count = tys.length()
  let json_names = index_names("json", count)
  let arg_names = index_names("arg", count)
  let patterns = [p_string(decl.tycon)]
  for name in json_names {
    patterns.push(p_var(name))
  }
  let tuple_case = p_case(
    p_array(patterns),
    fold_decode_bindings(
      json_names,
      arg_names,
      1,
      e_construct_positional(decl.tycon, arg_names),
    ),
  )
  let error_case = p_case(
    p_any(),
    e_raise_decode_error(
      "\{decl.tycon}::from_json: expected tuple struct array",
    ),
  )
  top_impl(
    decl,
    "from_json",
    params,
    e_match(e_id("json"), [tuple_case, error_case]),
    private~,
  )
}

///|
fn derive_tuple_decode_json_impl(
  decl : @syntax.TypeDecl,
  tys : List[@syntax.Type],
  private~ : Bool,
) -> @syntax.Impl raise {
  let params = type_param_names(decl.params)
  let arg_names = index_names("arg", tys.length())
  let payload_case = p_case(
    p_constr("Payload", args=[p_string(decl.tycon)], pkg=RUNTIME),
    e_stream_payload_body(
      arg_names,
      1,
      e_construct_positional(decl.tycon, arg_names),
      "\{decl.tycon}::decode_json: missing field",
      "\{decl.tycon}::decode_json: too many fields",
    ),
  )
  let error_case = p_case(
    p_any(),
    e_raise_decode_error(
      "\{decl.tycon}::decode_json: expected tuple struct array",
    ),
  )
  top_impl(
    decl,
    "decode_json",
    params,
    e_match(e_read_variant_tag(), [payload_case, error_case]),
    private~,
  )
}

///|
fn constr_params(constr : @syntax.ConstrDecl) -> Array[@syntax.ConstrParam] {
  match constr.args {
    None => []
    Some(args) => args.to_array()
  }
}

///|
fn layouts_from_constrs(
  constrs : List[@syntax.ConstrDecl],
) -> Array[CtorLayout] {
  constrs.map(layout_from_constr).to_array()
}

///|
fn layouts_from_error(
  name : String,
  decl : @syntax.ExceptionDecl,
) -> Array[CtorLayout] {
  match decl {
    NoPayload => [{ name, labels: [] }]
    SinglePayload(_) => [{ name, labels: [None] }]
    EnumPayload(constrs) => layouts_from_constrs(constrs)
  }
}

///|
fn derive_sum_from_json_impl(
  decl : @syntax.TypeDecl,
  layouts : Array[CtorLayout],
  private~ : Bool,
) -> @syntax.Impl raise {
  let params = type_param_names(decl.params)
  let cases = []
  for layout in layouts {
    if layout.labels.is_empty() {
      cases.push(p_case(p_string(layout.name), e_constr(layout.name)))
    } else {
      let arg_names = index_names("arg", layout.labels.length())
      cases.push(
        p_case(
          layout_json_pattern(layout),
          fold_layout_positional_from_json_bindings(
            layout,
            arg_names,
            e_named_object_from_json(
              layout,
              arg_names,
              e_construct_layout(layout, arg_names),
            ),
          ),
        ),
      )
    }
  }
  cases.push(
    p_case(
      p_any(),
      e_raise_decode_error("\{decl.tycon}::from_json: expected enum value"),
    ),
  )
  top_impl(decl, "from_json", params, e_match(e_id("json"), cases), private~)
}

///|
fn derive_sum_decode_json_impl(
  decl : @syntax.TypeDecl,
  layouts : Array[CtorLayout],
  private~ : Bool,
) -> @syntax.Impl raise {
  let params = type_param_names(decl.params)
  let cases = []
  for layout in layouts {
    if layout.labels.is_empty() {
      cases.push(
        p_case(
          p_constr("Plain", args=[p_string(layout.name)], pkg=RUNTIME),
          e_constr(layout.name),
        ),
      )
    } else {
      let arg_names = index_names("arg", layout.labels.length())
      cases.push(
        p_case(
          p_constr("Payload", args=[p_string(layout.name)], pkg=RUNTIME),
          e_stream_layout_payload_body(
            layout,
            arg_names,
            e_construct_layout(layout, arg_names),
            "\{decl.tycon}::decode_json: missing constructor field",
            "\{decl.tycon}::decode_json: too many constructor fields",
          ),
        ),
      )
    }
  }
  cases.push(
    p_case(
      p_any(),
      e_raise_decode_error("\{decl.tycon}::decode_json: expected enum value"),
    ),
  )
  top_impl(
    decl,
    "decode_json",
    params,
    e_match(e_read_variant_tag(), cases),
    private~,
  )
}

///|
fn derive_decl(
  decl : @syntax.TypeDecl,
  private~ : Bool,
) -> Array[@syntax.Impl] raise {
  match decl.components {
    Record(fields~, ..) =>
      [
        derive_from_json_impl(decl, fields, private~),
        derive_decode_json_impl(decl, fields, private~),
      ]
    TupleStruct(tys) =>
      [
        derive_tuple_from_json_impl(decl, tys, private~),
        derive_tuple_decode_json_impl(decl, tys, private~),
      ]
    Alias(_) => fail("from_json_str derive does not support type aliases")
    Error(error_decl) =>
      [
        derive_sum_from_json_impl(
          decl,
          layouts_from_error(decl.tycon, error_decl),
          private~,
        ),
        derive_sum_decode_json_impl(
          decl,
          layouts_from_error(decl.tycon, error_decl),
          private~,
        ),
      ]
    Extern => fail("from_json_str derive does not support extern types")
    Abstract => fail("from_json_str derive does not support abstract types")
    Variant(constrs) =>
      [
        derive_sum_from_json_impl(decl, layouts_from_constrs(constrs), private~),
        derive_sum_decode_json_impl(
          decl,
          layouts_from_constrs(constrs),
          private~,
        ),
      ]
  }
}

///|
pub fn derive_from_json_str(impls : @syntax.Impls) -> @syntax.Impls raise {
  let generated = []
  for impl_ in impls {
    match impl_ {
      TopTypeDef(decl) =>
        match is_from_json_str_derive(decl.attrs) {
          Some(private) => generated.append(derive_decl(decl, private~))
          None => ()
        }
      _ => ()
    }
  }
  List::from_array(generated)
}
