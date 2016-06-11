import SwiftParsec

typealias scv = String.CharacterView

enum Json {
  case Null
  case Bool(Swift.Bool)
  case Int(Swift.Int)
  case Double(Swift.Double)
  case String(Swift.String)
  case Array([Json])
  case Dictionary([Swift.String: Json])

  func getString () -> Swift.String {
    switch self {
    case let .String(s): return s
    default: return ""
    }
  }
}

func json () -> (State<scv>) -> Consumed<Json,scv> {
  return null()
    <|> bool()
    <|> int()
    <|> double()
    <|> quotedString()
    // <|> array()
    <|> dictionary()
    <?> "json"
}

func null () -> (State<scv>) -> Consumed<Json, scv> {
  return attempt(string("null".characters) >>| create(.Null)) <?> "null"
}

func bool () -> (State<scv>) -> Consumed<Json, scv> {
  return attempt(string("true".characters) >>| create(.Bool(true)))
    <|> attempt(string("false".characters) >>| create(.Bool(false)))
    <?> "boolean"
}

func int () -> (State<scv>) -> Consumed<Json, scv> {
  return attempt(many1(digit()) >>- { a in
    notFollowedBy(character(".")) >>- { _ in
      let intString = String(a)
      if let i = Int(intString + "") {
        return create(.Int(i))
      } else {
        return fail("invalid integer \(intString)")
      }
    }
  }) <?> "int"
}

func double () -> (State<scv>) -> Consumed<Json, scv> {
  return many1(digit()) >>- { a in
    character(".") >>| many(digit()) >>- { b in
      let doubleString = String(a) + "." + String(b)
      if let d = Double(doubleString) {
        return create(.Double(d))
      } else {
        return fail("invalid double \(doubleString)")
      }
    }
  }
}

func quotedString () -> (State<scv>) -> Consumed<Json, scv> {
  return attempt(
    character("\"") >>|
    many(noneOf(["\""])) >>- { ss in
      character("\"") >>| create(.String(String(ss)))
    }
  )
}

func array () -> (State<scv>) -> Consumed<Json, scv> {
  return attempt(
    character("[") >>|
    sepBy(json(), character(",")) >>- { items in
      character("]") >>| create(.Array(items))
    }
  )
}

func dictionary () -> (State<scv>) -> Consumed<Json, scv> {
  return attempt(
    character("{") >>|
    sepBy(dictionaryItem(), character(",")) >>- { items in
      let r: [String: Json] = items.reduce([:], combine: { acc, item in var r = acc; r[item.0] = item.1; return r})
      return character("}") >>| create(.Dictionary(r))
    }
  )
}

func dictionaryItem () -> (State<scv>) -> Consumed<(String, Json), scv> {
  return quotedString() >>- { k in
    character(":") >>|
    json() >>- { v in
      create((k.getString(), v))
    }
  }
}
