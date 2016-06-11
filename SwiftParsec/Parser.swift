// public typealias Parser<a, c: Collection> = (State<c>) -> Consumed<a, c>
// https://www.packtpub.com/books/content/how-make-generic-typealiases-swift
public enum Parser<a, c: Collection> {
  public typealias T = (State<c>) -> Consumed<a, c>
}

public func create<a, c: Collection> (_ x:a) -> Parser<a, c>.T {
  return { state in .Empty(.Ok(x, state, Message(state.pos, .Nothing, []))) }
}

public func satisfy<a, c: Collection where c.SubSequence == c, a == c.Iterator.Element> (_ test: (a) -> Bool) -> Parser<a, c>.T {
  return { state in
    if let head = state.input.first where test(head) {
      let tail = state.input.dropFirst(1)
      let newPos = state.input.index(after: state.pos)
      let newState = State(tail, newPos)
      return .Consumed(Lazy({ .Ok(head, newState, Message(state.pos, .Nothing, [])) }))
    } else if let head = state.input.first {
      return .Empty(.Error(Message(state.pos, .Element(head), [])))
    } else {
      return .Empty(.Error(Message(state.pos, .End, [])))
    }
  }
}

infix operator >>- { associativity left precedence 110 }
public func >>- <a, b, c: Collection> (p: Parser<a, c>.T, f: (a) -> Parser<b, c>.T) -> Parser<b, c>.T {
  return { state in
    switch p(state) {

    case let .Empty(reply1):
      switch reply1 {
      case let .Error(msg1): return .Empty(.Error(msg1))
      case let .Ok(x, inp, msg1):
        switch f(x)(inp) {
        case let .Empty(.Error(msg2)): return mergeError(msg1, msg2)
        case let .Empty(.Ok(y, _, msg2)): return mergeOk(y, inp, msg1, msg2)
        case let .Consumed(reply2):
          switch reply2.value {
          case let .Error(msg2): return .Consumed(Lazy( { .Error(merge(msg1, msg2)) } ))
          case let .Ok(y, rest, msg2): return .Consumed(Lazy( { .Ok(y, rest, merge(msg1, msg2)) } ))
          }
        }
      }

    case let .Consumed(reply1):
      return .Consumed(Lazy({
        switch reply1.value {
        case let .Error(msg1): return .Error(msg1)
        case let .Ok(x, rest, msg1):
          switch f(x)(rest) {
          case let .Empty(.Error(msg2)): return .Error(merge(msg2,msg1))
          case let .Empty(.Ok(y, inp, msg2)): return .Ok(y, inp, merge(msg1, msg2))
          case let .Consumed(reply2): return reply2.value
          }
        }
      }))
    }
  }
}

infix operator <|> { associativity left precedence 110 }
public func <|> <a, c:Collection> (p: Parser<a, c>.T, q: Parser<a, c>.T) -> Parser<a, c>.T {
  return { state in
    switch p(state) {
    case let .Empty(.Error(msg1)):
      switch q(state) {
      case let .Empty(.Error(msg2)):
        return mergeError(msg1, msg2)
      case let .Empty(.Ok(x, inp, msg2)):
        return mergeOk(x, inp, msg1, msg2)
      case let consumed:
        return consumed
      }
    case let .Empty(.Ok(x, inp, msg1)):
      switch q(state) {
      case let .Empty(.Error(msg2)):
        return mergeOk(x, inp, msg1, msg2)
      case let .Empty(.Ok(_, _, msg2)):
        return mergeOk(x, inp, msg1, msg2)
      case let consumed:
        return consumed
      }
    case let consumed: return consumed
    }
  }
}

public func attempt<a, c: Collection> (_ p: Parser<a, c>.T) -> Parser<a, c>.T {
  return { state in
    switch p(state) {
    case let .Consumed(reply):
      switch reply.value {
      case let .Error(msg): return .Empty(.Error(msg))
      default: return .Consumed(reply)
      }
    case let other: return other
    }
  }
}

infix operator <?> { associativity left precedence 110 }
public func <?> <a, c: Collection> (p: Parser<a, c>.T, exp: String) -> Parser<a, c>.T {
  return { state in
    switch p(state) {
    case let .Empty(.Error(msg)): return .Empty(.Error(expect(msg, exp)))
    case let .Empty(.Ok(x, st, msg)): return .Empty(.Ok(x, st, expect(msg, exp)))
    case let other: return other
    }
  }
}
