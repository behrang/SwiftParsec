/**
    Textual source positions.
    Source positions: a file name, a line and a column
    upper left is (1,1)
*/
public struct SourcePos: CustomStringConvertible, Comparable {
  public var name: String
  public var line: Int
  public var column: Int

  init (_ name: String, _ line: Int, _ column: Int) {
    self.name = name
    self.line = line
    self.column = column
  }

  init (_ name: String) {
    self.name = name
    line = 1
    column = 1
  }

  init () {
    name = ""
    line = 1
    column = 1
  }

  mutating func incrementLine (_ n: Int = 1) {
    line += n
    column = 1
  }

  mutating func incrementColumn (_ n: Int = 1) {
    column += n
  }

  mutating func setName (_ name: String) {
    self.name = name
  }

  mutating func setLine (_ n: Int) {
    line = n
  }

  mutating func setColumn (_ n: Int) {
    column = n
  }

  /**
      Updates the source position by calling `update` on every character.
  */
  mutating func update (_ s: String) {
    s.characters.forEach { update($0) }
  }

  mutating func update (_ cs: [Character]) {
    cs.forEach { update($0) }
  }

  /**
      Update a source position given a character. If the character is a
      newline (`\n`) the line number is incremented by 1. If the character
      is a tab (`\t`) the column number is incremented to the nearest 8'th
      column. In all other cases, the column is incremented by 1.
  */
  mutating func update(_ character: Character) {
    switch character {
    case "\n": incrementLine()
    case "\t": setColumn(column + 8 - ((column - 1) % 8))
    default: incrementColumn()
    }
  }

  public var description: String {
    var result = ""
    if !name.isEmpty {
      result = "\"\(name)\" "
    }
    result += "(line \(line), column \(column))"
    return result
  }
}

public func == (lhs: SourcePos, rhs: SourcePos) -> Bool {
  return lhs.line == rhs.line && lhs.column == rhs.column
}

public func < (lhs: SourcePos, rhs: SourcePos) -> Bool {
  return lhs.line < rhs.line || lhs.line == rhs.line && lhs.column < rhs.column
}
