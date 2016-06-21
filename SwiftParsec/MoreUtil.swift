public func eof<c: Collection where c.SubSequence == c> () -> Parser<(), c>.T {
  return notFollowedBy(anyToken()) <?> "end of input"
}

public func anyToken<a, c: Collection where c.SubSequence == c, a == c.Iterator.Element> () -> Parser<a, c>.T {
  return satisfy { _ in true }
}

infix operator >>| { associativity left precedence 107 }
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
      ( endBy(p, q) <|> create([]) ) >>- { xs in
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
