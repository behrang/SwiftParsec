import SwiftParsec

typealias scv = String.CharacterView

enum Json {
  case null
  case bool(Bool)
  case int(Int)
  case double(Double)
  case string(String)
  case array([Json])
  case dictionary([String: Json])

  func getString () -> String {
    switch self {
    case let .string(s): return s
    default: return ""
    }
  }
}

func json () -> Parser<Json,scv>.T {
  return null()
    <|> bool()
    <|> int()
    <|> double()
    <|> quotedString()
    // <|> array()
    <|> dictionary()
    <?> "json"
}

func null () -> Parser<Json, scv>.T {
  return attempt(string("null") >>| create(.null)) <?> "null"
}

func bool () -> Parser<Json, scv>.T {
  return attempt(string("true") >>| create(.bool(true)))
    <|> attempt(string("false") >>| create(.bool(false)))
    <?> "boolean"
}

func int () -> Parser<Json, scv>.T {
  return attempt(many1(digit()) >>- { a in
    notFollowedBy(char(".")) >>- { _ in
      let intString = String(a)
      if let i = Int(intString + "") {
        return create(.int(i))
      } else {
        return fail("invalid integer \(intString)")
      }
    }
  }) <?> "int"
}

func double () -> Parser<Json, scv>.T {
  return many1(digit()) >>- { a in
    char(".") >>| many(digit()) >>- { b in
      let doubleString = String(a) + "." + String(b)
      if let d = Double(doubleString) {
        return create(.double(d))
      } else {
        return fail("invalid double \(doubleString)")
      }
    }
  }
}

func quotedString () -> Parser<Json, scv>.T {
  return attempt(
    char("\"") >>|
    many(noneOf(["\""])) >>- { ss in
      char("\"") >>| create(.string(String(ss)))
    }
  )
}

func array () -> Parser<Json, scv>.T {
  return attempt(
    char("[") >>|
    sepBy(json(), char(",")) >>- { items in
      char("]") >>| create(.array(items))
    }
  )
}

func dictionary () -> Parser<Json, scv>.T {
  return attempt(
    char("{") >>|
    sepBy(dictionaryItem(), char(",")) >>- { items in
      let r: [String: Json] = items.reduce([:], combine: { acc, item in var r = acc; r[item.0] = item.1; return r})
      return char("}") >>| create(.dictionary(r))
    }
  )
}

func dictionaryItem () -> Parser<(String, Json), scv>.T {
  return quotedString() >>- { k in
    char(":") >>|
    json() >>- { v in
      create((k.getString(), v))
    }
  }
}
