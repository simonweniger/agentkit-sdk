//
// Agent.swift
//
//  Created by Simon Weniger on 09.07.23.
//

import Foundation



public struct Agent: Codable {

	public var isActive: Bool
	public var name: String
	public var prompt: String?
    public var llmModel: String
    public var description: String
    public var avatar: String?

	public init(name: String, isActive: Bool, prompt: String? = nil, llmModel: String, description: String, avatar: String? = nil) {
		self.isActive = isActive
		self.name = name
        self.prompt = prompt
        self.llmModel = llmModel
        self.description = description
        self.avatar = avatar
    }
}
