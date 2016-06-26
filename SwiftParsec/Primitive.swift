/*
    The primitive parser combinators.
*/

// public typealias Parser<a, c: Collection> = (State<c>) -> Consumed<a, c>
// https://www.packtpub.com/books/content/how-make-generic-typealiases-swift
public enum Parser<a, c: Collection> {
  public typealias T = (State<c>) -> Consumed<a, c>
}

public enum Consumed<a, c: Collection> {
  case consumed(Lazy<Reply<a, c>>)
  case empty(Reply<a, c>)

  func map<b> (_ f: (a) -> b) -> Consumed<b, c> {
    switch self {
    case let .consumed(reply): return .consumed(Lazy { reply.value.map(f) })
    case let .empty(reply): return .empty(reply.map(f))
    }
  }
}

// TODO: Change ParseError in Reply to Lazy<ParseError>
public enum Reply<a, c: Collection> {
  case ok(a, State<c>, ParseError)
  case error(ParseError)

  func map<b> (_ f: (a) -> b) -> Reply<b, c> {
    switch self {
    case let .ok(x, s, err): return .ok(f(x), s, err)
    case let .error(err): return .error(err)
    }
  }
}

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

public class Lazy<x> {
  let closure: () -> x
  var val: x?

  init (_ c: () -> x) {
    closure = c
  }

  var value: x {
    if val == nil {
      val = closure()
    }
    return val!
  }
}

public enum Either<l, r> {
  case left(l)
  case right(r)
}

public func create<a, c: Collection> (_ x: a) -> Parser<a, c>.T {
  return parserReturn(x)
}

infix operator >>- { associativity left precedence 107 }
public func >>- <a, b, c: Collection> (p: Parser<a, c>.T, f: (a) -> Parser<b, c>.T) -> Parser<b, c>.T {
  return parserBind(p, f)
}

infix operator >>> { associativity left precedence 107 }
public func >>> <a, b, c: Collection> (p: Parser<a, c>.T, q: Parser<b, c>.T) -> Parser<b, c>.T {
  return p >>- { _ in q }
}

infix operator <<< { associativity left precedence 107 }
public func <<< <a, b, c: Collection> (p: Parser<a, c>.T, q: Parser<b, c>.T) -> Parser<a, c>.T {
  return p >>- { x in q >>> create(x) }
}

/**
    The parser `unexpected(msg)` always fails with an unexpected error
    message `msg` without consuming any input.

    The parsers `fail`, `<?>` and `unexpected` are the three parsers
    used to generate error messages. Of these, only `<?>` is commonly
    used. For an example of the use of `unexpected`, see the definition
    of `notFollowedBy`.
*/
public func unexpected<a, c: Collection> (_ msg: String) -> Parser<a, c>.T {
  return { state in
    .empty(.error(ParseError(state.pos, [.unExpect(msg)])))
  }
}

public func fail<a, c: Collection> (_ msg: String) -> Parser<a, c>.T {
  return parserFail(msg)
}

public func parserReturn<a, c: Collection> (_ x: a) -> Parser<a, c>.T {
  return { state in .empty(.ok(x, state, unknownError(state))) }
}

public func parserBind<a, b, c: Collection> (_ p: Parser<a, c>.T, _ f: (a) -> Parser<b, c>.T) -> Parser<b, c>.T {
  return { state in
    switch p(state) {

    case let .empty(reply1):
      switch reply1 {
      case let .error(msg1): return .empty(.error(msg1))
      case let .ok(x, inp, msg1):
        switch f(x)(inp) {
        case let .empty(.error(msg2)): return .empty(.error(mergeError(msg1, msg2)))
        case let .empty(.ok(y, _, msg2)): return .empty(.ok(y, inp, mergeError(msg1, msg2)))
        case let .consumed(reply2):
          switch reply2.value {
          case let .error(msg2): return .consumed(Lazy{ .error(mergeError(msg1, msg2)) })
          case let .ok(y, rest, msg2): return .consumed(Lazy{ .ok(y, rest, mergeError(msg1, msg2)) })
          }
        }
      }

    case let .consumed(reply1):
      return .consumed(Lazy{
        switch reply1.value {
        case let .error(msg1): return .error(msg1)
        case let .ok(x, rest, msg1):
          switch f(x)(rest) {
          case let .empty(.error(msg2)): return .error(mergeError(msg2,msg1))
          case let .empty(.ok(y, inp, msg2)): return .ok(y, inp, mergeError(msg1, msg2))
          case let .consumed(reply2): return reply2.value
          }
        }
      })
    }
  }
}

public func parserFail<a, c: Collection> (_ msg: String) -> Parser<a, c>.T {
  return { state in
    .empty(.error(ParseError(state.pos, .message(msg))))
  }
}

/**
    `parserZero` always fails without consuming any input.
*/
public func parserZero<a, c: Collection> () -> Parser<a, c>.T {
  return { state in
    .empty(.error(unknownError(state)))
  }
}

public func parserPlus<a, c: Collection> (_ p: Parser<a, c>.T, _ q: Parser<a, c>.T) -> Parser<a, c>.T {
  return { state in
    switch p(state) {
    case let .empty(.error(msg1)):
      switch q(state) {
      case let .empty(.error(msg2)): return .empty(.error(mergeError(msg1, msg2)))
      case let .empty(.ok(x, inp, msg2)): return .empty(.ok(x, inp, mergeError(msg1, msg2)))
      case let consumed: return consumed
      }
    case let .empty(.ok(x, inp, msg1)):
      switch q(state) {
      case let .empty(.error(msg2)): return .empty(.ok(x, inp, mergeError(msg1, msg2)))
      case let .empty(.ok(_, _, msg2)): return .empty(.ok(x, inp, mergeError(msg1, msg2)))
      case let consumed: return consumed
      }
    case let consumed: return consumed
    }
  }
}

/**
    The parser `p <?> msg` behaves as parser `p`, but whenever the
    parser `p` fails *without consuming any input*, it replaces expect
    error messages with the expect error message `msg`.

    This is normally used at the end of a set alternatives where we want
    to return an error message in terms of a higher level construct
    rather than returning all possible characters.
*/
infix operator <?> { precedence 105 }
public func <?> <a, c: Collection> (p: Parser<a, c>.T, msg: String) -> Parser<a, c>.T {
  return label(p, msg)
}

public func label<a, c: Collection> (_ p: Parser<a, c>.T, _ msg: String) -> Parser<a, c>.T {
  return labels(p, [msg])
}

public func labels<a, c: Collection> (_ p: Parser<a, c>.T, _ msgs: [String]) -> Parser<a, c>.T {
  return { state in
    switch p(state) {
    case let .empty(.error(err)): return .empty(.error(setExpectErrors(err, msgs)))
    case let .empty(.ok(x, st, err)): return .empty(.ok(x, st, setExpectErrors(err, msgs)))
    case let other: return other
    }
  }
}

func setExpectErrors (_ err: ParseError, _ msgs: [String]) -> ParseError {
  var error = err
  if let head = msgs.first {
    let tail = msgs.dropFirst()
    error.setMessage(.expect(head))
    tail.forEach { msg in error.addMessage(.expect(msg)) }
  } else {
    error.setMessage(.expect(""))
  }
  return error
}

/**
    This combinator implements choice. The parser `p <|> q` first
    applies `p`. If it succeeds, the value of `p` is returned. If `p`
    fails *without consuming any input*, parser `q` is tried.

    The parser is called *predictive* since `q` is only tried when
    parser `p` didn't consume any input (i.e.. the look ahead is 1).
    This non-backtracking behaviour allows for both an efficient
    implementation of the parser combinators and the generation of good
    error messages.
*/
infix operator <|> { associativity right precedence 106 }
public func <|> <a, c:Collection> (p: Parser<a, c>.T, q: Parser<a, c>.T) -> Parser<a, c>.T {
  return parserPlus(p, q)
}

/**
    The parser `attempt(p)` behaves like parser `p`, except that it
    pretends that it hasn't consumed any input when an error occurs.

    This combinator is used whenever arbitrary look ahead is needed.
    Since it pretends that it hasn't consumed any input when `p` fails,
    the `<|>` combinator will try its second alternative even when the
    first parser failed while consuming input.

    The `attempt` combinator can for example be used to distinguish
    identifiers and reserved words. Both reserved words and identifiers
    are a sequence of letters. Whenever we expect a certain reserved
    word where we can also expect an identifier we have to use the `attempt`
    combinator. Suppose we write:

        expr        = letExpr() <|> identifier() <?> "expression"

        func letExpr<a, c: Collection> () -> Parser<a, c>.T {
          return string("let") ...
        }
        func identifier<a, c: Collection> () -> Parser<a, c>.T {
          return many1(letter())
        }

    If the user writes "lexical", the parser fails with: `unexpected
    'x', expecting 't' in "let"`. Indeed, since the `<|>` combinator
    only tries alternatives when the first alternative hasn't consumed
    input, the `identifier` parser is never tried (because the prefix
    "le" of the `string "let"` parser is already consumed). The
    right behaviour can be obtained by adding the `attempt` combinator:

        expr        = letExpr() <|> identifier() <?> "expression"

        func letExpr<a, c: Collection> () -> Parser<a, c>.T {
          return attempt(string("let")) ...
        }
        func identifier<a, c: Collection> () -> Parser<a, c>.T {
          return many1(letter())
        }
*/
public func attempt<a, c: Collection> (_ p: Parser<a, c>.T) -> Parser<a, c>.T {
  return { state in
    switch p(state) {
    case let .consumed(reply):
      switch reply.value {
      case let .error(msg): return .empty(.error(msg))
      default: return .consumed(reply)
      }
    case let other: return other
    }
  }
}

/**
    `lookAhead(p)` parses `p` without consuming any input.

    If `p` fails and consumes some input, so does `lookAhead`. Combine with
    `attempt` if this is undesirable.
*/
public func lookAhead<a, c: Collection> (_ p: Parser<a, c>.T) -> Parser<a, c>.T {
  return { state in
    switch p(state) {
    case let .consumed(reply):
      switch reply.value {
      case let .ok(x, st, err): return .empty(.ok(x, st, err))
      default: return .consumed(reply)
      }
    case let other: return other
    }
  }
}

/**
    The parser `token(showTok, posFromTok, testTok)` accepts a token `t`
    with result `x` when the function `testTok(t)` returns `.some(x)`. The
    source position of the `t` should be returned by `posFromTok(t)` and
    the token can be shown using `showTok(t)`.

    This combinator is expressed in terms of `tokenPrim`.
    It is used to accept user defined token streams. For example,
    suppose that we have a stream of basic tokens tupled with source
    positions. We can then define a parser that accepts single tokens as:

        func myToken<a, c: Collection> (_ x: c.Iterator.Element) -> Parser<a, c>.T {
          let showToken = { (pos, t) in String(t) }
          let posFromTok = { (pos, t) in pos }
          let testTok = { (pos, t) in if x == t { return t } else { return nil } }
          return token(showTok, posFromTok, testTok)
        }
*/
public func token<a, c: Collection where c.SubSequence == c> (_ showToken: (c.Iterator.Element) -> String, _ tokenPosition: (c.Iterator.Element) -> SourcePos, _ test: (c.Iterator.Element) -> a?) -> Parser<a, c>.T {
  let nextPosition: (SourcePos, c.Iterator.Element, c) -> SourcePos = { _, current, rest in
    if let next = rest.first {
      return tokenPosition(next)
    } else {
      return tokenPosition(current)
    }
  }
  return tokenPrim(showToken, nextPosition, test)
}

public func tokens<a: Equatable, c: Collection where a == c.Iterator.Element, c.SubSequence == c> (_ showTokens: ([c.Iterator.Element]) -> String, _ nextPosition: (SourcePos, [c.Iterator.Element]) -> SourcePos, _ tts: [c.Iterator.Element]) -> Parser<[a], c>.T {
  if let tok = tts.first {
    let toks = tts.dropFirst()
    return { state in
      let errEof = ParseError(state.pos, [.sysUnExpect(""), .expect(showTokens(tts))])
      let errExpect = { x in ParseError(state.pos, [.sysUnExpect(showTokens([x])), .expect(showTokens(tts))]) }
      func walk (_ restToks: ArraySlice<c.Iterator.Element>, _ restInput: c) -> Consumed<[a], c> {
        if let t = restToks.first {
          let ts = restToks.dropFirst()
          if let x = restInput.first {
            let xs = restInput.dropFirst()
            if t == x { return walk(ts, xs) }
            else { return .consumed(Lazy{ .error(errExpect(x)) })}
          } else {
            return .consumed(Lazy{ .error(errEof) })
          }
        } else {
          let newPos = nextPosition(state.pos, tts)
          let newState = State(restInput, newPos)
          return .consumed(Lazy{ .ok(tts, newState, unknownError(newState)) })
        }
      }

      if let x = state.input.first {
        let xs = state.input.dropFirst()
        if tok == x { return walk(toks, xs) }
        else { return .empty(.error(errExpect(x)))}
      } else {
        return .empty(.error(errEof))
      }
    }
  } else {
    return { state in .empty(.ok([], state, unknownError(state))) }
  }
}

/**
    The parser `tokenPrim(showTok, nextPos, testTok)` accepts a token `t`
    with result `x` when the function `testTok(t)` returns `.some(x)`. The
    token can be shown using `showTok(t)`. The position of the *next*
    token should be returned when `nextPos` is called with the current
    source position `pos`, the current token `t` and the rest of the
    tokens `toks`, `nextPos(pos, t, toks)`.

    This is the most primitive combinator for accepting tokens. For
    example, the `char` parser could be implemented as:

        func char<Character, c: Collection where c.Iterator.Element == Character> (c: Character) -> Parser<Character, c>.T {
          let showChar = { x: Character in "\"\(x)\"" }
          let testChar = { x: Character in if x == c { return x } else { return nil } }
          let nextPos = { pos: SourcePos, x: Character, xs: c in updatePos(pos, x) }
          return tokenPrim(showChar, nextPos, testChar)
        }
*/
public func tokenPrim<a, c: Collection where c.SubSequence == c> (_ showToken: (c.Iterator.Element) -> String, _ nextPosition: (SourcePos, c.Iterator.Element, c) -> SourcePos, _ test: (c.Iterator.Element) -> a?) -> Parser<a, c>.T {
  return { state in
    if let head = state.input.first, x = test(head) {
      let tail = state.input.dropFirst()
      let newPos = nextPosition(state.pos, head, tail)
      let newState = State(tail, newPos)
      return .consumed(Lazy{ .ok(x, newState, unknownError(newState)) })
    } else if let head = state.input.first {
      return .empty(sysUnExpectError(showToken(head), state.pos))
    } else {
      return .empty(sysUnExpectError("", state.pos))
    }
  }
}

/**
    `many(p)` applies the parser `p` *zero* or more times. Returns a
    list of the returned values of `p`.

        func identifier<a, c: Collection> () -> Parser<[a], c>.T {
          return letter() >>- { c in
            many(alphaNum() <|> char("_")) >>- { cs in
              var r = cs
              r.prepend(c)
              return create(r)
            }
          }
        }
*/
public func many<a, c: Collection> (_ p: Parser<a, c>.T) -> Parser<[a], c>.T {
  return manyAccum(append, p)
}

func append<a> (_ next: a, _ list: [a]) -> [a] {
  var r = list
  r.append(next)
  return r
}

/**
    `skipMany(p)` applies the parser `p` *zero* or more times, skipping
    its result.

        func spaces<c: Collection> () -> Parser<(), c>.T {
          return skipMany(space())
        }
*/
public func skipMany<a, c: Collection> (_ p: Parser<a, c>.T) -> Parser<(), c>.T {
  return manyAccum({ _, _ in [] }, p) >>> create(())
}

public func manyAccum<a, c: Collection> (_ acc: (a, [a]) -> [a], _ p: Parser<a, c>.T) -> Parser<[a], c>.T {
  let msg = "Parsec many: combinator 'many' is applied to a parser that accepts an empty string."
  func walk (_ xs: [a], _ x: a, _ state: State<c>, _ err: ParseError) -> Consumed<[a], c> {
    switch p(state) {
    case let .consumed(reply):
      switch reply.value {
      case let .error(err): return .consumed(Lazy{ .error(err) })
      case let .ok(y, st, e): return walk(acc(x, xs), y, st, e)
      }
    case let .empty(reply):
      switch reply {
      case let .error(err): return .consumed(Lazy{ .ok(acc(x, xs), state, err) })
      case .ok: fatalError(msg)
      }
    }
  }
  return { state in
    switch p(state) {
    case let .consumed(reply):
      switch reply.value {
      case let .error(err): return .consumed(Lazy{ .error(err) })
      case let .ok(x, st, err): return walk([], x, st, err)
      }
    case let .empty(reply):
      switch reply {
      case let .error(err): return .empty(.ok([], state, err))
      case .ok: fatalError(msg)
      }
    }
  }
}

public func runP<a, c: Collection> (_ p: Parser<a, c>.T, _ name: String, _ input: c) -> Either<ParseError, a> {
  switch p(State(input, SourcePos(name))) {
  case let .consumed(reply):
    switch reply.value {
    case let .ok(x, _, _): return .right(x)
    case let .error(err): return .left(err)
    }
  case let .empty(reply):
    switch reply {
    case let .ok(x, _, _): return .right(x)
    case let .error(err): return .left(err)
    }
  }
}

/**
    The most general way to run a parser. `runParser(p, filePath, input)`
    runs parser `p` on the input list of tokens `input`,
    obtained from source `filePath`.
    The `filePath` is only used in error messages and may be the empty
    string. Returns either a 'ParseError' ('left') or a
    value of type `a` ('right').

        func parseFromFile<a, c: Collection> (_ p: Parser<a, c>.T, _ fileUrl: String) -> Either<ParseError, a> {
          let input = String(contentsOf: fileUrl)
          return runParser(p, fileUrl, input)
        }
*/
public func runParser<a, c: Collection> (_ p: Parser<a, c>.T, _ name: String, _ input: c) -> Either<ParseError, a> {
  return runP(p, name, input)
}

/**
    `parse(p, filePath, input)` runs a parser `p`.
    The `filePath` is only used in error messages and may be the
    empty string. Returns either a 'ParseError' ('left')
    or a value of type `a` ('right').

        func main () {
          switch parse(numbers(), "", "11, 2, 43") {
          case let .left(err): print(err)
          case let .right(xs): print(xs.reduce(0, combine: +))
          }
        }

        func numbers<c: Collection> () -> Parser<[Int], c>.T {
          return commaSep(integer())
        }
*/
public func parse<a, c: Collection> (_ p: Parser<a, c>.T, _ name: String, _ input: c) -> Either<ParseError, a> {
  return runP(p, name, input)
}

public func parseTest<a, c: Collection> (_ p: Parser<a, c>.T, _ input: c) {
  switch parse(p, "", input) {
  case let .left(err): print(err)
  case let .right(x): print(x)
  }
}

/**
    Returns the current source position. See also 'SourcePos'.
*/
public func getPosition<c: Collection> () -> Parser<SourcePos, c>.T {
  return getParserState() >>- { state in
    create(state.pos)
  }
}

/**
    Returns the current input.
*/
public func getInput<c: Collection> () -> Parser<c, c>.T {
  return getParserState() >>- { state in
    create(state.input)
  }
}

/**
    `setPosition(pos)` sets the current source position to `pos`.
*/
public func setPosition<c: Collection> (_ pos: SourcePos) -> Parser<(), c>.T {
  return updateParserState { state in State(state.input, pos) } >>> create(())
}

/**
    `setInput(input)` continues parsing with `input`. The 'getInput' and
    `setInput` functions can for example be used to deal with #include
    files.
*/
public func setInput<c: Collection> (_ input: c) -> Parser<(), c>.T {
  return updateParserState { state in State(input, state.pos) } >>> create(())
}

/**
    Returns the full parser state as a 'State' record.
*/
public func getParserState<c: Collection> () -> Parser<State<c>, c>.T {
  return updateParserState { state in state }
}

/**
    `setParserState(state)` set the full parser state to `state`.
*/
public func setParserState<c: Collection> (_ state: State<c>) -> Parser<State<c>, c>.T {
  return updateParserState { _ in state }
}

/**
    `updateParserState(f)` applies function `f` to the parser state.
*/
public func updateParserState<c: Collection> (_ f: (State<c>) -> State<c>) -> Parser<State<c>, c>.T {
  return { state in
    let newState = f(state)
    return .empty(.ok(newState, newState, unknownError(newState)))
  }
}
