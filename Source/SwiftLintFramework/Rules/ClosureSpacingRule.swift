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
    let branceKind: Character
    let range: NSRange
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
        var timer00 = CFAbsoluteTimeGetCurrent()

        // find all lines and accurences of open { and closed } braces
        var linesWithBraces = [(Line, [BraceIndex])]()

        let openBraces = file.matchPattern("\\{").map { BraceIndex(branceKind: "{", range: $0.0) }
                                        //excludingSyntaxKinds: SyntaxKind.commentAndStringKinds())
//                                        .map { BraceIndex(branceKind: "{", range: $0) }
print("BLOCK 01", terminator:":   "); let timer01 = CFAbsoluteTimeGetCurrent(); print( Double(timer01 - timer00 ) * 1000 )

        let closeBraces = file.matchPattern("\\}",
                                        excludingSyntaxKinds: SyntaxKind.commentAndStringKinds())
                                        .map { BraceIndex(branceKind: "}", range: $0) }
print("BLOCK 02", terminator:":   "); let timer02 = CFAbsoluteTimeGetCurrent(); print( Double(timer02 - timer01 ) * 1000 )
      
        var allbraces = ( openBraces + closeBraces ).sort{ $0.range.location < $1.range.location }
        
print("BLOCK 03", terminator:":   "); let timer03 = CFAbsoluteTimeGetCurrent(); print( Double(timer03 - timer02 ) * 1000 )
        
//        var allbraces = testingAll.map {$0.range}.map { BraceIndex(branceKind: "{", range: $0)}
        var currentIndexOnAllBraces = 0
        for eachLine in file.lines {
            var bracesInLine = [BraceIndex]()
            innerLoop:for eachIndex in currentIndexOnAllBraces..<allbraces.count {
                if eachLine.range.intersectsRange(allbraces[eachIndex].range) {
                    bracesInLine.append(allbraces[eachIndex])
                    currentIndexOnAllBraces += 1
                } else {
                 break innerLoop
                }
            }
            linesWithBraces.append((eachLine, bracesInLine))
        }
 /*BLOCK CLOCK*/ let timer04 = CFAbsoluteTimeGetCurrent(); print( Double(timer04 - timer03 ) * 1000 )

        // matching up ranges of {}
        var violationRanges = linesWithBraces.flatMap { self.matchBraces($0.1, file:file ) }
                .filter {                       //removes enclosing brances to just content
                let content = file.contents.substring($0.location + 1, length: $0.length - 2)
                if content.isEmpty { return false } // case when {} is not a closure
                let cleaned = content.stringByTrimmingCharactersInSet(.whitespaceCharacterSet())
                return content == cleaned
                    }

        violationRanges = file.ruleEnabledViolatingRanges(violationRanges, forRule: self)
 /*BLOCK CLOCK*/ let timer05 = CFAbsoluteTimeGetCurrent(); print( Double(timer05 - timer04 ) * 1000 )

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
            var ranges = [NSRange]()
            var indexes = input
            var bracesAsString = indexes.map { String($0.branceKind) }.joinWithSeparator("")

            while let foundRange = bracesAsString.rangeOfString("{}") {
                let startIndex = bracesAsString.startIndex.distanceTo(foundRange.startIndex)
                let location = indexes[startIndex].range.location
                let length = indexes[startIndex + 1 ].range.location + 1 - location
                ranges.append(NSRange(location:location, length: length))
                bracesAsString.replaceRange(foundRange, with: "")
                indexes.removeRange(startIndex...startIndex  + 1)
            }
            return ranges
        }
}
