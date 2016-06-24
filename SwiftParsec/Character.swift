/*
    Commonly used character parsers.
*/

/**
    `oneOf(cs)` succeeds if the current character is in the supplied
    list of characters `cs`. Returns the parsed character. See also
    'satisfy'.

        let vowel = oneOf("aeiou")
*/
public func oneOf<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> (_ cs: [Character]) -> Parser<Character, c>.T {
  return satisfy { c in cs.contains(c) }
}

public func oneOf<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> (_ s: String) -> Parser<Character, c>.T {
  return oneOf(Array(s.characters))
}

/**
    As the dual of 'oneOf', `noneOf(cs)` succeeds if the current
    character *not* in the supplied list of characters `cs`. Returns the
    parsed character.

        let consonant = noneOf("aeiou")
*/
public func noneOf<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> (_ cs: [Character]) -> Parser<Character, c>.T {
  return satisfy { c in !cs.contains(c) }
}

public func noneOf<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> (_ s: String) -> Parser<Character, c>.T {
  return noneOf(Array(s.characters))
}

/**
    Skips *zero* or more white space characters. See also 'skipMany'.
*/
public func spaces<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> () -> Parser<(), c>.T {
  return skipMany(space()) <?> "white space"
}

/**
    Parses a white space character (any character which satisfies 'isSpace')
    Returns the parsed character.
*/
public func space<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> () -> Parser<Character, c>.T {
  return satisfy(isSpace) <?> "space"
}

/**
    Parses a newline character ('\n'). Returns a newline character.
*/
public func newline<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> () -> Parser<Character, c>.T {
  return char("\n") <?> "lf new-line"
}

/**
    Parses a carriage return character ('\r') followed by a newline character ('\n').
    Returns a newline character.
*/
public func crlf<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> () -> Parser<Character, c>.T {
  return char("\r") >>| char("\n") <?> "crlf new-line"
}

/**
    Parses a CRLF (see 'crlf') or LF (see 'newline') end-of-line.
    Returns a newline character ('\n').
*/
public func endOfLine<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> () -> Parser<Character, c>.T {
  return newline() <|> crlf() <?> "new-line"
}

/**
    Parses a tab character ('\t'). Returns a tab character.
*/
public func tab<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> () -> Parser<Character, c>.T {
  return char("\t") <?> "tab"
}

/**
    Parses an upper case letter (a character between 'A' and 'Z').
    Returns the parsed character.
*/
public func upper<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> () -> Parser<Character, c>.T {
  return satisfy(isUpper) <?> "uppercase letter"
}

/**
    Parses a lower case character (a character between 'a' and 'z').
    Returns the parsed character.
*/
public func lower<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> () -> Parser<Character, c>.T {
  return satisfy(isLower) <?> "lowercase letter"
}

/**
    Parses a letter or digit (a character between '0' and '9').
    Returns the parsed character.
*/
public func alphaNum<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> () -> Parser<Character, c>.T {
  return satisfy(isAlphaNum) <?> "letter or digit"
}

/**
    Parses a letter (an upper case or lower case character). Returns the
    parsed character.
*/
public func letter<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> () -> Parser<Character, c>.T {
  return satisfy(isLetter) <?> "letter"
}

/**
    Parses a digit. Returns the parsed character.
*/
public func digit<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> () -> Parser<Character, c>.T {
  return satisfy(isDigit) <?> "digit"
}

/**
    Parses a hexadecimal digit (a digit or a letter between 'a' and
    'f' or 'A' and 'F'). Returns the parsed character.
*/
public func hexDigit<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> () -> Parser<Character, c>.T {
  return satisfy(isHexDigit) <?> "hexadecimal digit"
}

/**
    Parses an octal digit (a character between '0' and '7'). Returns
    the parsed character.
*/
public func octDigit<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> () -> Parser<Character, c>.T {
  return satisfy(isOctDigit) <?> "octal digit"
}

/**
    `char(c)` parses a single character `c`. Returns the parsed
    character (i.e. `c`).

    let semiColon = char(";")
*/
public func char<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> (_ c: Character) -> Parser<Character, c>.T {
  return satisfy { x in x == c } <?> String(c)
}

/**
    This parser succeeds for any character. Returns the parsed character.
*/
public func anyChar<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> () -> Parser<Character, c>.T {
  return satisfy { _ in true }
}

/**
    The parser `satisfy(f)` succeeds for any character for which the
    supplied function `f` returns 'true'. Returns the character that is
    actually parsed.

        let digit = satisfy(isDigit)
*/
public func satisfy<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> (_ f: (Character) -> Bool) -> Parser<Character, c>.T {
  func show (_ c: Character) -> String {
    return String(c)
  }
  func next (_ pos: SourcePos, _ c: Character, _ cs: c) -> SourcePos {
    var newPos = pos
    newPos.update(c)
    return newPos
  }
  func test (_ c: Character) -> Character? {
    return f(c) ? c : nil
  }
  return tokenPrim(show, next, test)
}

/**
    `string(s)` parses a sequence of characters given by `s`. Returns
    the parsed string (i.e. `s`).

        let divOrMod = string("div")
                    <|> string("mod")
*/
public func string<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> (_ s: [Character]) -> Parser<[Character], c>.T {
  func show (_ cs: [Character]) -> String {
    return String(cs)
  }
  func next (_ pos: SourcePos, _ cs: [Character]) -> SourcePos {
    var newPos = pos
    newPos.update(cs)
    return newPos
  }
  return tokens(show, next, s)
}

public func string<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> (_ s: String) -> Parser<String, c>.T {
  return string(Array(s.characters)) >>- { cs in create(String(cs)) }
}
