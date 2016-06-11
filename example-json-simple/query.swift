import SwiftParsec

func query () -> (State<String.CharacterView>) -> Consumed<[String:String?], String.CharacterView> {
  return sepBy(pair(), character("&")) >>- { pairs in
    return create(pairs.reduce([:], combine: { acc, p in var r = acc; r[p.0] = p.1; return r }))
  }
}

func pair () -> (State<String.CharacterView>) -> Consumed<(String, String?), String.CharacterView> {
  return many1(pCharacter()) >>- { k in
    optionMaybe(character("=") >>| many(pCharacter())) >>- { v in
      var r: String? = nil
      if let v = v {
        r = String(v)
      }
      return create((String(k), r))
    }
  }
}

func pCharacter () -> (State<String.CharacterView>) -> Consumed<Character, String.CharacterView> {
  return noneOf(["=", "&"])
}
