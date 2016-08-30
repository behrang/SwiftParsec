/**
    `StringParser<a>` is an alias for `Parser<a, String.CharacterView>`.
*/
public typealias StringParser<a> = (State<String.CharacterView, ()>) -> Consumed<a, String.CharacterView, ()>
public typealias StringParserClosure<a> = () -> (State<String.CharacterView, ()>) -> Consumed<a, String.CharacterView, ()>
public typealias StringUserParser<a, u> = (State<String.CharacterView, u>) -> Consumed<a, String.CharacterView, u>
public typealias StringUserParserClosure<a, u> = () -> (State<String.CharacterView, u>) -> Consumed<a, String.CharacterView, u>

/**
    `parse(p, file: filePath)` runs a string parser `p` on the
    input read from `filePath` using 'String(contentsOfFile: filePath)'.
    Returns either a 'ParseError' ('left') or a value of type `a` ('right').

    func main () {
      let result = try! parse(numbers(), file: "digits.txt")
      switch result {
      case let .left(err): print(err)
      case let .right(xs): print(sum(xs))
      }
    }
*/
public func parse<a, c: Collection, u> (_ p: UserParserClosure<a, c, u>, _ user: u, contentsOfFile file: String) throws -> Either<ParseError, a> {
  let contents = try String(contentsOfFile: file)
  return parse(p, user, file, contents.characters as! c)
}

public func parse<a, c: Collection> (_ p: ParserClosure<a, c>, contentsOfFile file: String) throws -> Either<ParseError, a> {
  let contents = try String(contentsOfFile: file)
  return parse(p, file, contents.characters as! c)
}
