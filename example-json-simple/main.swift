import SwiftParsec

// print(identifier()( State("@".characters) ))

// func x (_ v: State<String.CharacterView>) {
// }
// x("")

// func test1<c: Collection where c.SubSequence == c, c.Iterator.Element == Character> () -> (State<c>) -> Consumed<c.Iterator.Element, c> {
//   return (digit() <|> create("0")) >>- { _ in letter() }
// }
// let input1: State<String.CharacterView> = "*"
// print(test1()( input1 ))

// func test2 () -> (State<String.CharacterView>) -> Consumed<[[Character]], String.CharacterView> {
//   return
//     many1(many1(letter()) >>- { name in return newline() >>- { _ in create(name)} }) <?> "one or more names on each line"
// }
// let input2: State<String.CharacterView> = "1Behrang\nNoruziniya\n34\n"
// print(test2()(input2))

// func test3 () -> (State<String.CharacterView>) -> Consumed<[Character], String.CharacterView> {
//   return attempt(string("let".characters) <?> "let" >>- { _ in character(" ") >>- { _ in letter() >>- { _ in create([Character("-")])} }}) <|> identifier()
// }
// let input3: State<String.CharacterView> = "*letter"
// print(test3()(input3))

// parseCSV4("\"This, is, one, big, cell\"\n")
// print(query()(State("name=Behrang&age=&x".characters)))
print(json()(State("{\"x\":1,\"y\":true,\"z\":null,\"w\":{\"a\":\"Behrang\"}}".characters)))
