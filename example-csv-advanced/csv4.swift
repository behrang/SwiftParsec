import SwiftParsec

func csvFile4 () -> (State<String.CharacterView>) -> Consumed<[[String]], String.CharacterView> {
  return endBy(line4(), eol4)
}

func line4 () -> (State<String.CharacterView>) -> Consumed<[String], String.CharacterView> {
  return sepBy(cell4(), character(","))
}

func cell4 () -> (State<String.CharacterView>) -> Consumed<String, String.CharacterView> {
  return character("\"") >>- { _ in
    many(quotedCharacter4()) >>- { content in
      character("\"") <?> "quote at end of cell" >>- { _ in
        create(String(content))
      }
    }
  } <|> (many(noneOf([",", "\n", "\r"])) >>- { xs in create(String(xs))})
}

func quotedCharacter4 () -> (State<String.CharacterView>) -> Consumed<Character, String.CharacterView> {
  return noneOf(["\""]) <|> attempt(string("\"\"".characters)  <?> "\\\"\\\"" >>- { _ in create(Character("\""))})
}

let eol4 = {
      attempt(string("\n\r".characters))
  <|> attempt(string("\r\n".characters))
  <|> string("\n".characters)
  <|> string("\r".characters)
  <?> "end of line"
}()

func parseCSV4 (_ input: String) {
  print(csvFile4()(State(input.characters)))
}
