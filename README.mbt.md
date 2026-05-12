# moonbit-community/from_json_str

Prototype of a JSON-specific streaming decode path for MoonBit.

The package defines a local `FromJson` trait with two paths:

- `from_json(Json, JsonPath)` for compatibility with an already-built `Json`
  value.
- `decode_json(Decoder, JsonPath)` for direct decoding from a JSON string.

The `codegen` package is a metaprogramming prototype. It recognizes
`#json.from_json_str` on record structs, tuple structs, and enums, then
generates both `from_json` and streaming `decode_json` impls by constructing
`moonbitlang/parser/syntax` AST nodes directly. `cmd/example` wires this
generator through a Wasmer pre-build step.

The generated output for the example lives in
[`cmd/example/output.mbt`](cmd/example/output.mbt). It shows the exact
`FromJson` impls emitted for a record struct, tuple struct, and enum.

## Decoder API used by generated code

The derivation only needs a JSON-specific decoder API, not a serde-style generic
visitor system. The required public surface is:

```moonbit nocheck
pub fn Decoder::new(StringView, max_nesting_depth? : Int) -> Decoder
pub fn Decoder::finish(Self, path? : JsonPath) -> Unit raise JsonDecodeError

pub fn Decoder::read_string(Self, JsonPath) -> String raise JsonDecodeError
pub fn Decoder::read_int(Self, JsonPath) -> Int raise JsonDecodeError
pub fn Decoder::read_double(Self, JsonPath) -> Double raise JsonDecodeError
pub fn Decoder::read_bool(Self, JsonPath) -> Bool raise JsonDecodeError
pub fn Decoder::read_null(Self, JsonPath) -> Unit raise JsonDecodeError
pub fn Decoder::read_json(Self, JsonPath) -> Json raise JsonDecodeError
pub fn Decoder::read_variant_tag(Self, JsonPath) -> VariantTag raise JsonDecodeError

pub fn Decoder::begin_object(Self, JsonPath) -> Unit raise JsonDecodeError
pub fn Decoder::next_object_key(Self, JsonPath) -> String? raise JsonDecodeError
pub fn Decoder::begin_array(Self, JsonPath) -> Unit raise JsonDecodeError
pub fn Decoder::next_array_value(Self, JsonPath) -> Bool raise JsonDecodeError
pub fn Decoder::skip_value(Self, JsonPath) -> Unit raise JsonDecodeError
```

`read_json` is mainly the compatibility fallback: the default streaming method
can build an intermediate `Json` and call the existing `from_json` method.
Derived implementations should normally use the typed readers and container
iteration APIs directly.

This workspace also includes a local checkout of `moonbitlang/formatter` so the
prototype can use the formatter fix for `let mut` expressions emitted from AST.

Run the checks with:

```bash
moon build cmd/codegen --target wasm
moon test . codegen cmd/example
(cd formatter && moon test internal/testsuite/style_test --filter let_mut)
moon run cmd/main
```

This standalone package cannot extend `moonbitlang/core/json.FromJson` or the
compiler deriver directly, so it uses local `JsonPath` and `JsonDecodeError`
types to demonstrate the design.
