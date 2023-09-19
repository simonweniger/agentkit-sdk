//
//  File.swift
//  
//
//  Created by vonweniger on 21.07.23.
//

import Foundation



public struct Tag {

	public var name: String
	public var color: String
	public var userId: String?

	public init(name: String, color: String, userId: String?) {
		self.name = name
		self.color = color
		self.userId = color
	}

	public enum CodingKeys: String, CodingKey {
		case name
		case color
		case userId
	}

}
