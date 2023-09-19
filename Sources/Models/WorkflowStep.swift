//
//  Workflow.swift
//  
//
//  Created by Simon Weniger (Aiden Technologies) on 19.09.23.
//

import Foundation

public struct WorkflowStep {

	public var order: Int
	public var agentId: String
	public var input: String
	public var output: String

	public init(order: Int, agentId: String, input: String, output: String) {
		self.order = order
		self.agentId = agentId
		self.input = input
		self.output = output
	}
	
}
