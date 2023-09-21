//
// Tool.swift
//
//  Created by Simon Weniger (Aiden Technologies) on 09.07.23.
//

import Foundation

public struct Tool {

    public var name: String
	public var description: String
    public var type: String
	public var metadata: [String : Any]?
    public var returnDirect: Bool?

	public init(name: String, description: String, type: String, metadata: [String: Any]? = nil, returnDirect: Bool? = nil) {
        self.name = name
		self.description = description
        self.type = type
        self.metadata = metadata
		self.returnDirect = returnDirect
    }
	
}
