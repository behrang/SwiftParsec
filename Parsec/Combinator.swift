/*
    Commonly used generic combinators.
*/

/**
    `choice(ps)` tries to apply the parsers in the array `ps` in order,
    until one of them succeeds. Returns the value of the succeeding
    parser.
*/
public func choice<a, c: Collection> (_ ps: [ParserClosure<a, c>]) -> ParserClosure<a, c> {
  return ps.reversed().reduce(parserZero, parserPlus)
}

/**
    `option(x, p)` tries to apply parser `p`. If `p` fails without
    consuming input, it returns the value `x`, otherwise the value
    returned by `p`.

        func priority () -> StringParser<Int> {
          return option(0, digit >>- { d in
            if let i = Int(String(d)) {
              return create(i)
            } else {
              return fail("this will not happen")
            }
          })()
        }
*/
public func option<a, c: Collection> (_ x: a, _ p: ParserClosure<a, c>) -> ParserClosure<a, c> {
  return p <|> create(x)
}

/**
    `optionMaybe(p)` tries to apply parser `p`.  If `p` fails without
    consuming input, it returns '.none', otherwise it returns
    '.some' the value returned by `p`.
*/
public func optionMaybe<a, c: Collection> (_ p: ParserClosure<a, c>) -> ParserClosure<a?, c> {
  return p >>- { x in create(x) } <|> create(nil)
}

/**
    `optional(p)` tries to apply parser `p`.  It will parse `p` or nothing.
    It only fails if `p` fails after consuming input. It discards the result
    of `p`.
*/
public func optional<a, c: Collection> (_ p: ParserClosure<a, c>) -> ParserClosure<(), c> {
  return p >>> create(()) <|> create(())
}

/**
    `between(open, close, p)` parses `open`, followed by `p` and `close`.
    Returns the value returned by `p`.

        func braces<a> (_ p: StringParserClosure<a>) -> StringParserClosure<a> {
          return between(char("{"), char("}"), p)
        }
*/
public func between<a, c: Collection, x, y> (_ open: ParserClosure<x, c>, _ close: ParserClosure<y, c>, _ p: ParserClosure<a, c>) -> ParserClosure<a, c> {
  return open >>> p <<< close
}

/**
    `skipMany1(p)` applies the parser `p` *one* or more times, skipping
    its result.
*/
public func skipMany1<a, c: Collection> (_ p: ParserClosure<a, c>) -> ParserClosure<(), c> {
  return p >>> skipMany(p)
}

/**
    `many1(p)` applies the parser `p` *one* or more times. Returns an
    array of the returned values of `p`.

        func word () -> StringParser<[Character]> {
          return many1(letter)()
        }
*/
public func many1<a, c: Collection> (_ p: ParserClosure<a, c>) -> ParserClosure<[a], c> {
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

        func commaSep<a> (_ p: StringParserClosure<a>) -> StringParserClosure<[a]> {
          return sepBy(p, char(","))
        }
*/
public func sepBy<a, c: Collection, x> (_ p: ParserClosure<a, c>, _ sep: ParserClosure<x, c>) -> ParserClosure<[a], c> {
  return sepBy1(p, sep) <|> create([])
}

/**
    `sepBy1(p, sep)` parses *one* or more occurrences of `p`, separated
    by `sep`. Returns a list of values returned by `p`.
*/
public func sepBy1<a, c: Collection, x> (_ p: ParserClosure<a, c>, _ sep: ParserClosure<x, c>) -> ParserClosure<[a], c> {
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
public func sepEndBy1<a, c: Collection, x> (_ p: ParserClosure<a, c>, _ sep: ParserClosure<x, c>) -> ParserClosure<[a], c> {
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
public func sepEndBy<a, c: Collection, x> (_ p: ParserClosure<a, c>, _ sep: ParserClosure<x, c>) -> ParserClosure<[a], c> {
  return sepEndBy1(p, sep) <|> create([])
}

/**
    `endBy1(p, sep)` parses *one* or more occurrences of `p`, separated
    and ended by `sep`. Returns a list of values returned by `p`.
*/
public func endBy1<a, c: Collection, x> (_ p: ParserClosure<a, c>, _ sep: ParserClosure<x, c>) -> ParserClosure<[a], c> {
  return many1(p >>- { x in sep >>> create(x) })
}

/**
    `endBy(p, sep)` parses *zero* or more occurrences of `p`, separated
    and ended by `sep`. Returns a list of values returned by `p`.
*/
public func endBy<a, c: Collection, x> (_ p: ParserClosure<a, c>, _ sep: ParserClosure<x, c>) -> ParserClosure<[a], c> {
  return many(p >>- { x in sep >>> create(x) })
}

/**
    `count(n, p)` parses `n` occurrences of `p`. If `n` is smaller or
    equal to zero, the parser equals to `create([])`. Returns a list of
    `n` values returned by `p`.
*/
public func count<a, c: Collection> (_ n: Int, _ p: ParserClosure<a, c>) -> ParserClosure<[a], c> {
  if n <= 0 {
    return create([])
  } else {
    return sequence(ArraySlice(repeating: p, count: n))
  }
}

func sequence<a, c: Collection> (_ ps: ArraySlice<ParserClosure<a, c>>) -> ParserClosure<[a], c> {
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
public func chainr<a, c: Collection> (_ p: ParserClosure<a, c>, _ op: ParserClosure<(a, a) -> a, c>, _ x: a) -> ParserClosure<a, c> {
  return chainr1(p, op) <|> create(x)
}

/**
    `chainl(p, op, x)` parses *zero* or more occurrences of `p`,
    separated by `op`. Returns a value obtained by a *left* associative
    application of all functions returned by `op` to the values returned
    by `p`. If there are no occurrences of `p`, the value `x` is
    returned.
*/
public func chainl<a, c: Collection> (_ p: ParserClosure<a, c>, _ op: ParserClosure<(a, a) -> a, c>, _ x: a) -> ParserClosure<a, c> {
  return chainl1(p, op) <|> create(x)
}

/**
    `chainl1(p, op)` parses *one* or more occurrences of `p`,
    separated by `op`. Returns a value obtained by a *left* associative
    application of all functions returned by `op` to the values returned
    by `p`. This parser can for example be used to eliminate left
    recursion which typically occurs in expression grammars.

        func expr () -> StringParser<Int> {
          return chainl1(term, addop)()
        }
        func term () -> StringParser<Int> {
          return chainl1(factor, mulop)()
        }
        func factor () -> StringParser<Int> {
          return (parens(expr) <|> integer)()
        }

        func mulop () -> StringParser<(Int, Int) -> Int> {
          return (char("*") >>> create(*)
              <|> char("/") >>> create(/))()
        }
        func addop () -> StringParser<(Int, Int) -> Int> {
          return (char("+") >>> create(+)
              <|> char("-") >>> create(-))()
        }
*/
public func chainl1<a, c: Collection> (_ p: ParserClosure<a, c>, _ op: ParserClosure<(a, a) -> a, c>) -> ParserClosure<a, c> {
  func rest (_ x: a) -> ParserClosure<a, c> {
    return op >>- { f in
      p >>- { y in
        rest(f(x, y))
      }
    } <|> create(x)
  }
  return p >>- rest
}

/**
    `chainr1(p, op)` parses *one* or more occurrences of `p`,
    separated by `op`. Returns a value obtained by a *right* associative
    application of all functions returned by `op` to the values returned
    by `p`.
*/
public func chainr1<a, c: Collection> (_ p: ParserClosure<a, c>, _ op: ParserClosure<(a, a) -> a, c>) -> ParserClosure<a, c> {
  func scan () -> Parser<a, c> {
    return (p >>- rest)()
  }
  func rest (_ x: a) -> ParserClosure<a, c> {
    return op >>- { f in
      scan >>- { y in
        create(f(x, y))
      }
    } <|> create(x)
  }
  return scan
}

/*
    Tricky combinators
*/

/**
    The parser `anyToken` accepts any kind of token. It is for example
    used to implement 'eof'. Returns the accepted token.
*/
public func anyToken<c: Collection> () -> Parser<c.Iterator.Element, c>
  where c.SubSequence == c
{
  return (tokenPrim({ String(describing: $0) }, { pos, _, _ in pos }, { $0 }))()
}

/**
    This parser only succeeds at the end of the input. This is not a
    primitive parser but it is defined using 'notFollowedBy'.
*/
public func eof<c: Collection> () -> Parser<(), c>
  where c.SubSequence == c
{
  return (notFollowedBy(anyToken) <?> "end of input")()
}

/**
    `notFollowedBy(p)` only succeeds when parser `p` fails. This parser
    does not consume any input. This parser can be used to implement the
    'longest match' rule. For example, when recognizing keywords (for
    example `let`), we want to make sure that a keyword is not followed
    by a legal identifier character, in which case the keyword is
    actually an identifier (for example `lets`). We can program this
    behaviour as follows:

        func keywordLet () -> StringParser<String> {
          return attempt(string("let") <<< notFollowedBy(alphaNum))()
        }
*/
public func notFollowedBy<a, c: Collection> (_ p: ParserClosure<a, c>) -> ParserClosure<(), c> {
  return attempt(
    attempt(p) >>- { c in unexpected(String(describing: c)) }
    <|> create(())
  )
}

/**
    `manyTill(p, end)` applies parser `p` *zero* or more times until
    parser `end` succeeds. Returns the list of values returned by `p`.
    This parser can be used to scan comments:

        func simpleComment () -> StringParser<String> {
          return (string("<!--") >>> manyTill(anyChar, attempt(string("-->"))) >>- { cs in create(String(cs)) })()
        }

    Note the overlapping parsers `anyChar` and `string("-->")`, and
    therefore the use of the 'attempt' combinator.
*/
public func manyTill<a, c: Collection, x> (_ p: ParserClosure<a, c>, _ end: ParserClosure<x, c>) -> ParserClosure<[a], c> {
  func scan () -> Parser<[a], c> {
    return (end >>> create([])
        <|> p >>- { x in
          scan >>- { xs in
            var r = [x]
            r.append(contentsOf: xs)
            return create(r)
          }
        })()
  }
  return scan
}
