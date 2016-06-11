public enum Consumed<a, c: Collection>: CustomDebugStringConvertible {
  case Consumed(Lazy<Reply<a, c>>)
  case Empty(Reply<a, c>)

  public var debugDescription: String {
    switch self {
    case let .Consumed(reply): return "Consumed: " + String(reflecting: reply.value)
    case let .Empty(reply): return "Empty: " + String(reflecting: reply)
    }
  }
}
