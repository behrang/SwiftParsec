public func many<a, c: Collection> (_ p: Parser<a, c>.T) -> Parser<[a], c>.T {
  return p >>- { x in
    return many(p) >>- { xs in
      var r = xs
      r.insert(x, at: 0)
      return create(r)
    }
  } <|> create([])
}

public func eof<c: Collection where c.SubSequence == c> () -> Parser<(), c>.T {
  return notFollowedBy(anyToken()) <?> "end of input"
}

public func anyToken<a, c: Collection where c.SubSequence == c, a == c.Iterator.Element> () -> Parser<a, c>.T {
  return satisfy { _ in true }
}

infix operator >>| { associativity left precedence 110 }
public func >>| <a, b, c: Collection> (p: Parser<a, c>.T, q: Parser<b, c>.T) -> Parser<b, c>.T {
  return p >>- { _ in q }
}

public func noneOf<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> (_ list: [Character]) -> Parser<Character, c>.T {
  return satisfy({ n in !list.contains { n == $0 } })
}

public func sepBy<a, b, c:Collection> (_ p: Parser<a, c>.T, _ q: Parser<b, c>.T) -> Parser<[a], c>.T {
  return p >>- { x in
    ( (q >>| sepBy(p, q) ) <|> create([]) ) >>- { xs in
      var r = [x]
      r.append(contentsOf: xs)
      return create(r)
    }
  }
}

public func endBy<a, b, c: Collection> (_ p: Parser<a, c>.T, _ q: Parser<b, c>.T) -> Parser<[a], c>.T {
  return p >>- { x in
    q >>- { _ in
      endBy(p, q) <|> create([]) >>- { xs in
        var r = [x]
        r.append(contentsOf: xs)
        return create(r)
      }
    }
  }
}

public func option<a, c: Collection> (_ o: a, _ p: Parser<a, c>.T) -> Parser<a, c>.T {
  return p <|> create(o)
}

public func optionMaybe<a, c: Collection> (_ p: Parser<a, c>.T) -> Parser<a?, c>.T {
  return p >>- { x in create(x) } <|> create(nil)
}

public func notFollowedBy<a, c: Collection> (_ p: Parser<a, c>.T) -> Parser<(), c>.T {
  return attempt(attempt(p) >>- { n in unexpected(String(n)) } <|> create(()))
}

public func unexpected<a, c: Collection> (_ msg: String) -> Parser<a, c>.T {
  return { state in
    .Empty(.Error(ParseError(state.pos, [.UnExpect(msg)])))
  }
}

public func fail<a, c: Collection> (_ msg: String) -> Parser<a, c>.T {
  return { state in
    .Empty(.Error(ParseError(state.pos, [.Message(msg)])))
  }
}
