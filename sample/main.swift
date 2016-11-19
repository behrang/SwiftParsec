import Parsec
import Foundation

func vowel () -> StringParser<Character> {
  return oneOf("aeiou")()
}

func consonant () -> StringParser<Character> {
  return noneOf("aeiou")()
}

func semiColon () -> StringParser<Character> {
  return char(";")()
}

func digits () -> StringParser<[Character]> {
  return many1(digit)()
}

func digit () -> StringParser<Character> {
  return satisfy(isDigit)()
}

func isDigit (_ c: Character) -> Bool {
  let digits = CharacterSet.decimalDigits
  return String(c).rangeOfCharacter(from: digits) != nil
}

func divOrMod () -> StringParser<String> {
  return ( string("div") <|> string("mod") )()
}

func priority () -> StringParser<Int> {
  return option(0, digit >>- { d in
    if let i = Int(String(d)) {
      return create(i)
    } else {
      return fail("this will not happen")
    }
  })()
}

func braces<a> (_ p: @escaping StringParserClosure<a>) -> StringParserClosure<a> {
  return { between(char("{"), char("}"), p)() }
}

func identifier () -> StringParser<String> {
  return ( letter >>- { c in
    many(alphaNum <|> char("_")) >>- { cs in
      return create(String(c) + String(cs))
    }
  } )()
}

func word () -> StringParser<[Character]> {
  return many1(letter)()
}

func commaSep<a> (_ p: @escaping StringParserClosure<a>) -> StringParserClosure<[a]> {
  return { sepBy(p, char(","))() }
}

func parens<a> (_ p: @escaping StringParserClosure<a>) -> StringParserClosure<a> {
  return { between(char("("), char(")"), p)() }
}

func integer () -> StringParser<Int> {
  return (many1(digit) >>- { ds in
    if let i = Int(String(ds)) {
      return create(i)
    } else {
      return fail("invalid integer")
    }
  })()
}

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

func keywordLet () -> StringParser<String> {
  return attempt(string("let") <<< notFollowedBy(alphaNum))()
}

func simpleComment () -> StringParser<String> {
  return (string("<!--") >>> manyTill(anyChar, attempt(string("-->"))) >>- { cs in create(String(cs)) })()
}

parseTest(simpleComment, "<!--lets 2*(3+4)-->/5-(6+2)".characters)
