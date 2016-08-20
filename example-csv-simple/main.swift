import Parsec

func csv () -> StringParser<[[String]]> {
  return endBy(line(), char("\n"))
}

func line () -> StringParser<[String]> {
  return sepBy(cell(), char(","))
}

func cell () -> StringParser<String> {
  return many(noneOf(",\n")) >>- { chars in create(String(chars)) }
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
