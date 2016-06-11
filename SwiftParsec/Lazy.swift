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
