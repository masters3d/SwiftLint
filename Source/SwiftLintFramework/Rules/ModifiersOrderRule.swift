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
    case `ibaction`         = "source.decl.attribute.ibaction"
    case `iboutlet`         = "source.decl.attribute.iboutlet"
    case `ibdesignable`     = "source.decl.attribute.ibdesignable"
    case `ibinspectable`    = "source.decl.attribute.ibinspectable"
    case `objc`             = "source.decl.attribute.objc"
    case name               = "source.decl.attribute.objc.name"
    case available          = "source.decl.attribute.available"
    case `final`            = "source.decl.attribute.final"
    case `required`         = "source.decl.attribute.required"
    case `optional`         = "source.decl.attribute.optional"
    case noreturn           = "source.decl.attribute.noreturn"
    case `NSManaged`        = "source.decl.attribute.NSManaged"
    case `lazy`             = "source.decl.attribute.lazy"
    case `dynamic`          = "source.decl.attribute.dynamic"
    case infix              = "source.decl.attribute.infix"
    case prefix             = "source.decl.attribute.prefix"
    case postfix            = "source.decl.attribute.postfix"
    case autoclosure        = "source.decl.attribute.autoclosure"
    case noescape           = "source.decl.attribute.noescape"
    case nonobjc            = "source.decl.attribute.nonobjc"
    case objcMembers        = "source.decl.attribute.objcMembers"
    case `mutating`         = "source.decl.attribute.mutating"
    case `nonmutating`      = "source.decl.attribute.nonmutating"
    case `convenience`      = "source.decl.attribute.convenience"
    case `override`         = "source.decl.attribute.override"
    case `weak`             = "source.decl.attribute.weak"
    case `testable`         = "source.decl.attribute.testable"
    case privateSetter      = "source.decl.attribute.setter_access.private"
    case `public`           = "source.decl.attribute.public"
    case `private`          = "source.decl.attribute.private"
    case `internal`         = "source.decl.attribute.internal"
    case `open`             = "source.decl.attribute.open"
}

extension SwiftDeclarationAttributeKind {
    static var ACLs: [SwiftDeclarationAttributeKind] {
        return [.private,
                .internal,
                .public,
                .open]
    }

    static var mutators: [SwiftDeclarationAttributeKind] {
        return [.mutating,
                .nonmutating]
    }

    static var overrides: [SwiftDeclarationAttributeKind] {
        return [.override]
>>>>>>> Stashed changes
    }
}

// TODO: Get the possible groups of attribute kinds
public enum SwiftDeclarationAttributeKindGroup {
    case acl
    case mutators
    case `override`

    var swiftDeclarationAttributeKinds: [SwiftDeclarationAttributeKind] {
        switch self {
        case .acl:
            return SwiftDeclarationAttributeKind.ACLs
        case .mutators:
            return SwiftDeclarationAttributeKind.mutators
        case .override:
            return SwiftDeclarationAttributeKind.overrides
        }
    }
}

public struct ModifiersOrderRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public init() { }
    public var configuration = ModifiersOrderConfiguration(beforeACL: ["override"], afterACL: [])
    public static let description = RuleDescription(
        identifier: "modifiers_order",
        name: "Modifiers Order",
        description: "Modifiers order should be consistent.", kind: RuleKind.style,
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

        guard observedDeclarationKinds.contains(kind) else {
            return []
        }

        let enclosedSwiftAttributesWithMetaData = dictionary.enclosedSwiftAttributesWithMetaData
        let aclIndex = findIndex(of: .acl, in: enclosedSwiftAttributesWithMetaData)
        print("\(String(describing: aclIndex))")
        // TODO: 1. Get indexes that could be in front of ACL
        //       2. Check if any of them is after ACL or not
        return []
    }

    func findIndex(of group: SwiftDeclarationAttributeKindGroup, in declarationAttributes: [[String: SourceKitRepresentable]]) -> Int? {
        let ordered = order(declarationAttributes: declarationAttributes)
        let modifiers = ordered.compactMap { attributeOrMetaData -> SwiftDeclarationAttributeKind? in
            if let attribute = attributeOrMetaData["key.attribute"] as? String {
                return SwiftDeclarationAttributeKind(rawValue: attribute)
            }
            return nil
        }

        let groupIndex = modifiers.index { return group.swiftDeclarationAttributeKinds.contains($0) }
        return groupIndex
    }

    private func order(declarationAttributes: [[String: SourceKitRepresentable]]) ->  [[String: SourceKitRepresentable]] {
        return declarationAttributes.sorted(by: { rhs, lhs in
            guard let rhsOffset = rhs["key.offset"] as? Int64,
                let lhsOffset = lhs["key.offset"] as? Int64 else {
                    return false
            }
            return rhsOffset < lhsOffset
        })
    }
}
