//
//  SwiftDeclarationAttributeKind+Swiftlint.swift
//  SwiftLint
//
//  Created by Daniel.Metzing on 04/08/18.
//  Copyright © 2018 Realm. All rights reserved.
//

import SourceKittenFramework

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

        var swiftDeclarationAttributeKinds: Set<SwiftDeclarationAttributeKind> {
            switch self {
            case .acl:
                return [.private,
                        .fileprivate,
                        .internal,
                        .public,
                        .open]
            case .setterACL:
                return [.setterPrivate,
                        .setterFilePrivate,
                        .setterInternal,
                        .setterPublic,
                        .setterOpen
                        ]
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

        static var allValues: Set<SwiftDeclarationAttributeKind.Group> {
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
