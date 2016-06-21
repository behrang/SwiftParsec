import SwiftParsec

func csvFile2 () -> Parser<[[String]], String.CharacterView>.T {
  // return many(endBy(sepBy(cellContent(), character(",")), character("\n")))
  return endBy(line2(), eol2())
}

func line2 () -> Parser<[String], String.CharacterView>.T {
  return sepBy(cell2(), character(","))
}

func cell2 () -> Parser<String, String.CharacterView>.T {
  return many(noneOf([",", "\n"])) >>- { xs in create(String(xs)) }
}

func eol2 () -> Parser<Character, String.CharacterView>.T {
  return character("\n")
}

func parseCSV2 (_ input: String) {
  print(csvFile()(State(input.characters)))
}
