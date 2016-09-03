//
//  ClosureSpacingRule.swift
//  SwiftLint
//
//  Created by J. Cheyo Jimenez on 2016-08-26.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

extension File {
    private func allBracesWithInRange(range: NSRange) -> [NSRange] {
        
        let syntaxKinds = SyntaxKind.commentAndStringKinds()
        return allBracesRangesAndTokens(range)
        .map { range, tokens in
            (range, tokens.flatMap { SyntaxKind(rawValue: $0.type) })}
        .filter { $0.1.filter(syntaxKinds.contains).isEmpty }
        .map { $0.0 }
    }
    
    private func allBracesRangesAndTokens(range:NSRange) ->
    [(NSRange, [SyntaxToken])] {
        let pattern = "\\{|\\}"
        return rangesAndTokensMatching(pattern, range: range)
    }
    
    private func allBracesRances(inRange: NSRange) -> [NSRange] {
        let pattern = regex("\\{|\\}")
       return pattern.matchesInString(self.contents, options: [],
                            range: inRange).map { $0.range }
    }

}

private extension String {
    
 func firstIndexOf(search: String) -> Int? {
        if let range = rangeOfString(search, options: [.LiteralSearch]) {
            return startIndex.distanceTo(range.startIndex)
        }
        return nil
    }
    
  func findFirstAndLastBrace() -> NSRange? {
    if let start = firstIndexOf("{"),
        let end = self.lastIndexOf("}")
        where start < end {
            return NSRange(start...end)
        }
     else { return nil }
    }
}


public struct ClosureSpacingRule: Rule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.Warning)

    public init() {}

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
    let kidsToExclude = SyntaxKind.commentAndStringKinds().map {$0.rawValue}
var timer00 = CFAbsoluteTimeGetCurrent()

        var linesWithBraces = [[NSRange]]()
        // find all lines and accurences of open { and closed } braces
        
        
        for eachLine in file.lines {
            guard let localRange = eachLine.content.findFirstAndLastBrace()
                else { continue }
            
            let fileRange = NSRange(location: localRange.location + eachLine.range.location,
                                      length: localRange.length)
            let bracesTokes = file.allBracesRangesAndTokens(fileRange).filter {
                                    Set($0.1.map{$0.type}).isDisjointWith(kidsToExclude)
                                }.map { $0.0 }
            linesWithBraces.append(bracesTokes)
       }
        
print("BLOCK 01", terminator:":   "); let timer01 = CFAbsoluteTimeGetCurrent(); print( Double(timer01 - timer00 ) * 1000 )


print("BLOCK 02", terminator:":   "); let timer02 = CFAbsoluteTimeGetCurrent(); print( Double(timer02 - timer01 ) * 1000 )

print("BLOCK 03", terminator:":   "); let timer03 = CFAbsoluteTimeGetCurrent(); print( Double(timer03 - timer02 ) * 1000 )

print("BLOCK 04", terminator:":   ");let timer04 = CFAbsoluteTimeGetCurrent(); print( Double(timer04 - timer03 ) * 1000 )

 // match open braces to closing braces
        func matchBraces(input: [NSRange] ) -> [NSRange] {
            if input.isEmpty { return [] }
            var ranges = [NSRange]()
            var indexes = input
            var bracesAsString = indexes.map { file.contents.substring($0.location,
                                                        length: $0.length) }.joinWithSeparator("")
            while let foundRange = bracesAsString.rangeOfString("{}") {
                let startIndex = bracesAsString.startIndex.distanceTo(foundRange.startIndex)
                let location = indexes[startIndex].location
                let length = indexes[startIndex + 1 ].location + 1 - location
                ranges.append(NSRange(location:location, length: length))
                bracesAsString.replaceRange(foundRange, with: "")
                indexes.removeRange(startIndex...startIndex  + 1)
            }
            return ranges
        }

        // matching up ranges of {}
        var violationRanges = linesWithBraces.flatMap { matchBraces($0) }
                .filter {                       //removes enclosing brances to just content
                let content = file.contents.substring($0.location + 1, length: $0.length - 2)
                if content.isEmpty { return false } // case when {} is not a closure
                let cleaned = content.stringByTrimmingCharactersInSet(.whitespaceCharacterSet())
                return content != " " + cleaned + " "
                }

        violationRanges = file.ruleEnabledViolatingRanges(violationRanges, forRule: self)
print("BLOCK 05", terminator:":   ");let timer05 = CFAbsoluteTimeGetCurrent(); print( Double(timer05 - timer04 ) * 1000 )

        return violationRanges.flatMap { StyleViolation(
                                        ruleDescription: self.dynamicType.description,
                                        severity: configuration.severity,
                                        location: Location(file: file, characterOffset: $0.location)
                                        )}
        }

}
