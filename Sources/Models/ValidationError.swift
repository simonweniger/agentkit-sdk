//
// ValidationError.swift
//
//  Created by Simon Weniger on 09.07.23.
//

import Foundation



public struct ValidationError: Codable {

    public var loc: [AnyOfValidationErrorLocItems]
    public var msg: String
    public var type: String

    public init(loc: [AnyOfValidationErrorLocItems], msg: String, type: String) {
        self.loc = loc
        self.msg = msg
        self.type = type
    }


}
