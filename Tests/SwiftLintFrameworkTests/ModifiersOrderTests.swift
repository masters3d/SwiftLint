//
//  ModifiersOrderTests.swift
//  SwiftLint
//
//  Created by Jose Cheyo Jimenez on 06/05/17.
//  Copyright © 2017 Realm. All rights reserved.
//

@testable import SwiftLintFramework
import XCTest

class ModifiersOrderTests: XCTestCase {

    func testAttibuteStatic() {
        // testing static attribute position
        let descriptionOverride = RuleDescription(
            identifier: "modifiers_order",
            name: "Modifiers Order",
            description: "Modifiers order should be consistent.",
            kind: .style,
            nonTriggeringExamples: [
                "public class SomeClass { \n" +
                    "    static public func someFunc() {} \n" +
                "}",
                "public class SomeClass { \n" +
                    "    class public func someFunc() {} \n" +
                "}"
            ],
            triggeringExamples: [
                "public class SomeClass { \n" +
                    "    public static func someFunc() {} \n" +
                "}",
                "public class SomeClass { \n" +
                    "    public class func someFunc() {} \n" +
                "}"
            ]
        )

        verifyRule(descriptionOverride,
                   ruleConfiguration: ["prefered_modifiers_order": ["typeMethods", "acl"]])
    }

    func testRightOrderedModifierGroups() {
        // testing modifiers ordered to the right from the ACL
        let descriptionOverride = RuleDescription(
            identifier: "modifiers_order",
            name: "Modifiers Order",
            description: "Modifiers order should be consistent.",
            kind: .style,
            nonTriggeringExamples: [
                "public protocol Foo: class {} \n" +
                "public weak internal(set) var bar: Foo? \n",
                "open final class Foo {" +
                    "fileprivate static  func bar() {} \n" +
                "open class func barFoo() {} }",
                "public struct Foo {" +
                "private mutating func bar() {} }",
                "public static let nnumber = 3 \n",
                "@objc \npublic final class MyClass: NSObject {\n }",
                "@objc \n override public private(set) weak var foo: Bar?\n",
                "@objc \npublic final class MyClass: NSObject {\n }",
                "@objc \npublic final class MyClass: NSObject {\n" +
                    "private final func myFinal() {}\n" +
                    "weak var myWeak: NSString? = nil\n" +
                "public static let nnumber = 3 \n }",
                "public final class MyClass {}",
                "class RootClass { func myFinal() {}}\n" +
                    "internal class MyClass: RootClass {" +
                "override internal func myFinal() {}}"
            ],
            triggeringExamples: [
                "public protocol Foo: class {} \n" +
                "public internal(set) weak var bar: Foo? \n",
                "final public class Foo {" +
                    "static fileprivate func bar() {} \n" +
                "class open func barFoo() {} }",
                "public struct Foo {" +
                "mutating private func bar() {} }",
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

        verifyRule(descriptionOverride,
                   ruleConfiguration: ["prefered_modifiers_order": ["acl", "typeMethods", "owned", "setterACL", "final", "mutators", "override"]])
    }
}
