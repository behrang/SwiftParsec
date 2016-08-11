/*
    Commonly used generic combinators.
*/

/**
    `choice(ps)` tries to apply the parsers in the array `ps` in order,
    until one of them succeeds. Returns the value of the succeeding
    parser.
*/
public func choice<a, c: Collection> (_ ps: [Parser<a, c>.T]) -> Parser<a, c>.T {
  return ps.reversed().reduce(parserZero(), parserPlus)
}

/**
    `option(x, p)` tries to apply parser `p`. If `p` fails without
    consuming input, it returns the value `x`, otherwise the value
    returned by `p`.

        func priority () -> StringParser<Int>.T {
          return option(0, digit() >>- { d in
            if let i = Int(String(d)) {
              return create(i)
            } else {
              return fail("this will not happen")
            }
          })
        }
*/
public func option<a, c: Collection> (_ x: a, _ p: Parser<a, c>.T) -> Parser<a, c>.T {
  return p <|> create(x)
}

/**
    `optionMaybe(p)` tries to apply parser `p`.  If `p` fails without
    consuming input, it returns '.none', otherwise it returns
    '.some' the value returned by `p`.
*/
public func optionMaybe<a, c: Collection> (_ p: Parser<a, c>.T) -> Parser<a?, c>.T {
  return p >>- { x in create(x) } <|> create(nil)
}

/**
    `optional(p)` tries to apply parser `p`.  It will parse `p` or nothing.
    It only fails if `p` fails after consuming input. It discards the result
    of `p`.
*/
public func optional<a, c: Collection> (_ p: Parser<a, c>.T) -> Parser<(), c>.T {
  return p >>> create(()) <|> create(())
}

/**
    `between(open, close, p)` parses `open`, followed by `p` and `close`.
    Returns the value returned by `p`.

        func braces<a> (_ p: StringParser<a>.T) -> StringParser<a>.T {
          return between(char("{"), char("}"), p)
        }
*/
public func between<a, c: Collection, x, y> (_ open: Parser<x, c>.T, _ close: Parser<y, c>.T, _ p: Parser<a, c>.T) -> Parser<a, c>.T {
  return open >>> p >>- { x in
    close >>> create(x)
  }
}

/**
    `skipMany1(p)` applies the parser `p` *one* or more times, skipping
    its result.
*/
public func skipMany1<a, c: Collection> (_ p: Parser<a, c>.T) -> Parser<(), c>.T {
  return p >>> skipMany(p)
}

/**
    `many1(p)` applies the parser `p` *one* or more times. Returns an
    array of the returned values of `p`.

        func word () -> StringParser<[Character]>.T {
          return many1(letter())
        }
*/
public func many1<a, c: Collection> (_ p: Parser<a, c>.T) -> Parser<[a], c>.T {
  return p >>- { x in
    many(p) >>- { xs in
      var r = [x]
      r.append(contentsOf: xs)
      return create(r)
    }
  }
}

/**
    `sepBy(p, sep)` parses *zero* or more occurrences of `p`, separated
    by `sep`. Returns a list of values returned by `p`.

        func commaSep<a> (_ p: StringParser<a>.T) -> StringParser<[a]>.T {
          return sepBy(p, char(","))
        }
*/
public func sepBy<a, c: Collection, x> (_ p: Parser<a, c>.T, _ sep: Parser<x, c>.T) -> Parser<[a], c>.T {
  return sepBy1(p, sep) <|> create([])
}

/**
    `sepBy1(p, sep)` parses *one* or more occurrences of `p`, separated
    by `sep`. Returns a list of values returned by `p`.
*/
public func sepBy1<a, c: Collection, x> (_ p: Parser<a, c>.T, _ sep: Parser<x, c>.T) -> Parser<[a], c>.T {
  return p >>- { x in
    many(sep >>> p) >>- { xs in
      var r = [x]
      r.append(contentsOf: xs)
      return create(r)
    }
  }
}

/**
    `sepEndBy1(p, sep)` parses *one* or more occurrences of `p`,
    separated and optionally ended by `sep`. Returns a list of values
    returned by `p`.
*/
public func sepEndBy1<a, c: Collection, x> (_ p: Parser<a, c>.T, _ sep: Parser<x, c>.T) -> Parser<[a], c>.T {
  return p >>- { x in
    sep >>> sepEndBy(p, sep) >>- { xs in
      var r = [x]
      r.append(contentsOf: xs)
      return create(r)
    } <|> create([x])
  }
}

/**
    `sepEndBy(p, sep)` parses *zero* or more occurrences of `p`,
    separated and optionally ended by `sep`. Returns a list
    of values returned by `p`.
*/
public func sepEndBy<a, c: Collection, x> (_ p: Parser<a, c>.T, _ sep: Parser<x, c>.T) -> Parser<[a], c>.T {
  return sepEndBy1(p, sep) <|> create([])
}

/**
    `endBy1(p, sep)` parses *one* or more occurrences of `p`, separated
    and ended by `sep`. Returns a list of values returned by `p`.
*/
public func endBy1<a, c: Collection, x> (_ p: Parser<a, c>.T, _ sep: Parser<x, c>.T) -> Parser<[a], c>.T {
  return many1(p >>- { x in sep >>> create(x) })
}

/**
    `endBy(p, sep)` parses *zero* or more occurrences of `p`, separated
    and ended by `sep`. Returns a list of values returned by `p`.
*/
public func endBy<a, c: Collection, x> (_ p: Parser<a, c>.T, _ sep: Parser<x, c>.T) -> Parser<[a], c>.T {
  return many(p >>- { x in sep >>> create(x) })
}

/**
    `count(n, p)` parses `n` occurrences of `p`. If `n` is smaller or
    equal to zero, the parser equals to `create([])`. Returns a list of
    `n` values returned by `p`.
*/
public func count<a, c: Collection> (_ n: Int, _ p: Parser<a, c>.T) -> Parser<[a], c>.T {
  if n <= 0 {
    return create([])
  } else {
    return sequence(ArraySlice(repeating: p, count: n))
  }
}

func sequence<a, c: Collection> (_ ps: ArraySlice<Parser<a, c>.T>) -> Parser<[a], c>.T {
  if let p = ps.first {
    return p >>- { x in
      sequence(ps.dropFirst()) >>- { xs in
        var r = [x]
        r.append(contentsOf: xs)
        return create(r)
      }
    }
  } else {
    return create([])
  }
}

/**
    `chainr(p, op, x)` parses *zero* or more occurrences of `p`,
    separated by `op`. Returns a value obtained by a *right* associative
    application of all functions returned by `op` to the values returned
    by `p`. If there are no occurrences of `p`, the value `x` is
    returned.
*/
public func chainr<a, c: Collection> (_ p: Parser<a, c>.T, _ op: Parser<(a, a) -> a, c>.T, _ x: a) -> Parser<a, c>.T {
  return chainr1(p, op) <|> create(x)
}

/**
    `chainl(p, op, x)` parses *zero* or more occurrences of `p`,
    separated by `op`. Returns a value obtained by a *left* associative
    application of all functions returned by `op` to the values returned
    by `p`. If there are no occurrences of `p`, the value `x` is
    returned.
*/
public func chainl<a, c: Collection> (_ p: Parser<a, c>.T, _ op: Parser<(a, a) -> a, c>.T, _ x: a) -> Parser<a, c>.T {
  return chainl1(p, op) <|> create(x)
}

/**
    `chainl1(p, op)` parses *one* or more occurrences of `p`,
    separated by `op`. Returns a value obtained by a *left* associative
    application of all functions returned by `op` to the values returned
    by `p`. This parser can for example be used to eliminate left
    recursion which typically occurs in expression grammars.

        func expr () -> StringParser<Int>.T {
          return chainl1(term(), addop())
        }
        func term () -> StringParser<Int>.T {
          return chainl1(factor(), mulop())
        }
        func factor () -> StringParser<Int>.T {
          return parens(expr()) <|> integer()
        }

        func mulop () -> StringParser<(Int, Int) -> Int>.T {
          return char("*") >>> create(*)
              <|> char("/") >>> create(/)
        }
        func addop () -> StringParser<(Int, Int) -> Int>.T {
          return char("+") >>> create(+)
              <|> char("-") >>> create(-)
        }
*/
public func chainl1<a, c: Collection> (_ p: Parser<a, c>.T, _ op: Parser<(a, a) -> a, c>.T) -> Parser<a, c>.T {
  func rest (_ x: a) -> Parser<a, c>.T {
    return op >>- { f in
      p >>- { y in
        rest(f(x, y))
      }
    } <|> create(x)
  }
  return p >>- { x in rest(x) }
}

/**
    `chainr1(p, op)` parses *one* or more occurrences of `p`,
    separated by `op`. Returns a value obtained by a *right* associative
    application of all functions returned by `op` to the values returned
    by `p`.
*/
public func chainr1<a, c: Collection> (_ p: Parser<a, c>.T, _ op: Parser<(a, a) -> a, c>.T) -> Parser<a, c>.T {
  func scan () -> Parser<a, c>.T {
    return p >>- { x in rest(x) }
  }
  func rest (_ x: a) -> Parser<a, c>.T {
    return op >>- { f in
      scan() >>- { y in
        create(f(x, y))
      }
    } <|> create(x)
  }
  return scan()
}

/*
    Tricky combinators
*/

/**
    The parser `anyToken` accepts any kind of token. It is for example
    used to implement 'eof'. Returns the accepted token.
*/
public func anyToken<c: Collection where c.SubSequence == c> () -> Parser<c.Iterator.Element, c>.T {
  return tokenPrim({ String($0) }, { pos, _, _ in pos }, { $0 })
}

/**
    This parser only succeeds at the end of the input. This is not a
    primitive parser but it is defined using 'notFollowedBy'.
*/
public func eof<c: Collection where c.SubSequence == c> () -> Parser<(), c>.T {
  return notFollowedBy(anyToken()) <?> "end of input"
}

/**
    `notFollowedBy(p)` only succeeds when parser `p` fails. This parser
    does not consume any input. This parser can be used to implement the
    'longest match' rule. For example, when recognizing keywords (for
    example `let`), we want to make sure that a keyword is not followed
    by a legal identifier character, in which case the keyword is
    actually an identifier (for example `lets`). We can program this
    behaviour as follows:

        func keywordLet () -> StringParser<String>.T {
          return attempt(string("let") <<< notFollowedBy(alphaNum()))
        }
*/
public func notFollowedBy<a, c: Collection> (_ p: Parser<a, c>.T) -> Parser<(), c>.T {
  return attempt(
    attempt(p) >>- { c in unexpected(String(c))}
    <|> create(())
  )
}

/**
    `manyTill(p, end)` applies parser `p` *zero* or more times until
    parser `end` succeeds. Returns the list of values returned by `p`.
    This parser can be used to scan comments:

        func simpleComment () -> StringParser<String>.T {
          return string("<!--") >>> manyTill(anyChar(), attempt(string("-->"))) >>- { cs in create(String(cs)) }
        }

    Note the overlapping parsers `anyChar` and `string("-->")`, and
    therefore the use of the 'attempt' combinator.
*/
public func manyTill<a, c: Collection, x> (_ p: Parser<a, c>.T, _ end: Parser<x, c>.T) -> Parser<[a], c>.T {
  func scan () -> Parser<[a], c>.T {
    return end >>> create([])
        <|> p >>- { x in
          scan() >>- { xs in
            var r = [x]
            r.append(contentsOf: xs)
            return create(r)
          }
        }
  }
  return scan()
}
