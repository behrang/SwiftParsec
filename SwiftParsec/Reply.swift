// TODO: Change ParseError in Reply to Lazy<ParseError>

public enum Reply<a, c: Collection>: CustomDebugStringConvertible {
  case Ok(a, State<c>, ParseError)
  case Error(ParseError)

  public var debugDescription: String {
    switch self {
    case let .Ok(a, _, _): return "Ok: " + String(reflecting: a)
    case let .Error(err): return "Error: " + String(reflecting: err)
    }
  }
}

func mergeOk<a, c: Collection> (_ x: a, _ inp: State<c>, _ err1: ParseError, _ err2: ParseError) -> Consumed<a, c> {
  return .Empty(.Ok(x, inp, merge(err1, err2)))
}

func mergeError<a, c: Collection> (_ err1: ParseError, _ err2: ParseError) -> Consumed<a, c> {
  return .Empty(.Error(merge(err1, err2)))
}

func merge (_ err1: ParseError, _ err2: ParseError) -> ParseError {
  var messages = err1.messages
  messages.append(contentsOf: err2.messages)
  return ParseError(err1.pos, messages)
}
