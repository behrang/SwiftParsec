import SwiftParsec

func csvFile () -> (State<String.CharacterView>) -> Consumed<[[String]], String.CharacterView> {
  return many(line()) >>- { result in
    eof() >>| create(result)
  }
}

func line () -> (State<String.CharacterView>) -> Consumed<[String], String.CharacterView> {
  return cells() >>- { result in
    eol() >>| create(result)
  }
}
// alternative:
// let line = {
//   return cells() >>- { result in
//     eol() >>| create(result)
//   }
// }()

func cells () -> (State<String.CharacterView>) -> Consumed<[String], String.CharacterView> {
  return cellContent() >>- { first in
    remainingCells() >>- { next in
      var r = [first]
      r.append(contentsOf: next)
      return create(r)
    }
  }
}

func remainingCells () -> (State<String.CharacterView>) -> Consumed<[String], String.CharacterView> {
  return (character(",") >>| cells()) <|> create([])
}

func cellContent () -> (State<String.CharacterView>) -> Consumed<String, String.CharacterView> {
  return many(noneOf([",","\n"])) >>- { cs in create(String(cs)) }
}

func eol () -> (State<String.CharacterView>) -> Consumed<Character, String.CharacterView> {
  return character("\n") <?> "\\n"
}

func parseCSV (_ input: String) {
  print(csvFile()(State(input.characters)))
}
