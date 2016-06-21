import SwiftParsec

func query () -> Parser<[String:String?], String.CharacterView>.T {
  return sepBy(pair(), character("&")) >>- { pairs in
    return create(pairs.reduce([:], combine: { acc, p in var r = acc; r[p.0] = p.1; return r }))
  }
}

func pair () -> Parser<(String, String?), String.CharacterView>.T {
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

func pCharacter () -> Parser<Character, String.CharacterView>.T {
  return noneOf(["=", "&"])
}
