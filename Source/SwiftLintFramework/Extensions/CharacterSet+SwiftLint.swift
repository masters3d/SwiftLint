//
//  CharacterSet+SwiftLint.swift
//  SwiftLint
//
//  Created by Cyril Lashkevich on 3/11/18.
//  Copyright © 2018 Realm. All rights reserved.
//

import Foundation

// This is workaround for https://bugs.swift.org/browse/SR-5971
// Can be removed when 
// https://github.com/apple/swift-corelibs-foundation/pull/1471 is merged
internal extension CharacterSet {
    init(safeCharactersIn string: String) {
#if os(Linux)
        self.init()
        insert(charactersIn: string)
#else
        self.init(charactersIn: string)
#endif
    }
}
