# username/from_json_str

Prototype of a JSON-specific streaming decode path for MoonBit.

The package defines a local `FromJson` trait with two paths:

- `from_json(Json, JsonPath)` for compatibility with an already-built `Json`
  value.
- `decode_json(Decoder, JsonPath)` for direct decoding from a JSON string.

`Decoder` exposes the operations derived or handwritten decoders need:
`read_string`, `read_int`, `read_bool`, `begin_object`, `next_object_key`,
`begin_array`, `next_array_value`, `skip_value`, `read_json`, and `finish`.

The `codegen` package is a metaprogramming prototype. It recognizes
`#json.from_json_str` on record structs, tuple structs, and enums, then
generates both `from_json` and streaming `decode_json` impls by constructing
`moonbitlang/parser/syntax` AST nodes directly. `cmd/example` wires this
generator through a Wasmer pre-build step.

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
