import SwiftParsec

func csvFile2 () -> (State<String.CharacterView>) -> Consumed<[[String]], String.CharacterView> {
  // return many(endBy(sepBy(cellContent(), character(",")), character("\n")))
  return endBy(line2(), eol2())
}

func line2 () -> (State<String.CharacterView>) -> Consumed<[String], String.CharacterView> {
  return sepBy(cell2(), character(","))
}

func cell2 () -> (State<String.CharacterView>) -> Consumed<String, String.CharacterView> {
  return many(noneOf([",", "\n"])) >>- { xs in create(String(xs)) }
}

func eol2 () -> (State<String.CharacterView>) -> Consumed<Character, String.CharacterView> {
  return character("\n")
}

func parseCSV2 (_ input: String) {
  print(csvFile()(State(input.characters)))
}
