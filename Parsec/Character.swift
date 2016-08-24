/*
    Commonly used character parsers.
*/

/**
    `oneOf(s)` succeeds if the current character is in the supplied
    string `s`. Returns the parsed character. See also
    'satisfy'.

        func vowel () -> StringParser<Character> {
          return oneOf("aeiou")()
        }
*/
public func oneOf<c: Collection> (_ s: String) -> ParserClosure<Character, c>
  where c.SubSequence == c, c.Iterator.Element == Character
{
  return satisfy { c in s.contains(String(c)) }
}

/**
    As the dual of 'oneOf', `noneOf(s)` succeeds if the current
    character is *not* in the supplied string `s`. Returns the
    parsed character.

        func consonant () -> StringParser<Character> {
          return noneOf("aeiou")()
        }
*/
public func noneOf<c: Collection> (_ s: String) -> ParserClosure<Character, c>
  where c.SubSequence == c, c.Iterator.Element == Character
{
  return satisfy { c in !s.contains(String(c)) }
}

/**
    Skips *zero* or more white space characters. See also 'skipMany'.
*/
public func spaces<c: Collection> () -> Parser<(), c>
  where c.SubSequence == c, c.Iterator.Element == Character
{
  return (skipMany(space) <?> "white space")()
}

/**
    Parses a white space character (any character which satisfies 'isSpace').
    Returns the parsed character.
*/
public func space<c: Collection> () -> Parser<Character, c>
  where c.SubSequence == c, c.Iterator.Element == Character
{
  return (satisfy(isSpace) <?> "space")()
}

/**
    Parses a newline character ('\n'). Returns a newline character.
*/
public func newline<c: Collection> () -> Parser<Character, c>
  where c.SubSequence == c, c.Iterator.Element == Character
{
  return (char("\n") <?> "lf new-line")()
}

/**
    Parses a carriage return character ('\r') followed by a newline character ('\n').
    Returns a newline character.
*/
public func crlf<c: Collection> () -> Parser<Character, c>
  where c.SubSequence == c, c.Iterator.Element == Character
{
  return (char("\r\n") >>> create("\n") <?> "crlf new-line")()
}

/**
    Parses a CRLF (see 'crlf') or LF (see 'newline') end-of-line.
    Returns a newline character ('\n').
*/
public func endOfLine<c: Collection> () -> Parser<Character, c>
  where c.SubSequence == c, c.Iterator.Element == Character
{
  return (newline <|> crlf <?> "new-line")()
}

/**
    Parses a tab character ('\t'). Returns a tab character.
*/
public func tab<c: Collection> () -> Parser<Character, c>
  where c.SubSequence == c, c.Iterator.Element == Character
{
  return (char("\t") <?> "tab")()
}

/**
    Parses an upper case letter (a character between 'A' and 'Z').
    Returns the parsed character.
*/
public func upper<c: Collection> () -> Parser<Character, c>
  where c.SubSequence == c, c.Iterator.Element == Character
{
  return (satisfy(isUpper) <?> "uppercase letter")()
}

/**
    Parses a lower case character (a character between 'a' and 'z').
    Returns the parsed character.
*/
public func lower<c: Collection> () -> Parser<Character, c>
  where c.SubSequence == c, c.Iterator.Element == Character
{
  return (satisfy(isLower) <?> "lowercase letter")()
}

/**
    Parses a letter or digit (a character between '0' and '9').
    Returns the parsed character.
*/
public func alphaNum<c: Collection> () -> Parser<Character, c>
  where c.SubSequence == c, c.Iterator.Element == Character
{
  return (satisfy(isAlphaNum) <?> "letter or digit")()
}

/**
    Parses a letter (an upper case or lower case character). Returns the
    parsed character.
*/
public func letter<c: Collection> () -> Parser<Character, c>
  where c.SubSequence == c, c.Iterator.Element == Character
{
  return (satisfy(isLetter) <?> "letter")()
}

/**
    Parses a digit. Returns the parsed character.
*/
public func digit<c: Collection> () -> Parser<Character, c>
  where c.SubSequence == c, c.Iterator.Element == Character
{
  return (satisfy(isDigit) <?> "digit")()
}

/**
    Parses a hexadecimal digit (a digit or a letter between 'a' and
    'f' or 'A' and 'F'). Returns the parsed character.
*/
public func hexDigit<c: Collection> () -> Parser<Character, c>
  where c.SubSequence == c, c.Iterator.Element == Character
{
  return (satisfy(isHexDigit) <?> "hexadecimal digit")()
}

/**
    Parses an octal digit (a character between '0' and '7'). Returns
    the parsed character.
*/
public func octDigit<c: Collection> () -> Parser<Character, c>
  where c.SubSequence == c, c.Iterator.Element == Character
{
  return (satisfy(isOctDigit) <?> "octal digit")()
}

/**
    `char(c)` parses a single character `c`. Returns the parsed
    character (i.e. `c`).

        func semiColon () -> StringParser<Character> {
          return char(";")()
        }
*/
public func char<c: Collection> (_ c: Character) -> ParserClosure<Character, c>
  where c.SubSequence == c, c.Iterator.Element == Character
{
  return satisfy { x in x == c } <?> String(c)
}

/**
    This parser succeeds for any character. Returns the parsed character.
*/
public func anyChar<c: Collection> () -> Parser<Character, c>
  where c.SubSequence == c, c.Iterator.Element == Character
{
  return (satisfy { _ in true })()
}

/**
    The parser `satisfy(f)` succeeds for any character for which the
    supplied function `f` returns 'true'. Returns the character that is
    actually parsed.

        func digit () -> StringParser<Character> {
          return satisfy(isDigit)()
        }
*/
public func satisfy<c: Collection> (_ f: @escaping (Character) -> Bool) -> ParserClosure<Character, c>
  where c.SubSequence == c, c.Iterator.Element == Character
{
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
    `string(s)` parses a string given by `s`. Returns
    the parsed string (i.e. `s`).

        func divOrMod () -> StringParser<String> {
          return ( string("div") <|> string("mod") )()
        }
*/
public func string<c: Collection> (_ s: String) -> ParserClosure<String, c>
  where c.SubSequence == c, c.Iterator.Element == Character
{
  func show (_ cs: [Character]) -> String {
    return String(reflecting: String(cs))
  }
  func next (_ pos: SourcePos, _ cs: [Character]) -> SourcePos {
    var newPos = pos
    newPos.update(cs)
    return newPos
  }
  return tokens(show, next, Array(s.characters)) >>- { cs in create(String(cs)) }
}
