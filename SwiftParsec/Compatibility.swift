import Foundation

func isSpace (_ c: Character) -> Bool {
  let whitespaces = CharacterSet.whitespacesAndNewlines
  return String(c).rangeOfCharacter(from: whitespaces) != nil
}

func isUpper (_ c: Character) -> Bool {
  let uppers = CharacterSet.uppercaseLetters
  return String(c).rangeOfCharacter(from: uppers) != nil
}

func isLower (_ c: Character) -> Bool {
  let lowers = CharacterSet.lowercaseLetters
  return String(c).rangeOfCharacter(from: lowers) != nil
}

func isAlphaNum (_ c: Character) -> Bool {
  let alphaNums = CharacterSet.alphanumerics
  return String(c).rangeOfCharacter(from: alphaNums) != nil
}

func isLetter (_ c: Character) -> Bool {
  let letters = CharacterSet.letters
  return String(c).rangeOfCharacter(from: letters) != nil
}

func isDigit (_ c: Character) -> Bool {
  let digits = CharacterSet.decimalDigits
  return String(c).rangeOfCharacter(from: digits) != nil
}

func isHexDigit (_ c: Character) -> Bool {
  let hexDigits = CharacterSet(charactersIn: "0123456789aAbBcCdDeEfF")
  return String(c).rangeOfCharacter(from: hexDigits) != nil
}

func isOctDigit (_ c: Character) -> Bool {
  let octDigits = CharacterSet(charactersIn: "01234567")
  return String(c).rangeOfCharacter(from: octDigits) != nil
}
