import SwiftParsec

func csvFile () -> Parser<[[String]], String.CharacterView>.T {
  return many(line()) >>- { result in
    eof() >>| create(result)
  }
}

func line () -> Parser<[String], String.CharacterView>.T {
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

func cells () -> Parser<[String], String.CharacterView>.T {
  return cellContent() >>- { first in
    remainingCells() >>- { next in
      var r = [first]
      r.append(contentsOf: next)
      return create(r)
    }
  }
}

func remainingCells () -> Parser<[String], String.CharacterView>.T {
  return (character(",") >>| cells()) <|> create([])
}

func cellContent () -> Parser<String, String.CharacterView>.T {
  return many(noneOf([",","\n"])) >>- { cs in create(String(cs)) }
}

func eol () -> Parser<Character, String.CharacterView>.T {
  return character("\n") <?> "\\n"
}

func parseCSV (_ input: String) {
  print(csvFile()(State(input.characters)))
}
