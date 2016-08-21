import Parsec

enum Json {
  case null
  case bool(Bool)
  case number(Double)
  case string(String)
  case array([Json])
  case object([String: Json])
}

func jsonFile () -> StringParser<Json> {
  return spaces() >>> value() <<< eof()
}

func value () -> StringParser<Json> {
  return str()
      <|> number()
      <|> object()
      <|> array()
      <|> bool()
      <|> null()
      <?> "json value"
}

func str () -> StringParser<Json> {
  return quotedString() >>- { s in create(.string(s)) }
}

func quotedString () -> StringParser<String> {
  return between(quote(), quote(), many(quotedCharacter()))
        >>- { cs in create(String(cs)) } <<< spaces() <?> "quoted string"
}

func quote () -> StringParser<Character> {
  return char("\"") <?> "double quote"
}

func quotedCharacter () -> StringParser<Character> {
  var chars = "\"\\"
  for i in 0x00...0x1f {
    chars += String(describing: UnicodeScalar(i)!)
  }
  for i in 0x7f...0x9f {
    chars += String(describing: UnicodeScalar(i)!)
  }
  return noneOf(chars)
      <|> attempt(string("\\\"")) >>> create("\"")
      <|> attempt(string("\\\\")) >>> create("\\")
      <|> attempt(string("\\/")) >>> create("/")
      <|> attempt(string("\\b")) >>> create("\u{8}")
      <|> attempt(string("\\f")) >>> create("\u{c}")
      <|> attempt(string("\\n")) >>> create("\n")
      <|> attempt(string("\\r")) >>> create("\r")
      <|> attempt(string("\\t")) >>> create("\t")
      <|> attempt(string("\\u") >>> count(4, hexDigit()) >>- { hds in
            let code = String(hds)
            let i = Int(code, radix: 16)!
            return create(Character(UnicodeScalar(i)!))
          })
}

func number () -> StringParser<Json> {
  return numberSign() >>- { sign in
    numberFixed() >>- { fixed in
      numberFraction() >>- { fraction in
        numberExponent() >>- { exponent in
          let s = sign + fixed + fraction + exponent
          if let d = Double(s) {
            return create(.number(d))
          } else {
            return fail("invalid number \(s)")
          }
        }
      }
    }
  } <<< spaces() <?> "number"
}

func numberSign () -> StringParser<String> {
  return option("+", string("-"))
}

func numberFixed () -> StringParser<String> {
  return string("0") <|> many1(digit()) >>- { create(String($0)) }
}

func numberFraction () -> StringParser<String> {
  return char(".") >>> many1(digit()) >>- { create("." + String($0)) }
    <|> create("")
}

func numberExponent () -> StringParser<String> {
  return oneOf("eE") >>> option("+", oneOf("+-")) >>- { sign in
      many1(digit()) >>- { digits in create("e" + String(sign) + String(digits)) }
    }
    <|> create("")
}

func object () -> StringParser<Json> {
  return between(leftBrace(), rightBrace(), sepBy(pair(), comma())) >>- { ps in
    var r: [String: Json] = [:]
    ps.forEach { p in r[p.0] = p.1 }
    return create(.object(r))
  } <?> "object"
}

func leftBrace () -> StringParser<Character> {
  return char("{") <<< spaces() <?> "open curly bracket"
}

func rightBrace () -> StringParser<Character> {
  return char("}") <<< spaces() <?> "close curly bracket"
}

func comma () -> StringParser<Character> {
  return char(",") <<< spaces() <?> "comma"
}

func colon () -> StringParser<Character> {
  return char(":") <<< spaces() <?> "colon"
}

func pair () -> StringParser<(String, Json)> {
  return quotedString() >>- { k in
    colon() >>> value() >>- { v in
      create((k, v))
    }
  } <?> "key:value pair"
}

func array () -> StringParser<Json> {
  // the next line crashes the compiler with "Segmentation fault: 11"
  // return between(leftBracket(), rightBracket(), sepBy(value(), comma()))
  //     >>- { js in create(.array(js)) }
  // as a result, we can't have an array within an array for now
  func element () -> StringParser<Json> {
    return null() <|> bool() <|> number() <|> str() <|> object()
  }
  return between(leftBracket(), rightBracket(), sepBy(element(), comma()))
      >>- { js in create(.array(js)) }
      <?> "array"
}

func leftBracket () -> StringParser<Character> {
  return char("[") <<< spaces() <?> "open square bracket"
}

func rightBracket () -> StringParser<Character> {
  return char("]") <<< spaces() <?> "close square bracket"
}

func bool () -> StringParser<Json> {
  return (string("true") >>> create(.bool(true)) <<< spaces() <?> "true")
      <|> (string("false") >>> create(.bool(false)) <<< spaces() <?> "false")
}

func null () -> StringParser<Json> {
  return string("null") >>> create(.null) <<< spaces() <?> "null"
}

func main () {
  if CommandLine.arguments.count != 2 {
    print("Usage: \(CommandLine.arguments[0]) json_file")
  } else {
    let result = try! parse(jsonFile(), contentsOfFile: CommandLine.arguments[1])
    switch result {
    case let .left(err): print(err)
    case let .right(x): print(format(x))
    }
  }
}

func format (_ data: Json) -> String {
  switch data {
  case .null: return "null"
  case let .bool(b): return b ? "true" : "false"
  case let .number(n): return String(n)
  case let .string(s): return "\"\(s)\""
  case let .array(a): return "[\(a.map(format).joined(separator: ","))]"
  case let .object(o):
    return "{\(o.map{ k, v in "\"\(k)\":\(format(v))" }.joined(separator: ","))}"
  }
}

main()
