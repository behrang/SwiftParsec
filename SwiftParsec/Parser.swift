public func satisfy<a, c: Collection where c.SubSequence == c, a == c.Iterator.Element> (_ test: (a) -> Bool) -> Parser<a, c>.T {
  return { state in
    if let head = state.input.first where test(head) {
      let tail = state.input.dropFirst()
      var newPos = state.pos
      newPos.update(String(head))
      let newState = State(tail, newPos)
      return .consumed(Lazy{ .ok(head, newState, ParseError(state.pos)) })
    } else if let head = state.input.first {
      return .empty(.error(ParseError(state.pos, [.sysUnExpect(String(head))])))
    } else {
      return .empty(.error(ParseError(state.pos, [.sysUnExpect("")])))
    }
  }
}
