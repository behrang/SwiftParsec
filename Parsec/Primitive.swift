/*
    The primitive parser combinators.
*/

public typealias Parser<a, c: Collection> = (State<c, ()>) -> Consumed<a, c, ()>
public typealias ParserClosure<a, c: Collection> = () -> (State<c, ()>) -> Consumed<a, c, ()>
public typealias UserParser<a, c: Collection, u> = (State<c, u>) -> Consumed<a, c, u>
public typealias UserParserClosure<a, c: Collection, u> = () -> (State<c, u>) -> Consumed<a, c, u>

public enum Consumed<a, c: Collection, u> {
  case consumed(Lazy<Reply<a, c, u>>)
  case empty(Reply<a, c, u>)

  func map<b> (_ f: @escaping (a) -> b) -> Consumed<b, c, u> {
    switch self {
    case let .consumed(reply): return .consumed(Lazy{ reply.value.map(f) })
    case let .empty(reply): return .empty(reply.map(f))
    }
  }
}

public enum Reply<a, c: Collection, u> {
  case ok(a, State<c, u>, Lazy<ParseError>)
  case error(Lazy<ParseError>)

  func map<b> (_ f: (a) -> b) -> Reply<b, c, u> {
    switch self {
    case let .ok(x, s, err): return .ok(f(x), s, err)
    case let .error(err): return .error(err)
    }
  }
}

public struct State<c: Collection, u> {
  let input: c
  let pos: SourcePos
  let user: u

  init (_ input: c, _ pos: SourcePos, _ user: u) {
    self.input = input
    self.pos = pos
    self.user = user
  }
}

public class Lazy<x> {
  let closure: () -> x
  var val: x?

  init (_ c: @escaping () -> x) {
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

public func create<a, c: Collection, u> (_ x: a) -> UserParserClosure<a, c, u> {
  return parserReturn(x)
}

precedencegroup BindPrecedence {
  associativity: left
  higherThan: ChoicePrecedence
}

precedencegroup ChoicePrecedence {
  associativity: right
  higherThan: LabelPrecedence
}

precedencegroup LabelPrecedence {
}

infix operator >>- : BindPrecedence
public func >>- <a, b, c: Collection, u> (p: @escaping UserParserClosure<a, c, u>, f: @escaping (a) -> UserParserClosure<b, c, u>) -> UserParserClosure<b, c, u> {
  return parserBind(p, f)
}

infix operator >>> : BindPrecedence
public func >>> <a, b, c: Collection, u> (p: @escaping UserParserClosure<a, c, u>, q: @escaping UserParserClosure<b, c, u>) -> UserParserClosure<b, c, u> {
  return p >>- { _ in q }
}

infix operator <<< : BindPrecedence
public func <<< <a, b, c: Collection, u> (p: @escaping UserParserClosure<a, c, u>, q: @escaping UserParserClosure<b, c, u>) -> UserParserClosure<a, c, u> {
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
public func unexpected<a, c: Collection, u> (_ msg: String) -> UserParserClosure<a, c, u> {
  return {{ state in
    .empty(.error(Lazy{ ParseError(state.pos, [.unExpect(msg)]) }))
  }}
}

public func fail<a, c: Collection, u> (_ msg: String) -> UserParserClosure<a, c, u> {
  return parserFail(msg)
}

public func parserReturn<a, c: Collection, u> (_ x: a) -> UserParserClosure<a, c, u> {
  return {{ state in .empty(.ok(x, state, Lazy{ unknownError(state) })) }}
}

public func parserBind<a, b, c: Collection, u> (_ p: @escaping UserParserClosure<a, c, u>, _ f: @escaping (a) -> UserParserClosure<b, c, u>) -> UserParserClosure<b, c, u> {
  return {{ state in
    switch p()(state) {

    case let .empty(reply1):
      switch reply1 {
      case let .error(msg1): return .empty(.error(msg1))
      case let .ok(x, inp, msg1):
        switch f(x)()(inp) {
        case let .empty(.error(msg2)): return .empty(.error(Lazy{ mergeError(msg1.value, msg2.value) }))
        case let .empty(.ok(y, _, msg2)): return .empty(.ok(y, inp, Lazy{ mergeError(msg1.value, msg2.value) }))
        case let .consumed(reply2):
          switch reply2.value {
          case let .error(msg2): return .consumed(Lazy{ .error(Lazy{ mergeError(msg1.value, msg2.value) }) })
          case let .ok(y, rest, msg2): return .consumed(Lazy{ .ok(y, rest, Lazy{ mergeError(msg1.value, msg2.value) }) })
          }
        }
      }

    case let .consumed(reply1):
      return .consumed(Lazy{
        switch reply1.value {
        case let .error(msg1): return .error(msg1)
        case let .ok(x, rest, msg1):
          switch f(x)()(rest) {
          case let .empty(.error(msg2)): return .error(Lazy{ mergeError(msg2.value,msg1.value) })
          case let .empty(.ok(y, inp, msg2)): return .ok(y, inp, Lazy{ mergeError(msg1.value, msg2.value) })
          case let .consumed(reply2): return reply2.value
          }
        }
      })
    }
  }}
}

public func parserFail<a, c: Collection, u> (_ msg: String) -> UserParserClosure<a, c, u> {
  return {{ state in
    .empty(.error(Lazy{ ParseError(state.pos, .message(msg)) }))
  }}
}

/**
    `parserZero` always fails without consuming any input.
*/
public func parserZero<a, c: Collection, u> () -> UserParser<a, c, u> {
  return { state in
    .empty(.error(Lazy{ unknownError(state) }))
  }
}

public func parserPlus<a, c: Collection, u> (_ p: @escaping UserParserClosure<a, c, u>, _ q: @escaping UserParserClosure<a, c, u>) -> UserParserClosure<a, c, u> {
  return {{ state in
    switch p()(state) {
    case let .empty(.error(msg1)):
      switch q()(state) {
      case let .empty(.error(msg2)): return .empty(.error(Lazy{ mergeError(msg1.value, msg2.value) }))
      case let .empty(.ok(x, inp, msg2)): return .empty(.ok(x, inp, Lazy{ mergeError(msg1.value, msg2.value) }))
      case let consumed: return consumed
      }
    case let .empty(.ok(x, inp, msg1)):
      switch q()(state) {
      case let .empty(.error(msg2)): return .empty(.ok(x, inp, Lazy{ mergeError(msg1.value, msg2.value) }))
      case let .empty(.ok(_, _, msg2)): return .empty(.ok(x, inp, Lazy{ mergeError(msg1.value, msg2.value) }))
      case let consumed: return consumed
      }
    case let consumed: return consumed
    }
  }}
}

/**
    The parser `p <?> msg` behaves as parser `p`, but whenever the
    parser `p` fails *without consuming any input*, it replaces expect
    error messages with the expect error message `msg`.

    This is normally used at the end of a set alternatives where we want
    to return an error message in terms of a higher level construct
    rather than returning all possible characters.
*/
infix operator <?> : LabelPrecedence
public func <?> <a, c: Collection, u> (p: @escaping UserParserClosure<a, c, u>, msg: String) -> UserParserClosure<a, c, u> {
  return label(p, msg)
}

public func label<a, c: Collection, u> (_ p: @escaping UserParserClosure<a, c, u>, _ msg: String) -> UserParserClosure<a, c, u> {
  return labels(p, [msg])
}

public func labels<a, c: Collection, u> (_ p: @escaping UserParserClosure<a, c, u>, _ msgs: [String]) -> UserParserClosure<a, c, u> {
  return {{ state in
    switch p()(state) {
    case let .empty(.error(err)): return .empty(.error(Lazy{ setExpectErrors(err.value, msgs) }))
    case let .empty(.ok(x, st, err)): return .empty(.ok(x, st, Lazy{ setExpectErrors(err.value, msgs) }))
    case let other: return other
    }
  }}
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
infix operator <|> : ChoicePrecedence
public func <|> <a, c:Collection, u> (p: @escaping UserParserClosure<a, c, u>, q: @escaping UserParserClosure<a, c, u>) -> UserParserClosure<a, c, u> {
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

        func letExpr<a, c: Collection> () -> Parser<a, c> {
          return string("let") ...
        }
        func identifier<a, c: Collection> () -> Parser<a, c> {
          return many1(letter())
        }

    If the user writes "lexical", the parser fails with: `unexpected
    'x', expecting 't' in "let"`. Indeed, since the `<|>` combinator
    only tries alternatives when the first alternative hasn't consumed
    input, the `identifier` parser is never tried (because the prefix
    "le" of the `string "let"` parser is already consumed). The
    right behaviour can be obtained by adding the `attempt` combinator:

        expr        = letExpr() <|> identifier() <?> "expression"

        func letExpr<a, c: Collection> () -> Parser<a, c> {
          return attempt(string("let")) ...
        }
        func identifier<a, c: Collection> () -> Parser<a, c> {
          return many1(letter())
        }
*/
public func attempt<a, c: Collection, u> (_ p: @escaping UserParserClosure<a, c, u>) -> UserParserClosure<a, c, u> {
  return {{ state in
    switch p()(state) {
    case let .consumed(reply):
      switch reply.value {
      case let .error(msg): return .empty(.error(msg))
      default: return .consumed(reply)
      }
    case let other: return other
    }
  }}
}

/**
    `lookAhead(p)` parses `p` without consuming any input.

    If `p` fails and consumes some input, so does `lookAhead`. Combine with
    `attempt` if this is undesirable.
*/
public func lookAhead<a, c: Collection, u> (_ p: @escaping UserParserClosure<a, c, u>) -> UserParserClosure<a, c, u> {
  return {{ state in
    switch p()(state) {
    case let .consumed(reply):
      switch reply.value {
      case let .ok(x, _, _): return .empty(.ok(x, state, Lazy{ unknownError(state) }))
      default: return .consumed(reply)
      }
    case let .empty(reply):
      switch reply {
      case let .ok(x, _, _): return .empty(.ok(x, state, Lazy{ unknownError(state) }))
      default: return .empty(reply)
      }
    }
  }}
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

        func myToken<a, c: Collection> (_ x: c.Iterator.Element) -> Parser<a, c> {
          let showToken = { (pos, t) in String(t) }
          let posFromTok = { (pos, t) in pos }
          let testTok = { (pos, t) in if x == t { return t } else { return nil } }
          return token(showTok, posFromTok, testTok)
        }
*/
public func token<a, c: Collection, u> (_ showToken: @escaping (c.Iterator.Element) -> String, _ tokenPosition: @escaping (c.Iterator.Element) -> SourcePos, _ test: @escaping (c.Iterator.Element) -> a?) -> UserParserClosure<a, c, u>
  where c.SubSequence == c
{
  let nextPosition: (SourcePos, c.Iterator.Element, c) -> SourcePos = { _, current, rest in
    if let next = rest.first {
      return tokenPosition(next)
    } else {
      return tokenPosition(current)
    }
  }
  return tokenPrim(showToken, nextPosition, test)
}

public func tokens<c: Collection, u> (_ showTokens: @escaping ([c.Iterator.Element]) -> String, _ nextPosition: @escaping (SourcePos, [c.Iterator.Element]) -> SourcePos, _ tts: [c.Iterator.Element]) -> UserParserClosure<[c.Iterator.Element], c, u>
  where c.Iterator.Element: Equatable, c.SubSequence == c
{
  if let tok = tts.first {
    let toks = tts.dropFirst()
    return {{ state in
      let errEof = ParseError(state.pos, [.sysUnExpect(""), .expect(showTokens(tts))])
      let errExpect = { x in ParseError(state.pos, [.sysUnExpect(showTokens([x])), .expect(showTokens(tts))]) }
      func walk (_ restToks: ArraySlice<c.Iterator.Element>, _ restInput: c) -> Consumed<[c.Iterator.Element], c, u> {
        if let t = restToks.first {
          let ts = restToks.dropFirst()
          if let x = restInput.first {
            let xs = restInput.dropFirst()
            if t == x { return walk(ts, xs) }
            else { return .consumed(Lazy{ .error(Lazy{ errExpect(x) }) })}
          } else {
            return .consumed(Lazy{ .error(Lazy{ errEof }) })
          }
        } else {
          let newPos = nextPosition(state.pos, tts)
          let newState = State(restInput, newPos, state.user)
          return .consumed(Lazy{ .ok(tts, newState, Lazy{ unknownError(newState) }) })
        }
      }

      if let x = state.input.first {
        let xs = state.input.dropFirst()
        if tok == x { return walk(toks, xs) }
        else { return .empty(.error(Lazy{ errExpect(x) }))}
      } else {
        return .empty(.error(Lazy{ errEof }))
      }
    }}
  } else {
    return {{ state in .empty(.ok([], state, Lazy{ unknownError(state) })) }}
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

        func char<Character, c: Collection> (c: Character) -> Parser<Character, c>
          where c.Iterator.Element == Character
        {
          let showChar = { x: Character in "\"\(x)\"" }
          let testChar = { x: Character in if x == c { return x } else { return nil } }
          let nextPos = { pos: SourcePos, x: Character, xs: c in updatePos(pos, x) }
          return tokenPrim(showChar, nextPos, testChar)
        }
*/
public func tokenPrim<a, c: Collection, u> (_ showToken: @escaping (c.Iterator.Element) -> String, _ nextPosition: @escaping (SourcePos, c.Iterator.Element, c) -> SourcePos, _ test: @escaping (c.Iterator.Element) -> a?) -> UserParserClosure<a, c, u>
  where c.SubSequence == c
{
  return {{ state in
    if let head = state.input.first, let x = test(head) {
      let tail = state.input.dropFirst()
      let newPos = nextPosition(state.pos, head, tail)
      let newState = State(tail, newPos, state.user)
      return .consumed(Lazy{ .ok(x, newState, Lazy{ unknownError(newState) }) })
    } else if let head = state.input.first {
      return .empty(sysUnExpectError(showToken(head), state.pos))
    } else {
      return .empty(sysUnExpectError("", state.pos))
    }
  }}
}

/**
    `many(p)` applies the parser `p` *zero* or more times. Returns an
    array of the returned values of `p`.

        func identifier () -> StringParser<String> {
          return ( letter >>- { c in
            many(alphaNum <|> char("_")) >>- { cs in
              return create(String(c) + String(cs))
            }
          } )()
        }
*/
public func many<a, c: Collection, u> (_ p: @escaping UserParserClosure<a, c, u>) -> UserParserClosure<[a], c, u> {
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

        func spaces<c: Collection> () -> Parser<(), c> {
          return skipMany(space)()
        }
*/
public func skipMany<a, c: Collection, u> (_ p: @escaping UserParserClosure<a, c, u>) -> UserParserClosure<(), c, u> {
  return manyAccum({ _, _ in [] }, p) >>> create(())
}

public func manyAccum<a, c: Collection, u> (_ acc: @escaping (a, [a]) -> [a], _ p: @escaping UserParserClosure<a, c, u>) -> UserParserClosure<[a], c, u> {
  let msg = "Parsec many: combinator 'many' is applied to a parser that accepts an empty string."
  func walk (_ xs: [a], _ x: a, _ state: State<c, u>) -> Consumed<[a], c, u> {
    switch p()(state) {
    case let .consumed(reply):
      switch reply.value {
      case let .error(err): return .consumed(Lazy{ .error(err) })
      case let .ok(y, st, _): return walk(acc(x, xs), y, st)
      }
    case let .empty(reply):
      switch reply {
      case let .error(err): return .consumed(Lazy{ .ok(acc(x, xs), state, err) })
      case .ok: fatalError(msg)
      }
    }
  }
  return {{ state in
    switch p()(state) {
    case let .consumed(reply):
      switch reply.value {
      case let .error(err): return .consumed(Lazy{ .error(err) })
      case let .ok(x, st, _): return walk([], x, st)
      }
    case let .empty(reply):
      switch reply {
      case let .error(err): return .empty(.ok([], state, err))
      case .ok: fatalError(msg)
      }
    }
  }}
}

public func runP<a, c: Collection, u> (_ p: UserParserClosure<a, c, u>, _ user: u, _ name: String, _ input: c) -> Either<ParseError, a> {
  switch p()(State(input, SourcePos(name), user)) {
  case let .consumed(reply):
    switch reply.value {
    case let .ok(x, _, _): return .right(x)
    case let .error(err): return .left(err.value)
    }
  case let .empty(reply):
    switch reply {
    case let .ok(x, _, _): return .right(x)
    case let .error(err): return .left(err.value)
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

        func parseFromFile<a, c: Collection> (_ p: Parser<a, c>, _ fileUrl: String) -> Either<ParseError, a> {
          let input = String(contentsOf: fileUrl)
          return runParser(p, fileUrl, input)
        }
*/
public func runParser<a, c: Collection, u> (_ p: UserParserClosure<a, c, u>, _ user: u, _ name: String, _ input: c) -> Either<ParseError, a> {
  return runP(p, user, name, input)
}

/**
    `parse(p, filePath, input)` runs a parser `p`.
    The `filePath` is only used in error messages and may be the
    empty string. Returns either a 'ParseError' ('left')
    or a value of type `a` ('right').

        func main () {
          switch parse(numbers, "", "11, 2, 43") {
          case let .left(err): print(err)
          case let .right(xs): print(xs.reduce(0, combine: +))
          }
        }

        func numbers<c: Collection> () -> Parser<[Int], c> {
          return commaSep(integer)()
        }
*/
public func parse<a, c: Collection, u> (_ p: UserParserClosure<a, c, u>, _ user: u, _ name: String, _ input: c) -> Either<ParseError, a> {
  return runP(p, user, name, input)
}

public func parse<a, c: Collection> (_ p: ParserClosure<a, c>, _ name: String, _ input: c) -> Either<ParseError, a> {
  return parse(p, (), name, input)
}

public func parseTest<a, c: Collection, u> (_ p: UserParserClosure<a, c, u>, _ user: u, _ input: c) {
  switch parse(p, user, "", input) {
  case let .left(err): print(err)
  case let .right(x): print(x)
  }
}

public func parseTest<a, c: Collection> (_ p: ParserClosure<a, c>, _ input: c) {
  return parseTest(p, (), input)
}

/**
    Returns the current source position. See also 'SourcePos'.
*/
public func getPosition<c: Collection, u> () -> UserParser<SourcePos, c, u> {
  return (getParserState >>- { state in create(state.pos) })()
}

/**
    Returns the current input.
*/
public func getInput<c: Collection, u> () -> UserParser<c, c, u> {
  return (getParserState >>- { state in create(state.input) })()
}

/**
    `setPosition(pos)` sets the current source position to `pos`.
*/
public func setPosition<c: Collection, u> (_ pos: SourcePos) -> UserParserClosure<(), c, u> {
  return updateParserState { state in State(state.input, pos, state.user) } >>> create(())
}

/**
    `setInput(input)` continues parsing with `input`. The 'getInput' and
    `setInput` functions can for example be used to deal with #include
    files.
*/
public func setInput<c: Collection, u> (_ input: c) -> UserParserClosure<(), c, u> {
  return updateParserState { state in State(input, state.pos, state.user) } >>> create(())
}

/**
    Returns the full parser state as a 'State' record.
*/
public func getParserState<c: Collection, u> () -> UserParser<State<c, u>, c, u> {
  return (updateParserState { state in state })()
}

/**
    `setParserState(state)` set the full parser state to `state`.
*/
public func setParserState<c: Collection, u> (_ state: State<c, u>) -> UserParserClosure<State<c, u>, c, u> {
  return updateParserState { _ in state }
}

/**
    `updateParserState(f)` applies function `f` to the parser state.
*/
public func updateParserState<c: Collection, u> (_ f: @escaping (State<c, u>) -> State<c, u>) -> UserParserClosure<State<c, u>, c, u> {
  return {{ state in
    let newState = f(state)
    return .empty(.ok(newState, newState, Lazy{ unknownError(newState) }))
  }}
}

/**
    Returns the current user state.
*/
public func getState<c: Collection, u> () -> UserParser<u, c, u> {
  return (getParserState >>- { state in create(state.user)})()
}

/**
    `putState(state)` set the user state to `state`.
*/
public func putState<c:Collection, u> (_ user: u) -> UserParserClosure<(), c, u> {
  return updateParserState { state in State(state.input, state.pos, user) } >>> create(())
}

/**
    `modifyState(f)` applies function `f` to the user state. Suppose
    that we want to count identifiers in a source, we could use the user
    state as:

        let expr = identifier >>- { x in
          modifyState { $0 + 1 }
          return create(x)
        }
*/
public func modifyState<c: Collection, u> (_ f: @escaping (u) -> u) -> UserParserClosure<(), c, u> {
  return updateParserState { state in State(state.input, state.pos, f(state.user)) } >>> create(())
}

