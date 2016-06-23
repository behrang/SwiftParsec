import SwiftParsec

func csvFile4 () -> Parser<[[String]], String.CharacterView>.T {
  return endBy(line4(), eol4())
}

func line4 () -> Parser<[String], String.CharacterView>.T {
  return sepBy(cell4(), char(","))
}

func cell4 () -> Parser<String, String.CharacterView>.T {
  return char("\"") >>- { _ in
    many(quotedCharacter4()) >>- { content in
      ( char("\"") <?> "quote at end of cell" ) >>- { _ in
        create(String(content))
      }
    }
  } <|> (many(noneOf([",", "\n", "\r"])) >>- { xs in create(String(xs))})
}

func quotedCharacter4 () -> Parser<Character, String.CharacterView>.T {
  return noneOf(["\""]) <|> attempt((string("\"\"")  <?> "\\\"\\\"") >>- { _ in create(Character("\""))})
}

func eol4 () -> Parser<String, String.CharacterView>.T {
  return attempt(string("\n\r"))
    <|> attempt(string("\r\n"))
    <|> string("\n")
    <|> string("\r")
    <?> "end of line"
}

func parseCSV4 (_ input: String) {
  print(csvFile4()(State(input.characters)))
}
