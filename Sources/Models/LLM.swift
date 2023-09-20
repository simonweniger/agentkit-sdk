//
//  LLM.swift
//  
//
//  Created by Simon Weniger (Aiden Technologies) on 19.09.23.
//
import Foundation

public struct LLM {
	public var provider: String
	public var apiKey: String
	public var options: [String: Any]?

	public init(provider: String, apiKey: String, options: [String: Any]? = nil) {
		self.provider = provider
		self.apiKey = apiKey
		self.options = options
	}
}
