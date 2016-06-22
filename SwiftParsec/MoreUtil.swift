public func noneOf<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> (_ list: [Character]) -> Parser<Character, c>.T {
  return satisfy({ n in !list.contains { n == $0 } })
}
