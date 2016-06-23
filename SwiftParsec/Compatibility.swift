// TODO: Consider using CharacterSet instead of NSCharacterSet
// https://developer.apple.com/reference/foundation/characterset
import Foundation

func isSpace (_ c: Character) -> Bool {
  let whitespaces = NSCharacterSet.whitespacesAndNewlines()
  return String(c).rangeOfCharacter(from: whitespaces) != nil
}

func isUpper (_ c: Character) -> Bool {
  let uppers = NSCharacterSet.uppercaseLetters()
  return String(c).rangeOfCharacter(from: uppers) != nil
}

func isLower (_ c: Character) -> Bool {
  let lowers = NSCharacterSet.lowercaseLetters()
  return String(c).rangeOfCharacter(from: lowers) != nil
}

func isAlphaNum (_ c: Character) -> Bool {
  let alphaNums = NSCharacterSet.alphanumerics()
  return String(c).rangeOfCharacter(from: alphaNums) != nil
}

func isLetter (_ c: Character) -> Bool {
  let letters = NSCharacterSet.letters()
  return String(c).rangeOfCharacter(from: letters) != nil
}

func isDigit (_ c: Character) -> Bool {
  let digits = NSCharacterSet.decimalDigits()
  return String(c).rangeOfCharacter(from: digits) != nil
}

func isHexDigit (_ c: Character) -> Bool {
  let hexDigits = NSCharacterSet(charactersIn: "0123456789aAbBcCdDeEfF")
  return String(c).rangeOfCharacter(from: hexDigits) != nil
}

func isOctDigit (_ c: Character) -> Bool {
  let octDigits = NSCharacterSet(charactersIn: "01234567")
  return String(c).rangeOfCharacter(from: octDigits) != nil
}
