public struct State<c: Collection> {
  let input: c
  let pos: SourcePos

  init (_ input: c, _ pos: SourcePos) {
    self.input = input
    self.pos = pos
  }

  public init (_ input: c) {
    self.input = input
    self.pos = SourcePos()
  }
}
