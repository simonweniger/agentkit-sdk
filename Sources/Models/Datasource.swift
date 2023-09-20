//
//  Datasource.swift
//  
//
//  Created by Simon Weniger (Aiden Technologies) on 19.09.23.
//

import Foundation

public struct Datasource {

	public var name: String
	public var description: String
	public var type: String
	public var url: String
	public var metadata: [String: Any]?

	public init(name: String, description: String, type: String, url: String, metadata: [String: Any]? = nil) {
		self.name = name
		self.description = description
		self.type = type
		self.url = url
	}
}
