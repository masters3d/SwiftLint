//
//  SwiftDeclarationAttributeKindsGroup.swift
//  swiftlint
//
//  Created by Daniel.Metzing on 27.03.18.
//  Copyright © 2018 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public enum SwiftDeclarationAttributeKindsGroup: Int {
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
            return []
        }
    }

    static var allValues: [SwiftDeclarationAttributeKindsGroup] {
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
