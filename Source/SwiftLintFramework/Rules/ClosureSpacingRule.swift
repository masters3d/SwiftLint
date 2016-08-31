//
//  ClosureSpacingRule.swift
//  SwiftLint
//
//  Created by J. Cheyo Jimenez on 2016-08-26.
//  Copyright © 2016 Realm. All rights reserved.
//

private extension String {
  func firstIndexOf(search: String) -> Int? {
        if let range = rangeOfString(search, options: [.LiteralSearch]) {
            return startIndex.distanceTo(range.startIndex)
        }
        return nil
    }
}

private extension String {
    // find all index occurrances of serach string
   private func findAllIndexes(search: String,
                                searchRange: Range<Index>, result: [Int] = []) -> [Int] {
        var result = result
        if let range = rangeOfString(search, options: .LiteralSearch, range: searchRange) {
            result.append(startIndex.distanceTo(range.startIndex))
         result =  findAllIndexes(search,
                    searchRange: range.startIndex.successor()..<endIndex, result: result)
        }
    return result
    }

}

private struct BraceIndex {
    private enum Brace {
        case open
        case close
    func braceChar() -> String {
        switch self {
            case .open:
                return "{"
            case .close:
                return "}"
            }
        }
    }

    let brance: Brace
    let index: Int
}

import Foundation
import SourceKittenFramework

public struct ClosureSpacingRule: Rule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.Warning)

    public init() { }

    public static let description = RuleDescription(
        identifier: "closure_spacing",
        name: "Closure Spacing",
        description: "Closure expressions should have consistent spacing",
        nonTriggeringExamples: [
            "[].map({ $0.description })",
            "[].filter { $0.contains(location) }"
        ],
        triggeringExamples: [
            "[].filter({$0.contains(location)})",
            "[].map({$0})"
          ]
//        ],
//        corrections: [
//             "[].filter({$0.description})" : "[].filter({ $0.description })",
//             "[].map({$0})" : "[].map({ $0 })"
//        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {

        //filter out lines where rule is disabled
        let lines = file.lines.filter {
                !file.ruleEnabledViolatingRanges([$0.range], forRule: self).isEmpty }

        // find all lines and accurences of open { and closed } braces
        var linesWithBraces = [(Line, [BraceIndex])]()
        for eachLine in lines {
            if let start = eachLine.content.rangeOfString("{",
                                                options: [.LiteralSearch])?.startIndex,
               let end = eachLine.content.rangeOfString("}",
                                options: [.LiteralSearch, .BackwardsSearch])?.endIndex
                where start < end { // filter out lines like '} else {'

                    let openBraces = eachLine.content.findAllIndexes("{",
                                   searchRange: start..<end).flatMap {
                                   BraceIndex(brance: .open, index: $0 + eachLine.range.location) }
                    let closedBraces = eachLine.content.findAllIndexes("}",
                                   searchRange: start..<end).flatMap {
                                   BraceIndex(brance: .close, index: $0 + eachLine.range.location) }
                    let brances = (openBraces + closedBraces).sort { $0.index < $1.index }

                    linesWithBraces.append(( eachLine, brances ))
               }
        }

        // filter out lines disabled and braces in comments and strings
        linesWithBraces = linesWithBraces.filter {
                            !file.ruleEnabledViolatingRanges([$0.0.range], forRule: self).isEmpty }

        // matching up ranges of {}
        let violationRanges = linesWithBraces.flatMap { self.matchBraces($0.1, file:file ) }
                .filter {                       //removes enclosing brances to just content
                let content = file.contents.substring($0.location + 1, length: $0.length - 2)
                if content.isEmpty { return false } // case when {} is not a closure
                let cleaned = content.stringByTrimmingCharactersInSet(.whitespaceCharacterSet())
                return content == cleaned
                    }

        return violationRanges.flatMap { StyleViolation(
                                        ruleDescription: self.dynamicType.description,
                                        severity: configuration.severity,
                                        location: Location(file: file, characterOffset: $0.location)
                                        )}
        }

}

private extension ClosureSpacingRule {

        // match open braces to closing braces
        func matchBraces(input: [BraceIndex], file: File ) -> [NSRange] {
            if input.isEmpty { return [] }
            let syntax = file.syntaxMap
            let nsstring = file.contents

            //filter out occurences of { and } in comments or strings
            func filterOutStringAndComments(input: [BraceIndex]) -> [BraceIndex] {
                return input.filter {
                   guard let byteRange = nsstring.NSRangeToByteRange(start: $0.index, length: 1)
                        else { return false }
                    let tokensIn = syntax.tokensIn(byteRange)
                    let syntaxTokens = tokensIn.flatMap { SyntaxKind(rawValue: $0.type) }
                return Set(SyntaxKind.commentAndStringKinds()).isDisjointWith( syntaxTokens )
                }
            }
            var ranges = [NSRange]()
            var indexes = filterOutStringAndComments(input)
            var bracesAsString = indexes.map { $0.brance.braceChar() }.joinWithSeparator("")

            while let foundRange = bracesAsString.rangeOfString("{}") {
                let startIndex = bracesAsString.startIndex.distanceTo(foundRange.startIndex)
                let location = indexes[startIndex].index
                let length = indexes[startIndex + 1 ].index + 1 - location
                ranges.append(NSRange(location:location, length: length))
                bracesAsString.replaceRange(foundRange, with: "")
                indexes.removeRange(startIndex...startIndex  + 1)
            }
            return ranges
        }
}
