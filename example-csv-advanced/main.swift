import SwiftParsec

func csv () -> Parser<[[String]], String.CharacterView>.T {
  return endBy(line(), endOfLine())
}

func line () -> Parser<[String], String.CharacterView>.T {
  return sepBy(cell(), char(","))
}

func cell () -> Parser<String, String.CharacterView>.T {
  return quotedCell() <|> simpleCell()
}

func quotedCell () -> Parser<String, String.CharacterView>.T {
  return between(char("\""), char("\""), quotedCellContent())
}

func quotedCellContent () -> Parser<String, String.CharacterView>.T {
  return many(quotedCellChar()) >>- { cs in create(String(cs)) }
}

func quotedCellChar () -> Parser<Character, String.CharacterView>.T {
  return noneOf("\"") <|> attempt((string("\"\"") <?> "escaped double quote") >>| create("\"") )
}

func simpleCell () -> Parser<String, String.CharacterView>.T {
  return many(noneOf(",\n")) >>- { cs in create(String(cs)) }
}

func main () {
  if Process.arguments.count != 2 {
    print("Usage: \(Process.arguments[0]) csv_file")
  } else {
    let result = try! parse(csv(), file: Process.arguments[1])
    switch result {
    case let .left(err): print(err)
    case let .right(x): format(x)
    }
  }
}

func format (_ data: [[String]]) {
  data.forEach{ item in
    print(item.joined(separator: "\t"))
  }
}

main()
