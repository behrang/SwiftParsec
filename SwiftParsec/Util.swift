public func character<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> (_ x: c.Iterator.Element) -> Parser<c.Iterator.Element, c>.T {
  return satisfy({ n in n == x }) <?> String(x)
}

public func letter<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> () -> Parser<c.Iterator.Element, c>.T {
  return satisfy({ n in ("a"..."z" ~= n) || ("A"..."Z" ~= n) }) <?> "letter"
}

public func digit<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> () -> Parser<c.Iterator.Element, c>.T {
  return satisfy({ n in "0"..."9" ~= n }) <?> "digit"
}

public func hexDigit<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> () -> Parser<c.Iterator.Element, c>.T {
  return satisfy({ n in ("0"..."9" ~= n) || ("a"..."f" ~= n) || ("A"..."F") ~= n})
}

public func newline<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> () -> Parser<c.Iterator.Element, c>.T {
  return satisfy({ n in n == "\n" }) <?> "newline"
}

public func string<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> (_ x: c) -> Parser<String, c>.T {
  if let head = x.first {
    let tail = x.dropFirst()
    return character(head) >>- { ch in
      string(tail) >>- { chs in
        var r = chs
        r.insert(ch, at: r.startIndex)
        return create(String(r))
      }
    }
  } else {
    return create("")
  }
}

public func many1<a, c: Collection> (_ p: Parser<a, c>.T) -> Parser<[a], c>.T {
  return p >>- { x in
    (many1(p) <|> create([])) >>- { xs in
      var r = [x]
      r.append(contentsOf: xs)
      return create(r)
    }
  }
}

public func identifier<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> () -> Parser<[c.Iterator.Element], c>.T {
  return many1(letter() <|> digit() <|> character("_")) <?> "identifier"
}
