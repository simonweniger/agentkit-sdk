//
// SignIn.swift
//
//  Created by Simon Weniger on 09.07.23.
//

import Foundation



public struct SignIn: Codable {

    public var email: String
    public var password: String

    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }


}
