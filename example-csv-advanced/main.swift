import Parsec

func csv () -> StringParser<[[String]]>.T {
  return endBy(line(), endOfLine())
}

func line () -> StringParser<[String]>.T {
  return sepBy(cell(), char(","))
}

func cell () -> StringParser<String>.T {
  return quotedCell() <|> simpleCell()
}

func simpleCell () -> StringParser<String>.T {
  return many(noneOf(",\n"))
}

func quotedCell () -> StringParser<String>.T {
  return between(char("\""), char("\""), quotedCellContent())
}

func quotedCellContent () -> StringParser<String>.T {
  return many(quotedCellChar())
}

func quotedCellChar () -> StringParser<Character>.T {
  return noneOf("\"") <|> escapedQuote()
}

func escapedQuote () -> StringParser<Character>.T {
  return attempt(string("\"\"") <?> "escaped double quote") >>> create("\"")
}

func main () {
  if CommandLine.arguments.count != 2 {
    print("Usage: \(CommandLine.arguments[0]) csv_file")
  } else {
    let result = try! parse(csv(), contentsOfFile: CommandLine.arguments[1])
    switch result {
    case let .left(err): print(err)
    case let .right(x): format(x)
    }
  }
}

func format (_ data: [[String]]) {
  data.forEach{ item in
    print(item.joined(separator: "\n"), terminator: "\n\n")
  }
}

main()
