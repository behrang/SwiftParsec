/**
    `StringParser<a>` is an alias for `Parser<a, String.CharacterView>`.
*/
public typealias StringParser<a> = (State<String.CharacterView>) -> Consumed<a, String.CharacterView>

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
public func parse<a, c: Collection> (_ p: Parser<a, c>, contentsOfFile file: String) throws -> Either<ParseError, a> {
  let contents = try String(contentsOfFile: file)
  return parse(p, file, contents.characters as! c)
}
