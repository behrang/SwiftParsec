import SwiftParsec

enum Json {
  case null
  case bool(Bool)
  case number(Double)
  case string(String)
  case array([Json])
  case object([String: Json])
}

func jsonFile () -> Parser<Json, String.CharacterView>.T {
  return spaces() >>> value() <<< eof()
}

func value () -> Parser<Json, String.CharacterView>.T {
  return str()
      <|> number()
      <|> object()
      <|> array()
      <|> bool()
      <|> null()
      <?> "json value"
}

func str () -> Parser<Json, String.CharacterView>.T {
  return quotedString() >>- { s in create(.string(s)) }
}

func quotedString () -> Parser<String, String.CharacterView>.T {
  return between(quote(), quote(), many(quotedCharacter()))
        >>- { cs in create(String(cs)) } <<< spaces() <?> "quoted string"
}

func quotedCharacter () -> Parser<Character, String.CharacterView>.T {
  var chars: [Character] = ["\"", "\\"]
  for i in 0x00...0x1f {
    chars.append(Character(UnicodeScalar(i)))
  }
  for i in 0x7f...0x9f {
    chars.append(Character(UnicodeScalar(i)))
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
            return create(Character(UnicodeScalar(i)))
          })
}

func number () -> Parser<Json, String.CharacterView>.T {
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

func numberSign () -> Parser<String, String.CharacterView>.T {
  return option("+", string("-"))
}

func numberFixed () -> Parser<String, String.CharacterView>.T {
  return string("0") <|> many1(digit()) >>- { create(String($0)) }
}

func numberFraction () -> Parser<String, String.CharacterView>.T {
  return char(".") >>> many1(digit()) >>- { create("." + String($0)) }
    <|> create("")
}

func numberExponent () -> Parser<String, String.CharacterView>.T {
  return oneOf("eE") >>> option("+", oneOf("+-")) >>- { sign in
      many1(digit()) >>- { digits in create("e" + String(sign) + String(digits)) }
    }
    <|> create("")
}

func object () -> Parser<Json, String.CharacterView>.T {
  return between(leftBrace(), rightBrace(), sepBy(pair(), comma())) >>- { ps in
    var r: [String: Json] = [:]
    ps.forEach { p in r[p.0] = p.1 }
    return create(.object(r))
  } <?> "object"
}

func pair () -> Parser<(String, Json), String.CharacterView>.T {
  return quotedString() >>- { k in
    colon() >>> value() >>- { v in
      create((k, v))
    }
  } <?> "key:value pair"
}

func array () -> Parser<Json, String.CharacterView>.T {
  // the next line crashes the compiler with "Segmentation fault: 11"
  // return between(leftBracket(), rightBracket(), sepBy(value(), comma()))
  //     >>- { js in create(.array(js)) }
  // as a result, we can't have an array within an array
  func element () -> Parser<Json, String.CharacterView>.T {
    return null() <|> bool() <|> number() <|> str() <|> object()
  }
  return between(leftBracket(), rightBracket(), sepBy(element(), comma()))
      >>- { js in create(.array(js)) }
      <?> "array"
}

func bool () -> Parser<Json, String.CharacterView>.T {
  return (string("true") >>> create(.bool(true)) <<< spaces() <?> "true")
      <|> (string("false") >>> create(.bool(false)) <<< spaces() <?> "false")
}

func null () -> Parser<Json, String.CharacterView>.T {
  return string("null") >>> create(.null) <<< spaces() <?> "null"
}

func leftBracket () -> Parser<Character, String.CharacterView>.T {
  return char("[") <<< spaces() <?> "open square bracket"
}

func rightBracket () -> Parser<Character, String.CharacterView>.T {
  return char("]") <<< spaces() <?> "close square bracket"
}

func leftBrace () -> Parser<Character, String.CharacterView>.T {
  return char("{") <<< spaces() <?> "open curly bracket"
}

func rightBrace () -> Parser<Character, String.CharacterView>.T {
  return char("}") <<< spaces() <?> "close curly bracket"
}

func comma () -> Parser<Character, String.CharacterView>.T {
  return char(",") <<< spaces() <?> "comma"
}

func colon () -> Parser<Character, String.CharacterView>.T {
  return char(":") <<< spaces() <?> "colon"
}

func quote () -> Parser<Character, String.CharacterView>.T {
  return char("\"") <?> "double quote"
}

func main () {
  if Process.arguments.count != 2 {
    print("Usage: \(Process.arguments[0]) json_file")
  } else {
    let result = try! parse(jsonFile(), contentsOfFile: Process.arguments[1])
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
