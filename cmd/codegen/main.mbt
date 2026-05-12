///|
fn eprintln(msg : String) -> Unit {
  let data = @encoding/utf8.encode(msg + "\n")
  let mut written = 0
  while written < data.length() {
    let n = @wasi.stderr.fd_write([data[written:]]) catch { _ => return }
    written += n.0.reinterpret_as_int()
  }
}

///|
fn print_stdout(msg : String) -> Unit {
  let data = @encoding/utf8.encode(msg + "\n")
  let mut written = 0
  while written < data.length() {
    let n = @wasi.stdout.fd_write([data[written:]]) catch { _ => return }
    written += n.0.reinterpret_as_int()
  }
}

///|
fn[T] exit(code : Int) -> T {
  @wasi.proc_exit(code.reinterpret_as_uint())
  panic()
}

///|
fn read_input() -> String raise {
  let fd = @wasi.stdin
  let buffer = @buffer.new(size_hint=1024)
  let buf = FixedArray::make(1024, b'\x00')
  while true {
    let n = fd.fd_read([buf]) catch { e => raise e }
    let read = n.0.to_uint64()
    if read == 0 {
      break
    }
    buffer.write_bytesview(buf.unsafe_reinterpret_as_bytes()[:read.to_int()])
  }
  @encoding/utf8.decode(buffer.to_bytes()) catch {
    e => raise e
  }
}

///|
fn main {
  try {
    let source = read_input() catch { e => raise e }
    let (ast, report) = @parser.parse_string(source)
    guard report is [] else {
      fail("Parse error: \{report.to_json().stringify(indent=2)}")
    }
    let generated = @from_json_str_codegen.derive_from_json_str(ast)
    let result = @formatter.impls_to_string(generated)
    print_stdout(result)
  } catch {
    e => {
      eprintln(e.to_string())
      exit(1)
    }
  }
}
