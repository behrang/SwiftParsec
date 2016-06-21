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
  return attempt(string("null".characters) >>| create(.null)) <?> "null"
}

func bool () -> Parser<Json, scv>.T {
  return attempt(string("true".characters) >>| create(.bool(true)))
    <|> attempt(string("false".characters) >>| create(.bool(false)))
    <?> "boolean"
}

func int () -> Parser<Json, scv>.T {
  return attempt(many1(digit()) >>- { a in
    notFollowedBy(character(".")) >>- { _ in
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
    character(".") >>| many(digit()) >>- { b in
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
    character("\"") >>|
    many(noneOf(["\""])) >>- { ss in
      character("\"") >>| create(.string(String(ss)))
    }
  )
}

func array () -> Parser<Json, scv>.T {
  return attempt(
    character("[") >>|
    sepBy(json(), character(",")) >>- { items in
      character("]") >>| create(.array(items))
    }
  )
}

func dictionary () -> Parser<Json, scv>.T {
  return attempt(
    character("{") >>|
    sepBy(dictionaryItem(), character(",")) >>- { items in
      let r: [String: Json] = items.reduce([:], combine: { acc, item in var r = acc; r[item.0] = item.1; return r})
      return character("}") >>| create(.dictionary(r))
    }
  )
}

func dictionaryItem () -> Parser<(String, Json), scv>.T {
  return quotedString() >>- { k in
    character(":") >>|
    json() >>- { v in
      create((k.getString(), v))
    }
  }
}
