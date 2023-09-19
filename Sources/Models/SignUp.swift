//
// SignUp.swift
//
//  Created by Simon Weniger on 09.07.23.
//

import Foundation



public struct SignUp {

    public var email: String
    public var password: String
    public var name: String?
    public var metadata: Any?

    public init(email: String, password: String, name: String? = nil, metadata: Any? = nil) {
        self.email = email
        self.password = password
        self.name = name
        self.metadata = metadata
    }


}
