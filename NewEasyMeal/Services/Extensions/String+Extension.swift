import Foundation

extension String {
    public func isValidPassword() -> Bool {
        let passwordRegex = "^(?=.*\\d)(?=.*[a-z])(?=.*[A-Z])[0-9a-zA-Z!@#$%^&*()\\-_=+{}|?>.<,:;~`’]{8,}$"
        return NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: self)
    }
    
    public func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
}

extension String {
    func formatPhoneNumber() -> String {
        let cleanNumber = components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        let mask = "(XXX) XXX-XXXX"
        
        var result = ""
        var startIndex = cleanNumber.startIndex
        var endIndex = cleanNumber.endIndex
        
        for char in mask where startIndex < endIndex {
            if char == "X" {
                result.append(cleanNumber[startIndex])
                startIndex = cleanNumber.index(after: startIndex)
            } else {
                result.append(char)
            }
        }
        return result
    }
    
    func applyPatternOnNumbers(pattern: String, replacementCharacter: Character) -> String {
          var pureNumber = self.replacingOccurrences( of: "[^0-9]", with: "", options: .regularExpression)
          for index in 0 ..< pattern.count {
              guard index < pureNumber.count else { return pureNumber }
              let stringIndex = String.Index(utf16Offset: index, in: pattern)
              let patternCharacter = pattern[stringIndex]
              guard patternCharacter != replacementCharacter else { continue }
              pureNumber.insert(patternCharacter, at: stringIndex)
          }
          return pureNumber
      }
    
    func changeToBackPhone() -> String {
        var phone = "+"
        for i in self {
            if i.isNumber {
                phone += String(i)
            }
        }
        return phone
    }
}
