//
// Tool.swift
//
//  Created by Simon Weniger on 09.07.23.
//

import Foundation



public struct Tool {

    public var name: String
    public var type: String
    public var _description: String
    public var authorization: Any?
    public var metadata: Any?

    public init(name: String, type: String, _description: String, authorization: Any? = nil, metadata: Any? = nil) {
        self.name = name
        self.type = type
        self._description = _description
        self.authorization = authorization
        self.metadata = metadata
    }

    public enum CodingKeys: String, CodingKey { 
        case name
        case type
        case _description = "description"
        case authorization
        case metadata
    }

}
