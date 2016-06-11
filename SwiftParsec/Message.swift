public struct Message<c: Collection>: CustomDebugStringConvertible {
  let pos: c.Index
  let input: Unexpected<c.Iterator.Element>
  let expected: [Expected<c.Iterator.Element>]

  init(_ pos: c.Index, _ input: Unexpected<c.Iterator.Element>, _ expected: [Expected<c.Iterator.Element>]) {
    self.pos = pos
    self.input = input
    self.expected = expected
  }

  public var debugDescription: String {
    return "parse error at (\(pos)):\n" +
            "unexpected \"\(String(reflecting: input))\"\n" +
            "expecting " + expected.map({ String(reflecting: $0) }).joined(separator: " or ")
  }
}

enum Unexpected<e>: CustomDebugStringConvertible {
  case Element(e)
  case Label(String)
  case Nothing
  case End

  var debugDescription: String {
    switch self {
    case let .Element(element): return String(reflecting: element)
    case let .Label(string): return String(reflecting: string)
    case .Nothing: return "(nothing)"
    case .End: return "end of input"
    }
  }
}

enum Expected<e>: CustomDebugStringConvertible {
  case Element(e)
  case Label(String)
  case End

  var debugDescription: String {
    switch self {
    case let .Element(element): return String(reflecting: element)
    case let .Label(string): return String(reflecting: string)
    case End: return "end of input"
    }
  }
}

func merge<c: Collection> (_ msg1: Message<c>, _ msg2: Message<c>) -> Message<c> {
  var expected = msg1.expected
  expected.append(contentsOf: msg2.expected)
  return Message(msg1.pos, msg1.input, expected)
}

func expect<c: Collection> (_ msg: Message<c>, _ exp: String) -> Message<c> {
  return Message(msg.pos, msg.input, [.Label(exp)])
}
