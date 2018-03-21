//
//  ModifiersOrderRule.swift
//  SwiftLint
//
//  Created by Jose Cheyo Jimenez on 05/06/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

// TODO: Get somehow `SwiftDeclarationAttribute` for Swift 4.1
public enum SwiftDeclarationAttributeKind: String, SwiftLangSyntax  {
    case NSManaged          = "source.decl.attribute.NSManaged"
    case name               = "source.decl.attribute.objc.name"
    case available          = "source.decl.attribute.available"
    case infix              = "source.decl.attribute.infix"
    case prefix             = "source.decl.attribute.prefix"
    case postfix            = "source.decl.attribute.postfix"
    case autoclosure        = "source.decl.attribute.autoclosure"
    case noescape           = "source.decl.attribute.noescape"
    case nonobjc            = "source.decl.attribute.nonobjc"
    case objcMembers        = "source.decl.attribute.objcMembers"
    case `objc`             = "source.decl.attribute.objc"
    case privateSetter      = "source.decl.attribute.setter_access.private"
    case internalSetter     = "source.decl.attribute.setter_access.internal"
    case publicSetter       = "source.decl.attribute.setter_access.public"
    case ibaction           = "source.decl.attribute.ibaction"
    case iboutlet           = "source.decl.attribute.iboutlet"
    case ibdesignable       = "source.decl.attribute.ibdesignable"
    case ibinspectable      = "source.decl.attribute.ibinspectable"
    case `final`            = "source.decl.attribute.final"
    case `required`         = "source.decl.attribute.required"
    case `optional`         = "source.decl.attribute.optional"
    case noreturn           = "source.decl.attribute.noreturn"
    case `lazy`             = "source.decl.attribute.lazy"
    case `dynamic`          = "source.decl.attribute.dynamic"
    case `mutating`         = "source.decl.attribute.mutating"
    case `nonmutating`      = "source.decl.attribute.nonmutating"
    case `convenience`      = "source.decl.attribute.convenience"
    case `override`         = "source.decl.attribute.override"
    case `weak`             = "source.decl.attribute.weak"
    case `testable`         = "source.decl.attribute.testable"
    case `public`           = "source.decl.attribute.public"
    case `private`          = "source.decl.attribute.private"
    case `internal`         = "source.decl.attribute.internal"
    case `open`             = "source.decl.attribute.open"

    // TODO: Discuss the option of these "fake" cases
    case `static`           = "source.decl.attribute.static"
    case `class`            = "source.decl.attribute.class"
}

// TODO: Get the possible groups of attribute kinds
public enum SwiftDeclarationAttributeKindGroup: Int {
    case acl
    case setterACL
    case mutators
    case memoryReference
    case `override`
    case objcInteroperability
    case availability
    case final
    case interfaceBuilder
    case typeMethods

    var swiftDeclarationAttributeKinds: [SwiftDeclarationAttributeKind] {
        switch self {
        case .acl:
            return [.private,
                    .internal,
                    .public,
                    .open]
        case .setterACL:
            return [.privateSetter,
                    .internalSetter,
                    .publicSetter]
        case .mutators:
            return [.mutating,
                    .nonmutating]
        case .override:
            return [.override]
        case .memoryReference:
            return [.weak]
        case .objcInteroperability:
            return [.objc,
                    .nonobjc,
                    .objcMembers]
        case .availability:
            return [.available]
        case .final:
            return [.final]
        case .interfaceBuilder:
            return [.ibaction,
                    .iboutlet,
                    .ibdesignable,
                    .ibinspectable]
        case .typeMethods:
            return [.static,
                    .class]
        }
    }

    static var allValues: [SwiftDeclarationAttributeKindGroup] {
        return [.acl,
                .setterACL,
                .mutators,
                .override,
                .memoryReference,
                .objcInteroperability,
                .availability,
                .final,
                .interfaceBuilder,
                .typeMethods]
    }
}

public struct ModifiersOrderRule: ASTRule, OptInRule, ConfigurationProviderRule {

    public init() { }
    public var configuration = ModifiersOrderConfiguration(beforeACL: ["override"], afterACL: [])
    public static let description = RuleDescription(
        identifier: "modifiers_order",
        name: "Modifiers Order",
        description: "Modifiers order should be consistent.",
        kind: .style,
        nonTriggeringExamples: [
            "public static let nnumber = 3 \n",
            "@objc \npublic final class MyClass: NSObject {\n }",
            "@objc \n override public private(set) weak var foo: Bar?\n",
            "@objc \npublic final class MyClass: NSObject {\n }",
            "@objc \npublic final class MyClass: NSObject {\n" +
                "private final func myFinal() {}\n" +
                "weak var myWeak: NSString? = nil\n" +
            "public static let nnumber = 3 \n }",
            "public final class MyClass {}"
        ],
        triggeringExamples: [
            "static public let nnnumber = 3 \n",
            "@objc \npublic final class MyClass: NSObject {\n" +
            "final private func myFinal() {}\n}",
            "@objc \nfinal public class MyClass: NSObject {}\n",
            "final public class MyClass {}\n",
            "class MyClass {" +
            "weak internal var myWeak: NSString? = nil\n}",
            "class MyClass {" +
            "static public let nnumber = 3 \n }"
        ]
    )

    enum UnrecoginzedModifierKeywords: String {
        case `static` = "static"
        case `class` = "class"

        var declarationAttributeKind: SwiftDeclarationAttributeKind {
            switch self {
            case .class:
                return .class
            case .static:
                return .static
            }
        }
    }

    public func validate(file: File,
                          kind: SwiftDeclarationKind,
                          dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {

        guard let offset = dictionary.offset else {
            return []
        }
        

        let updatedDictionary = updateIfNeeded(in: file, dictionary: dictionary, for: [.class, .static])

        let preferedOrderOfModifiers = [.objcInteroperability, .interfaceBuilder]
            + configuration.beforeACL
                .compactMap { return group(of: $0) }
            + [.acl]
            + configuration.afterACL
                .compactMap { return group(of: $0) }

        let modifierGroupsInDeclaration = findModifierGroups(in: updatedDictionary.enclosedSwiftAttributesWithMetaData)
        let filteredPreferedOrderOfModifiers = preferedOrderOfModifiers.filter { return modifierGroupsInDeclaration.contains($0) }

        for (index, preferedGroup) in filteredPreferedOrderOfModifiers.enumerated() {
            if preferedGroup != modifierGroupsInDeclaration[index] {
                return [StyleViolation(ruleDescription: type(of: self).description,
                                       severity: configuration.severityConfiguration.severity,
                                       location: Location(file: file, byteOffset: offset))]
            }
        }

        return []
    }

    private func findModifierGroups(in declarationAttributes: [[String: SourceKitRepresentable]]) -> [SwiftDeclarationAttributeKindGroup] {
        return orderAndTransform(declarationAttributes: declarationAttributes)
            .compactMap {
                for declarationAttributeKindGroup in SwiftDeclarationAttributeKindGroup.allValues where declarationAttributeKindGroup.swiftDeclarationAttributeKinds.contains($0) {
                    return declarationAttributeKindGroup
                }
                return nil
        }
    }

    private func orderAndTransform(declarationAttributes: [[String: SourceKitRepresentable]]) -> [SwiftDeclarationAttributeKind] {
        return declarationAttributes
            .sorted {
                guard let rhsOffset = $0["key.offset"] as? Int64, let lhsOffset = $1["key.offset"] as? Int64 else { return false }
                return rhsOffset < lhsOffset
            }
            .compactMap { modifierOrMetaData -> SwiftDeclarationAttributeKind? in
                guard let attribute = modifierOrMetaData["key.attribute"] as? String else { return nil }
                return SwiftDeclarationAttributeKind(rawValue: attribute)
        }
    }

    private func group(of rawAttribute: String) -> SwiftDeclarationAttributeKindGroup? {
        for value in SwiftDeclarationAttributeKindGroup.allValues {
            for attributeKind in value.swiftDeclarationAttributeKinds where attributeKind.rawValue.hasSuffix(rawAttribute) {
                return value
            }
        }
        return nil
    }

    // TODO: What to do with these hacks only for static and class modifiers?
    private func updateIfNeeded(in file: File,
                                dictionary: [String: SourceKitRepresentable],
                                for keywords: [UnrecoginzedModifierKeywords]) -> [String: SourceKitRepresentable] {

        guard dictionary.kind != SwiftDeclarationKind.class.rawValue else { return dictionary }
        var updatedDictionary = dictionary
        for keyword in keywords {
            let matches = find(keyword: keyword, in: file)
            let matchedDeclaration = matches.first {
                guard let nameOffset = dictionary.nameOffset else { return false }
                return $0.range.contains(nameOffset)
            }

            // Fake a class or static attribute in the structure dictionary
            if let match = matchedDeclaration {
                let attribute: [String: SourceKitRepresentable] = ["key.attribute": keyword.declarationAttributeKind.rawValue,
                                                                   "key.offset": Int64(match.range.location),
                                                                   "key.length": Int64(keyword.rawValue.count)]
                if var attributes = updatedDictionary["key.attributes"] as? [[String: SourceKitRepresentable]] {
                    attributes.append(attribute)
                    updatedDictionary["key.attributes"] = attributes
                }
            }
        }

        return updatedDictionary
    }

    private func find(keyword: UnrecoginzedModifierKeywords, in file: File) -> [NSTextCheckingResult] {
        // Pattern idea: match everything if it contains with static or class until the first newline
        let pattern = "(?:\(keyword.rawValue))(?:.*(\\n|,|\\{|))"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
        let fileRange = NSRange(location: 0, length: file.contents.bridge().length)
        let matches = regex.matches(in: file.contents, options: [], range: fileRange)

        return matches
    }
}
