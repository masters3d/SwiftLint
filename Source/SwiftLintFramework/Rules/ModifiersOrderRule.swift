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
public enum SwiftDeclarationAttributeKind: String, SwiftLangSyntax  { // TODO: Need to check what happens with `class` and `static`
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
    case privateSetter      = "source.decl.attribute.setter_access.private"
    case internalSetter     = "source.decl.attribute.setter_access.internal"
    case publicSetter       = "source.decl.attribute.setter_access.public"
    case `ibaction`         = "source.decl.attribute.ibaction"
    case `iboutlet`         = "source.decl.attribute.iboutlet"
    case `ibdesignable`     = "source.decl.attribute.ibdesignable"
    case `ibinspectable`    = "source.decl.attribute.ibinspectable"
    case `objc`             = "source.decl.attribute.objc" // TODO: This always has to be first. How to handle this case?
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
}

// TODO: Get the possible groups of attribute kinds
public enum SwiftDeclarationAttributeKindGroup {
    case acl
    case setterACL
    case mutators
    case memoryReference
    case `override`

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
        case .memoryReference:
            return [.weak]
        case .override:
            return [.override]
        }
    }

    static var allValues: [SwiftDeclarationAttributeKindGroup] {
        return [.acl, .setterACL, .mutators, .override]
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
            "@objc \n override public private(set) weak var foo: Bar?\n @objc \npublic final class MyClass: NSObject {\n }",
            "@objc \npublic final class MyClass: NSObject {\n" +
                "private final func myFinal() {}\n" +
                "weak var myWeak: NSString? = nil\n" +
            "public static let nnumber = 3 \n }",

            "public final class MyClass {}"
        ],
        triggeringExamples: [
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

    private let observedDeclarationKinds: [SwiftDeclarationKind] =  [.class,
                                                                     .enum,
                                                                     .extension,
                                                                     .protocol,
                                                                     .functionConstructor,
                                                                     .functionDestructor,
                                                                     .functionMethodClass,
                                                                     .functionMethodInstance,
                                                                     .functionMethodStatic,
                                                                     .functionOperator,
                                                                     .functionSubscript,
                                                                     .struct,
                                                                     .varClass,
                                                                     .varGlobal,
                                                                     .varInstance,
                                                                     .varLocal,
                                                                     .varParameter,
                                                                     .varStatic]

    public func validate(file: File,
                         kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {

        guard observedDeclarationKinds.contains(kind),
              let offset = dictionary.offset else {
            return []
        }

        let preferedOrderOfModifiers = configuration.beforeACL
                                       .compactMap { return group(of: $0) }
                                       + [.acl]
                                       + configuration.afterACL
                                       .compactMap { return group(of: $0) }

        for (index, group) in preferedOrderOfModifiers.enumerated() {
            guard let groupIndex = findIndex(of: group, in: dictionary.enclosedSwiftAttributesWithMetaData) else { continue }
            if groupIndex != index {
                return [StyleViolation(ruleDescription: type(of: self).description,
                                       severity: configuration.severityConfiguration.severity,
                                       location: Location(file: file, byteOffset: offset))]
            }
        }

        return []
    }

    private func findIndex(of group: SwiftDeclarationAttributeKindGroup, in declarationAttributes: [[String: SourceKitRepresentable]]) -> Int? {
        return declarationAttributes
            .sorted {
                guard let rhsOffset = $0["key.offset"] as? Int64, let lhsOffset = $1["key.offset"] as? Int64 else { return false }
                return rhsOffset < lhsOffset
            }
            .compactMap { modifierOrMetaData -> SwiftDeclarationAttributeKind? in
                guard let attribute = modifierOrMetaData["key.attribute"] as? String else { return nil }
                return SwiftDeclarationAttributeKind(rawValue: attribute)
            }
            .index {
                group.swiftDeclarationAttributeKinds.contains($0)
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
}
