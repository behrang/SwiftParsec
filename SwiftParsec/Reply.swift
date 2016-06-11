// TODO: Change Message in Reply to Lazy<Message>

public enum Reply<a, c: Collection>: CustomDebugStringConvertible {
  case Ok(a, State<c>, Message<c>)
  case Error(Message<c>)

  public var debugDescription: String {
    switch self {
    case let .Ok(a, _, _): return "Ok: " + String(reflecting: a)
    case let .Error(msg): return "Error: " + String(reflecting: msg)
    }
  }
}

func mergeOk<a, c: Collection> (_ x: a, _ inp: State<c>, _ msg1: Message<c>, _ msg2: Message<c>) -> Consumed<a, c> {
  return .Empty(.Ok(x, inp, merge(msg1, msg2)))
}

func mergeError<a, c: Collection> (_ msg1: Message<c>, _ msg2: Message<c>) -> Consumed<a, c> {
  return .Empty(.Error(merge(msg1, msg2)))
}
