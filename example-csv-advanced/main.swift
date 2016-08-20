import Parsec

func csv () -> StringParser<[[String]]> {
  return endBy(line(), endOfLine())
}

func line () -> StringParser<[String]> {
  return sepBy(cell(), char(","))
}

func cell () -> StringParser<String> {
  return quotedCell() <|> simpleCell()
}

func simpleCell () -> StringParser<String> {
  return many(noneOf(",\n")) >>- { cs in create(String(cs)) }
}

func quotedCell () -> StringParser<String> {
  return between(char("\""), char("\""), quotedCellContent())
}

func quotedCellContent () -> StringParser<String> {
  return many(quotedCellChar()) >>- { cs in create(String(cs)) }
}

func quotedCellChar () -> StringParser<Character> {
  return noneOf("\"") <|> escapedQuote()
}

func escapedQuote () -> StringParser<Character> {
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
