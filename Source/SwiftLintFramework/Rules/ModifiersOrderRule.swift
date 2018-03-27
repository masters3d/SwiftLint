//
//  ModifiersOrderRule.swift
//  SwiftLint
//
//  Created by Jose Cheyo Jimenez on 05/06/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

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
            "class Foo { \n static public let bar = 3 {} \n }",
            "class Foo { \n class override public let bar = 3 {} \n }",
            "class Foo { \n overide static final public var foo: String {} \n }",
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

        static func attribute(for declarationKind: SwiftDeclarationKind) -> UnrecoginzedModifierKeywords? {
            switch declarationKind {
            case .functionMethodClass, .varClass:
                return .class
            case .functionMethodStatic, .varStatic:
                return .static
            default:
                return nil
            }
        }
    }

    public func validate(file: File,
                          kind: SwiftDeclarationKind,
                          dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {

        guard let offset = dictionary.offset else {
            return []
        }

        print(dictionary)
        let updatedDictionary = updateIfNeeded(dictionary)

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

    private func updateIfNeeded(_ dictionary: [String: SourceKitRepresentable]) -> [String: SourceKitRepresentable] {

        guard let rawKind = dictionary.kind,
              let kind = SwiftDeclarationKind(rawValue: rawKind),
              let offset = dictionary.offset else {
            return dictionary
        }
        let searchedKinds: [SwiftDeclarationKind] = [.functionMethodClass,
                                                     .functionMethodStatic,
                                                     .varClass,
                                                     .varStatic]
        var updatedDictionary = dictionary
        if searchedKinds.contains(kind), let keyword = UnrecoginzedModifierKeywords.attribute(for: kind) {
            let attribute: [String: SourceKitRepresentable] = ["key.attribute": keyword.declarationAttributeKind.rawValue,
                                                               "key.offset": Int64(offset),
                                                               "key.length": Int64(keyword.rawValue.count)]
            if var attributes = updatedDictionary["key.attributes"] as? [[String: SourceKitRepresentable]] {
                attributes.append(attribute)
                updatedDictionary["key.attributes"] = attributes
            }
        }
        return updatedDictionary
    }
}
