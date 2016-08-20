/**
    `StringParser<a>` is an alias for `Parser<a, String.CharacterView>`.
*/
public enum StringParser<a> {
  public typealias T = Parser<a, String.CharacterView>.T
}

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
public func parse<a, c: Collection> (_ p: Parser<a, c>.T, contentsOfFile file: String) throws -> Either<ParseError, a> {
  let contents = try String(contentsOfFile: file)
  return parse(p, file, contents.characters as! c)
}

/**
    Like `many` but when collection iterator element is 'Character',
    the result will be a 'String' instead of '[Character]'.
*/
public func many<c:Collection> (_ p: Parser<c.Iterator.Element, c>.T) -> Parser<String, c>.T
  where c.Iterator.Element == Character
{
  return many(p) >>- { xs in create(String(xs)) }
}

/**
    Like `many1` but when collection iterator element is 'Character',
    the result will be a 'String' instead of '[Character]'.
*/
public func many1<c:Collection> (_ p: Parser<c.Iterator.Element, c>.T) -> Parser<String, c>.T
  where c.Iterator.Element == Character
{
  return many1(p) >>- { xs in create(String(xs)) }
}
