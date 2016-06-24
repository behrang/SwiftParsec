public func parse<a, c: Collection> (_ p: Parser<a, c>.T, file: String) throws -> Either<ParseError, a> {
  let contents = try String(contentsOfFile: file)
  return parse(p, file, contents.characters as! c)
}
