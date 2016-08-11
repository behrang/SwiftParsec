# SwiftParsec

Parsec is an industrial strength, monadic parser combinator library. The original paper is available here: [Parsec: Direct Style Monadic Parser Combinators For The Real World](http://research.microsoft.com/pubs/65201/parsec-paper-letter.pdf). Find more info about Haskell Parsec here: [https://wiki.haskell.org/Parsec](https://wiki.haskell.org/Parsec). To learn more, you may want to read [chapter 16 of Real World Haskell](http://book.realworldhaskell.org/read/using-parsec.html).

# What is Parsec?

Parsec is a "parser combinator" library. It has many utility functions and helps you combine simpler parsers to create more advanced parsers.

# What is a parser?

A parser is a function that when given an input stream, it may parse a value from it and return the rest of the stream, or it may fail. For example, `digit()` is a parser for parsing a single digit. Given an input stream like `"123"`, it will parse it successfully and returns `"1"` and the rest of the stream (`"23"`).

Another example is `letter()` for parsing a single letter. Given an input stream like `"123"`, it will fail with an error message about unexpected `"1"` in the input stream. But with the stream `"abc"`, it will return `"a"` and the rest of the stream (`"bc"`).

# What is a combinator?

Suppose we want to parse either a single letter or a digit. We can combine `letter()` and `digit()` with `<|>` combinator:

```swift
func letterOrDigit () -> StringParser<Character>.T {
  return letter() <|> digit()
}
```

With `letterOrDigit()` we can parse both `"123"` and `"abc"` successfully and we will get `"1"` or `"a"` respectively. Here, `<|>` operator is a combinator which creates a new parser from two simpler parsers (`letter()` and `digit()`).

Another combinator is `many`. Using it, we can create a new parser which applies the provided parser many times while it is successful and returns an array of results:

```swift
func digits () -> StringParser<[Character]>.T {
  return many(digit())
}
```

With `digits()` we can parse `"123"` and successfully get `["1", "2", "3"]`.

# Parsing values

In the above examples, we have parsed single characters, which is not really interesting. Now suppose we want to parse an integer value. We can use `>>-` operator (bind combinator)  to convert the result:

```swift
func integer () -> StringParser<Int>.T {
  return digits() >>- { ds in
    let s = String(ds)
    if let i = Int(s) {
      return create(i)
    } else {
      return fail("invalid integer \(s)")
    }
  }
}
```

The `>>-` operator, takes a parser on its left hand side (`digits()` in this example) and a function (or closure) on the right hand side, and creates a new parser, that when applied, will pass the result of left hand side parser (`[Character]` in this example) to the right hand side function. The right hand side function should return a parser, and if left hand side has failed, right hand side function will not be called.

The `create` function creates a new parser that always succeeds with the provided value, so here, when `integer()` is applied, and some digit characters are in the input stream, those will be passed to the closure as `ds` and converted to an `Int`. If conversion is successful, a new parser that always succeeds with that integer is created and returned. On the other hand, if conversion fails, a parser that always fails is returned.

# `Parser` and `StringParser`

In the above examples, functions return a value of type `StringParser<X>.T`. Here, `T` is just a temporary solution for a bug in Swift compiler. When it is fixed, the type will be simplified to `StringParser<X>`.

The generic parameter `X` is the type of the value returned by parser when applied. In the `integer` function it's `Int`, in the `digits` function it's `[Character]` and in `letterOrDigit`, `letter` and `digit` it's `Character`.

So what is `StringParser`? It is an alias for `Parser` type and is defined like:

```swift
typealias StringParser<X> = Parser<X, String.CharacterView>
```

It's just a short hand for working with `String` inputs, since most of the times, you will be parsing a string.

And now let's focus on `Parser`. Here is the tricky part. It's a function. That means, any value of this type is a function that needs to be applied. It is defined like:

```swift
typealias Parser<X, C: Collection> = (State<C>) -> Consumed<X, C>
```

So it needs a parameter of type `State<C>` and returns a value of type `Consumed<X, C>`. `State` is a container for input stream, and `Consumed` is the result which may be a success or a failure. With this definition, parsers get an input stream and return a result.

The type `StringParser` just fixes the `C` generic parameter to `String.CharacterView` which is the collection of `Character`s in the input `String`. So `StringParser` works with `String` but if you need some advanced functionality, you can use the more generic type `Parser`.

With all of this, `StringParser` will get a parameter of type `State<String.CharacterView>` and returns a value of type `Consumed<X, String.CharacterView>`.

To learn more about `State` and `Consumed`, you can read the paper in the About section. However, you can read some examples and start creating your own parsers.

# Example 1: Simple CSV Parser

Let's say we want to write a parser to parse CSV files. CSV (Comma Separated Values) files are simple text files that each record is on a line and fields are separated by commas. Here is an example:

```
Movie,Year
Following,1998
Memento,2000
Insomnia,2002
Batman Begins,2005
The Prestige,2006
The Dark Knight,2008
Inception,2010
The Dark Knight Rises,2012
Interstellar,2014
```

Each movie is on its own line and title and year of the movie are separated by a comma.

Here is a simple CSV parser:

```swift
import Parsec

func csv () -> StringParser<[[String]]>.T {
  return endBy(line(), char("\n"))
}

func line () -> StringParser<[String]>.T {
  return sepBy(cell(), char(","))
}

func cell () -> StringParser<String>.T {
  return many(noneOf(",\n")) >>- { chars in create(String(chars)) }
}
```

The first parser, `csv()` creates a parser of type `[[String]]`. It is using the `endBy` combinator. We wanted to say that a CSV file is `many` `line`s which are `endBy` a `"\n"` character.

The second parser, `line()` creates a parser of type `[String]`. Each line in a CSV file is an array of separated fields. It is using the `sepBy` combinator. We wanted to say that a line is `many` `cell`s which are separated by a `","` character.

The difference of `endBy` and `sepBy` is that `endBy` requires the separator after each parsed value, while `sepBy` requires the separator in between the separated values.

The third parser, `cell()` creates a parser of type `String`. It parses a single field. It is defined as `many` characters which are `noneOf` `","` and `"\n"` and the resulting `[Character]` is converted to a `String`.

With these three parsers, we can parse simple CSV files. To execute it, we need to get file name and parse it and display the results:

```swift
func main () {
  if Process.arguments.count != 2 {
    print("Usage: \(Process.arguments[0]) csv_file")
  } else {
    let result = try! parse(csv(), contentsOfFile: Process.arguments[1])
    switch result {
    case let .left(err): print(err)
    case let .right(x): format(x)
    }
  }
}

func format (_ data: [[String]]) {
  data.forEach{ item in
    print(item.joined(separator: "\n"), terminator: "\n\n")
  }
}

main()
```

In the `main` function, first we check input arguments to the script and print a usage guide if a file is not provided as an argument.

If a file is provided, we call the `parse` function with the `csv()` parser and pass the name of the file provided as argument to the script. `parse` will first read the contents of the file, and pass the resulting string to our parser and returns its result.

We then print the result which may be an error (.left) or success (.right). `format` is a utility function to print the parsed result so we can check the behaviour of our parser.

Let's test this. You can clone the repository and then build the project:

```shell
swift build
```

**Note**: You'll need the latest Swift 3.0. You can download and install it from [swift.org](swift.org).

Now, if you run:

```shell
.build/debug/example-csv-simple
```

You'll get the error message in the main function:

```
Usage: .build/debug/example-csv-simple csv_file
```

We need to provide a CSV file:

```shell
.build/debug/example-csv-simple example-csv-simple/simple.csv
```

And the output will be:

```
Movie
Year

Following
1998

Memento
2000

Insomnia
2002

Batman Begins
2005

The Prestige
2006

The Dark Knight
2008

Inception
2010

The Dark Knight Rises
2012

Interstellar
2014

```

The `format` function prints each field on a separate line and inserts an empty line after each record.

As you can see, our parser worked great for this simple CSV file.

** Note**: You may think that it was easier to just split the input on new-line characters and then split each line on comma characters. Although this approach would work for simple CSV files, not all of them are as simple as this. For example there may be a cell in the CSV file that contains a comma character. Spliting blindly on commas whould incorrectly split that cell. To handle those cases, CSV files use double quotes around those fields to mark the start and end of the cell.

Our simple CSV parser has this limitation too. It doesn't check for double quotes. Say we have this CSV file:

```
Movie,Year,Roles
Following,1998,"Director, Producer, Writer"
Memento,2000,"Director, Writer"
Insomnia,2002,Director
Batman Begins,2005,"Director, Writer"
The Prestige,2006,"Director, Producer, Writer"
The Dark Knight,2008,"Director, Producer, Writer"
Inception,2010,"Director, Producer, Writer"
The Dark Knight Rises,2012,"Director, Producer, Writer"
Interstellar,2014,"Director, Producer, Writer"
```

We added a 'Roles' field but this field has commas inside it. So double quotes are used around that field. If we run our simple parser with this CSV file:

```shell
.build/debug/example-csv-simple example-csv-simple/advanced.csv
```

We will get:

```
Movie
Year
Roles

Following
1998
"Director
 Producer
 Writer"

Memento
2000
"Director
 Writer"

Insomnia
2002
Director

Batman Begins
2005
"Director
 Writer"

The Prestige
2006
"Director
 Producer
 Writer"

The Dark Knight
2008
"Director
 Producer
 Writer"

Inception
2010
"Director
 Producer
 Writer"

The Dark Knight Rises
2012
"Director
 Producer
 Writer"

Interstellar
2014
"Director
 Producer
 Writer"

```

As you can see, roles are printed on different lines, and our parser *incorrectly* parsed them as different fields.

Another thing in CSV files is that if we want a double quote character in a double quoted field, we need to escape it with two double quotes. If one double quote is used, that means the end of the field. To test this assume we have this bad CSV file:

```
Movie,Year
Following,1998
Memento,2000
Insomnia,2002
Batman Begins,"20"05"
The Prestige,2006
The Dark Knight,2008
Inception,2010
The Dark Knight Rises,2012
Interstellar,2014
```

Here, a double quote is incorrectly inserted in the middle of year on line 5. If we run our simple parser with this file:

```shell
.build/debug/example-csv-simple example-csv-simple/bad.csv
```

We would not get any error messages.

Let's fix these issues in the next example.

# Example 2: Advanced CSV Parser

To fix the problems of our simple CSV parser, we need to consider the case where double quotes are used around fields. Also we should consider double quote escapes. Here is our advanced CSV parser:

```swift
import Parsec

func csv () -> StringParser<[[String]]>.T {
  return endBy(line(), endOfLine())
}

func line () -> StringParser<[String]>.T {
  return sepBy(cell(), char(","))
}

func cell () -> StringParser<String>.T {
  return quotedCell() <|> simpleCell()
}

func simpleCell () -> StringParser<String>.T {
  return many(noneOf(",\n")) >>- { cs in create(String(cs)) }
}

func quotedCell () -> StringParser<String>.T {
  return between(char("\""), char("\""), quotedCellContent())
}

func quotedCellContent () -> StringParser<String>.T {
  return many(quotedCellChar()) >>- { cs in create(String(cs)) }
}

func quotedCellChar () -> StringParser<Character>.T {
  return noneOf("\"") <|> escapedQuote()
}

func escapedQuote () -> StringParser<Character>.T {
  return attempt(string("\"\"")) >>> create("\"")
}
```

`csv()` is defined as `many` `line`s `endBy` an `endOfLine` character. `endOfLine()` is a utility parser that matches both `"\n"` and `"\r\n"` to support new-line characters in different operating systems.

`line()` is the same as before.

`cell()` is defined as either a `quotedCell()` or a `simpleCell()`. Note that we need to first check for quoted cell.

`simpleCell()` is like `cell` in simple CSV parser.

`quotedCell()` is defined as `quotedCellContent()` which is between two double quotes (`char("\"")`).

`quotedCellContent()` is defined as `many` quotedCellChar()`s which are then converted to a string.

`quotedCellChar()` is defined as `noneOf` `\"` or an `escapedQuote()`.

`escapedQuote()` is defined as a `string` of two double quotes (a double quote followed by another double quote) and the success result of those two double quotes is ignored (using `>>>` combinator) and a single double quote is created. `attempt` is also used whenever we are going to look ahead more than one character.

Now we can parse CSV files with fields that also include comma, new-line and double quote characters with the same main function. Execute it with the advanced.csv file:

```shell
.build/debug/example-csv-advanced example-csv-advanced/advanced.csv
```

And this time, we will get the following expected output:

```
Movie
Year
Roles

Following
1998
Director, Producer, Writer

Memento
2000
Director, Writer

Insomnia
2002
Director

Batman Begins
2005
Director, Writer

The Prestige
2006
Director, Producer, Writer

The Dark Knight
2008
Director, Producer, Writer

Inception
2010
Director, Producer, Writer

The Dark Knight Rises
2012
Director, Producer, Writer

Interstellar
2014
Director, Producer, Writer

```

As you can see, even though roles fields may include commas, they are parsed as a single field and displayed on their own row.

If we execute it on an incorrectly formatted CSV file:

```shell
.build/debug/example-csv-advanced example-csv-advanced/bad.csv
```

We will get a good error message:

```
"example-csv-advanced/bad.csv" (line 5, column 19): unexpected "0"
expecting "new-line" or ","
```

# Example 3: JSON Parser

Now let's creat a parser for parsing JSON files. If you are not familiar with JSON, read [json.org](json.org). From there, we can see that a JSON value is:

![JSON value](http://json.org/value.gif)

When parsing a json document, we need a data structure to put the parsed values in it. In Swift, we can use an enum for this:

```swift
enum Json {
  case null
  case bool(Bool)
  case number(Double)
  case string(String)
  case array([Json])
  case object([String: Json])
}
```

A JSON file, can contain spaces and a JSON value, but nothing else:

```swift
func jsonFile () -> StringParser<Json>.T {
  return spaces() >>> value() <<< eof()
}
```

Here, `spaces()` parser matches zero or more white space characters. The `>>>` combinator ignores success result on its left and returns the result of its right. `value()` parser parses a JSON value which we will see next, and `<<<` combinator, as you have guessed, ignores success result of its right and returns the result of its left. Finally, `eof()` (End Of File) is a parser that matches an end of file or input stream.

A JSON value can be a string, number, object, array, boolean, or null:

```swift
func value () -> StringParser<Json>.T {
  return str()
      <|> number()
      <|> object()
      <|> array()
      <|> bool()
      <|> null()
      <?> "json value"
}
```

The `<?>` combinator just adds a label to the parser for better error messages. When the above parser fails, the error message will contain a message about expecting "json value".

JSON Strings are defined as a string of characters between double quotes with some special cases for control characters and escape sequences:

![JSON String](http://json.org/string.gif)

Here are the required parsers:

```swift
func str () -> StringParser<Json>.T {
  return quotedString() >>- { s in create(.string(s)) }
}

func quotedString () -> StringParser<String>.T {
  return between(quote(), quote(), many(quotedCharacter()))
        >>- { cs in create(String(cs)) } <<< spaces() <?> "quoted string"
}

func quote () -> StringParser<Character>.T {
  return char("\"") <?> "double quote"
}

func quotedCharacter () -> StringParser<Character>.T {
  var chars: [Character] = ["\"", "\\"]
  for i in 0x00...0x1f {
    chars.append(Character(UnicodeScalar(i)))
  }
  for i in 0x7f...0x9f {
    chars.append(Character(UnicodeScalar(i)))
  }
  return noneOf(chars)
      <|> attempt(string("\\\"")) >>> create("\"")
      <|> attempt(string("\\\\")) >>> create("\\")
      <|> attempt(string("\\/")) >>> create("/")
      <|> attempt(string("\\b")) >>> create("\u{8}")
      <|> attempt(string("\\f")) >>> create("\u{c}")
      <|> attempt(string("\\n")) >>> create("\n")
      <|> attempt(string("\\r")) >>> create("\r")
      <|> attempt(string("\\t")) >>> create("\t")
      <|> attempt(string("\\u") >>> count(4, hexDigit()) >>- { hds in
            let code = String(hds)
            let i = Int(code, radix: 16)!
            return create(Character(UnicodeScalar(i)))
          })
}
```

`str()` is a parser of type `Json`, so we wrap the returned value of `quotedString()` which is a Swift `String` in our enum (`.string(s)`).

`quotedString()` is `many` `quotedCharacter()`s between two `quote()`s followed by zero or more white spaces.

A `quotedCharacter()` is `noneOf` `\"` or `\\` or unicode control characters, or some escape sequences, or a unicode escape sequence.

JSON numbers are defined as:

![JSON Number](http://json.org/number.gif)

It's a little more complicated but we can break it to different parsers and combine them together:

```swift
func number () -> StringParser<Json>.T {
  return numberSign() >>- { sign in
    numberFixed() >>- { fixed in
      numberFraction() >>- { fraction in
        numberExponent() >>- { exponent in
          let s = sign + fixed + fraction + exponent
          if let d = Double(s) {
            return create(.number(d))
          } else {
            return fail("invalid number \(s)")
          }
        }
      }
    }
  } <<< spaces() <?> "number"
}

func numberSign () -> StringParser<String>.T {
  return option("+", string("-"))
}

func numberFixed () -> StringParser<String>.T {
  return string("0") <|> many1(digit()) >>- { create(String($0)) }
}

func numberFraction () -> StringParser<String>.T {
  return char(".") >>> many1(digit()) >>- { create("." + String($0)) }
    <|> create("")
}

func numberExponent () -> StringParser<String>.T {
  return oneOf("eE") >>> option("+", oneOf("+-")) >>- { sign in
      many1(digit()) >>- { digits in create("e" + String(sign) + String(digits)) }
    }
    <|> create("")
}
```

In `number()` four parsers are combined using `>>-` and then they are joined and converted to a `Double` value.

In `numberSign()`, `option` combinator is used which gets a default value and returns it in case the passed in parser fails.

Other parsers should be easy by now.

A JSON object is defined as:

![JSON Object](http://json.org/object.gif)

And we can parse it with:

```swift
func object () -> StringParser<Json>.T {
  return between(leftBrace(), rightBrace(), sepBy(pair(), comma())) >>- { ps in
    var r: [String: Json] = [:]
    ps.forEach { p in r[p.0] = p.1 }
    return create(.object(r))
  } <?> "object"
}

func leftBrace () -> StringParser<Character>.T {
  return char("{") <<< spaces() <?> "open curly bracket"
}

func rightBrace () -> StringParser<Character>.T {
  return char("}") <<< spaces() <?> "close curly bracket"
}

func comma () -> StringParser<Character>.T {
  return char(",") <<< spaces() <?> "comma"
}

func colon () -> StringParser<Character>.T {
  return char(":") <<< spaces() <?> "colon"
}

func pair () -> StringParser<(String, Json)>.T {
  return quotedString() >>- { k in
    colon() >>> value() >>- { v in
      create((k, v))
    }
  } <?> "key:value pair"
}
```

A JSON array is defined as:

![JSON Array](http://json.org/array.gif)

And we can parse it with:

```swift
func array () -> StringParser<Json>.T {
  // the next line crashes the compiler with "Segmentation fault: 11"
  // return between(leftBracket(), rightBracket(), sepBy(value(), comma()))
  //     >>- { js in create(.array(js)) }
  // as a result, we can't have an array within an array for now
  func element () -> StringParser<Json>.T {
    return null() <|> bool() <|> number() <|> str() <|> object()
  }
  return between(leftBracket(), rightBracket(), sepBy(element(), comma()))
      >>- { js in create(.array(js)) }
      <?> "array"
}

func leftBracket () -> StringParser<Character>.T {
  return char("[") <<< spaces() <?> "open square bracket"
}

func rightBracket () -> StringParser<Character>.T {
  return char("]") <<< spaces() <?> "close square bracket"
}
```

Here, because of a problem in Swift compiler, an array could not contain another array. So, `element()` is a temporary parser just like `value()` except that it doesn't accept arrays.

Adding parsers for "true", "false" and "null" will complete our JSON parser:

```swift
func bool () -> StringParser<Json>.T {
  return (string("true") >>> create(.bool(true)) <<< spaces() <?> "true")
      <|> (string("false") >>> create(.bool(false)) <<< spaces() <?> "false")
}

func null () -> StringParser<Json>.T {
  return string("null") >>> create(.null) <<< spaces() <?> "null"
}
```

Assuming we have the following JSON file:

```json
{
  "name": "Christopher Nolan",
  "age": 45,
  "movies": [
    {
      "title": "Following",
      "year": 1998,
      "roles": ["Director", "Producer", "Writer"]
    },
    {
      "title": "Memento",
      "year": 2000,
      "roles": ["Director", "Writer"]
    },
    {
      "title": "Insomnia",
      "year": 2002,
      "roles": ["Director"]
    },
    {
      "title": "Batman Begins",
      "year": 2005,
      "roles": ["Director", "Writer"]
    },
    {
      "title": "The Prestige",
      "year": 2006,
      "roles": ["Director", "Producer", "Writer"]
    },
    {
      "title": "The Dark Knight",
      "year": 2008,
      "roles": ["Director", "Producer", "Writer"]
    },
    {
      "title": "Inception",
      "year": 2010,
      "roles": ["Director", "Producer", "Writer"]
    },
    {
      "title": "The Dark Knight Rises",
      "year": 2012,
      "roles": ["Director", "Producer", "Writer"]
    },
    {
      "title": "Interstellar",
      "year": 2014,
      "roles": ["Director", "Producer", "Writer"]
    }
  ]
}
```

We can parse it with:

```shell
.build/debug/example-json example-json/movies.json
```

And we will get the following output:

```
{"name":"Christopher Nolan","age":45.0,"movies":[{"year":1998.0,"roles":["Director","Producer","Writer"],"title":"Following"},{"year":2000.0,"roles":["Director","Writer"],"title":"Memento"},{"year":2002.0,"roles":["Director"],"title":"Insomnia"},{"year":2005.0,"roles":["Director","Writer"],"title":"Batman Begins"},{"year":2006.0,"roles":["Director","Producer","Writer"],"title":"The Prestige"},{"year":2008.0,"roles":["Director","Producer","Writer"],"title":"The Dark Knight"},{"year":2010.0,"roles":["Director","Producer","Writer"],"title":"Inception"},{"year":2012.0,"roles":["Director","Producer","Writer"],"title":"The Dark Knight Rises"},{"year":2014.0,"roles":["Director","Producer","Writer"],"title":"Interstellar"}]}
```

You can give it different files and test it, and also give it some bad JSON files to see the great error messages the parser emits.

# API

To use SwiftParsec, it needs to be imported first:

```swift
import Parsec
```

Then parsers and combinators from the library can be combined togeether to create more complicated parsers and parse the input stream you want.

## Parse Input

The input stream can be any `Collection` type. A useful `Collection` is `String.CharacterView` which is a `Collection` of `Character`s of the input `String`.

But SwiftParsec can work with any `Collection`. You can for example tokenize the input stream first and create a collection of tokens and then use that as the input for parsers, although in this case tokens are not `Character`s anymore and Character parsers can't be used. An example is `Process.arguments` which is a `Collection` of `String`s provided as input arguments to the application.

## Character

Character parsers are basic parsers for parsing `Character` data when elements of input stream is of type `Character`.

### `oneOf(_ s: String) -> Parser<Character>`

Succeeds if the current character is in the supplied string `s`. Returns the parsed character. See also `satisfy`.

```swift
func vowel () -> StringParser<Character>.T {
  return oneOf("aeiou")
}
```

### `noneOf(_ s: String) -> Parser<Character>`

As the dual of 'oneOf', `noneOf(s)` succeeds if the current character is *not* in the supplied string `s`. Returns the parsed character.

```swift
func consonant () -> StringParser<Character>.T {
  return noneOf("aeiou")
}
```

### `spaces() -> Parser<Character>`

Skips *zero* or more white space characters. See also 'skipMany'.

### `space() -> Parser<Character>`

Parses a white space character (any character which satisfies 'isSpace'). Returns the parsed character.

### `newline() -> Parser<Character>`

Parses a newline character ('\n'). Returns a newline character.

### `crlf() -> Parser<Character>`

Parses a carriage return character ('\r') followed by a newline character ('\n'). Returns a newline character.

### `endOfLine() -> Parser<Character>`

Parses a CRLF (see 'crlf') or LF (see 'newline') end-of-line. Returns a newline character ('\n').

### `tab() -> Parser<Character>`

Parses a tab character ('\t'). Returns a tab character.

### `upper() -> Parser<Character>`

Parses an upper case letter (a character between 'A' and 'Z'). Returns the parsed character.

### `lower() -> Parser<Character>`

Parses a lower case character (a character between 'a' and 'z'). Returns the parsed character.

### `alphaNum() -> Parser<Character>`

Parses a letter or digit (a character between '0' and '9'). Returns the parsed character.

### `letter() -> Parser<Character>`

Parses a letter (an upper case or lower case character). Returns the parsed character.

### `digit() -> Parser<Character>`

Parses a digit. Returns the parsed character.

### `hexDigit() -> Parser<Character>`

Parses a hexadecimal digit (a digit or a letter between 'a' and 'f' or 'A' and 'F'). Returns the parsed character.

### `octDigit() -> Parser<Character>`

Parses an octal digit (a character between '0' and '7'). Returns the parsed character.

### `char(_ c: Character) -> Parser<Character>`

`char(c)` parses a single character `c`. Returns the parsed character (i.e. `c`).

```swift
func semiColon () -> StringParser<Character>.T {
  return char(";")
}
```

### `anyChar() -> Parser<Character>`

This parser succeeds for any character. Returns the parsed character.

### `satisfy(_ f: (Character) -> Bool) -> Parser<Character>`

The parser `satisfy(f)` succeeds for any character for which the supplied function `f` returns 'true'. Returns the character that is actually parsed.

```swift
func digit () -> StringParser<Character>.T {
  return satisfy(isDigit)
}
```

### `string(_ s: String) -> Parser<String>`

`string(s)` parses a string given by `s`. Returns the parsed string (i.e. `s`).

```swift
func divOrMod () -> StringParser<String>.T {
  return string("div")
    <|> string("mod")
}
```

## Combinators

Combinators are functions for combining other parsers. They can be used on any parser, not only character parsers.

### `choice(_ ps: [Parser<a>]) -> Parser<a>`

`choice(ps)` tries to apply the parsers in the array `ps` in order, until one of them succeeds. Returns the value of the succeeding parser.

### `option(_ x: a, _ p: Parser<a>) -> Parser<a>`

`option(x, p)` tries to apply parser `p`. If `p` fails without consuming input, it returns the value `x`, otherwise the value returned by `p`.

```swift
func priority () -> StringParser<Int>.T {
  return option(0, digit() >>- { d in
    if let i = Int(String(d)) {
      return create(i)
    } else {
      return fail("this will not happen")
    }
  })
}
```

### `optionMaybe(_ p: Parser<a>) -> Parser<a?>`

`optionMaybe(p)` tries to apply parser `p`.  If `p` fails without consuming input, it returns '.none', otherwise it returns '.some' the value returned by `p`.

### `optional(_ p: Parser<a>) -> Parser<()>`

`optional(p)` tries to apply parser `p`.  It will parse `p` or nothing. It only fails if `p` fails after consuming input. It discards the result of `p`.

### `between(_ open: Parser<x>, _ close: Parser<y>, _ p: Parser<a>) -> Parser<a>`

`between(open, close, p)` parses `open`, followed by `p` and `close`. Returns the value returned by `p`.

```swift
func braces<a> (_ p: StringParser<a>.T) -> StringParser<a>.T {
  return between(char("{"), char("}"), p)
}
```

### `skipMany1(_ p: Parser<a>) -> Parser<()>`

`skipMany1(p)` applies the parser `p` *one* or more times, skipping its result.

### `many1(_ p: Parser<a>) -> Parser<[a]>`

`many1(p)` applies the parser `p` *one* or more times. Returns an array of the returned values of `p`.

```swift
func word () -> StringParser<[Character]>.T {
  return many1(letter())
}
```

### `sepBy(_ p: Parser<a>, _ sep: Parser<x>) -> Parser<[a]>`

`sepBy(p, sep)` parses *zero* or more occurrences of `p`, separated by `sep`. Returns a list of values returned by `p`.

```swift
func commaSep<a> (_ p: StringParser<a>.T) -> StringParser<[a]>.T {
  return sepBy(p, char(","))
}
```

### `sepBy1(_ p: Parser<a>, _sep: Parser<x>) -> Parser<[a]>`

`sepBy1(p, sep)` parses *one* or more occurrences of `p`, separated by `sep`. Returns a list of values returned by `p`.

### `sepEndBy1(_ p: Parser<a>, _ sep: Parser<x>) -> Parser<[a]>`

`sepEndBy1(p, sep)` parses *one* or more occurrences of `p`, separated and optionally ended by `sep`. Returns a list of values returned by `p`.

### `sepEndBy(_ p: Parser<a>, _ sep: Parser<x>) -> Parser<[a]>`

`sepEndBy(p, sep)` parses *zero* or more occurrences of `p`, separated and optionally ended by `sep`. Returns a list of values returned by `p`.

### `endBy1(_ p: Parser<a>, _ sep: Parser<x>) -> Parser<[a]>`

`endBy1(p, sep)` parses *one* or more occurrences of `p`, separated and ended by `sep`. Returns a list of values returned by `p`.

### `endBy(_ p: Parser<a>, _ sep: Parser<x>) -> Parser<[a]>`

`endBy(p, sep)` parses *zero* or more occurrences of `p`, separated and ended by `sep`. Returns a list of values returned by `p`.

### `count(_ n: Int, _ p: Parser<a>) -> Parser<[a]>`

`count(n, p)` parses `n` occurrences of `p`. If `n` is smaller or equal to zero, the parser equals to `create([])`. Returns a list of `n` values returned by `p`.

### `chainr(_ p: Parser<a>, _ op: Parser<(a, a) -> a>, _ x: a) -> Parser<a>`

`chainr(p, op, x)` parses *zero* or more occurrences of `p`, separated by `op`. Returns a value obtained by a *right* associative application of all functions returned by `op` to the values returned by `p`. If there are no occurrences of `p`, the value `x` is returned.

### `chainl(_ p: Parser<a>, _ op: Parser<(a, a) -> a>, _ x: a) -> Parser<a>`

`chainl(p, op, x)` parses *zero* or more occurrences of `p`, separated by `op`. Returns a value obtained by a *left* associative application of all functions returned by `op` to the values returned by `p`. If there are no occurrences of `p`, the value `x` is returned.

### `chainl1(_ p: Parser<a>, _ op: Parser<(a, a) -> a>) -> Parser<a>`

`chainl1(p, op)` parses *one* or more occurrences of `p`, separated by `op`. Returns a value obtained by a *left* associative application of all functions returned by `op` to the values returned by `p`. This parser can for example be used to eliminate left recursion which typically occurs in expression grammars.

```swift
func expr () -> StringParser<Int>.T {
  return chainl1(term(), addop())
}
func term () -> StringParser<Int>.T {
  return chainl1(factor(), mulop())
}
func factor () -> StringParser<Int>.T {
  return parens(expr()) <|> integer()
}

func mulop () -> StringParser<(Int, Int) -> Int>.T {
  return char("*") >>> create(*)
      <|> char("/") >>> create(/)
}
func addop () -> StringParser<(Int, Int) -> Int>.T {
  return char("+") >>> create(+)
      <|> char("-") >>> create(-)
}
```

### `chainr1(_ p: Parser<a>, _ op: Parser<(a, a) -> a>) -> Parser<a>`

`chainr1(p, op)` parses *one* or more occurrences of `p`, separated by `op`. Returns a value obtained by a *right* associative application of all functions returned by `op` to the values returned by `p`.

### `anyToken<c: Collection> () -> Parser<c.Iterator.Element>`

The parser `anyToken` accepts any kind of token. It is for example used to implement 'eof'. Returns the accepted token.

### `eof() -> Parser<()>`

This parser only succeeds at the end of the input. This is not a primitive parser but it is defined using 'notFollowedBy'.

### `notFollowedBy(_ p: Parser<a>) -> Parser<()>`

`notFollowedBy(p)` only succeeds when parser `p` fails. This parser does not consume any input. This parser can be used to implement the 'longest match' rule. For example, when recognizing keywords (for example `let`), we want to make sure that a keyword is not followed by a legal identifier character, in which case the keyword is actually an identifier (for example `lets`). We can program this behaviour as follows:

```swift
func keywordLet () -> StringParser<String>.T {
  return attempt(string("let") <<< notFollowedBy(alphaNum()))
}
```

### `manyTill(_ p: Parser<a>, _ end: Parser<x>) -> Parser<[a]>`

`manyTill(p, end)` applies parser `p` *zero* or more times until parser `end` succeeds. Returns the list of values returned by `p`. This parser can be used to scan comments:

```swift
func simpleComment () -> StringParser<String>.T {
  return string("<!--") >>> manyTill(anyChar(), attempt(string("-->"))) >>- { cs in create(String(cs)) }
}
```

Note the overlapping parsers `anyChar` and `string("-->")`, and therefore the use of the 'attempt' combinator.

# Credits

All credits goes to Daan Leijen and Erik Meijer for creating Parsec in Haskell.

# License

MIT
