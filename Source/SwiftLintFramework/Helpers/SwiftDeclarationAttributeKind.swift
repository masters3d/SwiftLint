//
//  SwiftDeclarationAttributeKind.swift
//  sourcekitten
//
//  Created by Daniel Metzing on 10/02/18.
//  Copyright © 2018 Realm. All rights reserved.
//

import SourceKittenFramework

/// Swift declaration kinds.
/// Found in `strings SourceKitService | grep source.decl.attribute.`.
public enum SwiftDeclarationAttributeKind: String, SwiftLangSyntax  { // TODO: Get `SwiftDeclarationAttribute` for Swift 4.1
                                                                      // TODO: Maybe this should go to SourceKitten ??
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
    case openSetter         = "source.decl.attribute.setter_access.open"
    case fileprivateSetter  = "source.decl.attribute.setter_access.fileprivate"
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
    case `fileprivate`      = "source.decl.attribute.fileprivate"
}

extension SwiftDeclarationAttributeKind {
    internal enum Group: Int {
        case acl
        case setterACL
        case mutators
        case owned
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
                        .fileprivate,
                        .internal,
                        .public,
                        .open]
            case .setterACL:
                return [.privateSetter,
                        .internalSetter,
                        .publicSetter,
                        .fileprivateSetter,
                        .openSetter]
            case .mutators:
                return [.mutating,
                        .nonmutating]
            case .override:
                return [.override]
            case .owned:
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
                return []
            }
        }

        static var allValues: [SwiftDeclarationAttributeKind.Group] {
            return [.acl,
                    .setterACL,
                    .mutators,
                    .override,
                    .owned,
                    .objcInteroperability,
                    .availability,
                    .final,
                    .interfaceBuilder,
                    .typeMethods]
        }
    }
}
