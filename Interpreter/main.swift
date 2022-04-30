import Foundation

let toInterpret = try! String.init(contentsOfFile: "/Users/michel/Desktop/test.qs")

let scanner = Scanner(source: toInterpret)
let (tokens, errors) = scanner.scanTokens()
debugPrintTokens(tokens: tokens)
print(errors)

let parser = Parser(tokens: tokens)
parser.parse()
