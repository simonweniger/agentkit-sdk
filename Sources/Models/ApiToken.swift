//
// ApiToken.swift
//
//  Created by Simon Weniger on 09.07.23.
//

import Foundation



public struct ApiToken: Codable {

    public var _description: String

    public init(_description: String) {
        self._description = _description
    }

    public enum CodingKeys: String, CodingKey { 
        case _description = "description"
    }

}
