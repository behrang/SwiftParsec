public struct State<c: Collection>: StringLiteralConvertible {
  let input: c
  let pos: c.Index

  public init (_ input: c, _ pos: c.Index) {
    self.input = input
    self.pos = pos
  }

  public init (_ input: c) {
    self.input = input
    self.pos = input.startIndex
  }

  public init (stringLiteral value: String) {
    self.input = value.characters as! c
    self.pos = value.characters.startIndex as! c.Index
  }

  public init (extendedGraphemeClusterLiteral value: String) {
    self.input = value.characters as! c
    self.pos = value.characters.startIndex as! c.Index
  }

  public init (unicodeScalarLiteral value: String) {
    self.input = value.characters as! c
    self.pos = value.characters.startIndex as! c.Index
  }
}
