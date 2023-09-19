//
// AgentTool.swift
//
//  Created by Simon Weniger on 09.07.23.

//

import Foundation



public struct AgentTool: Codable {

    public var agentId: String
    public var toolId: String

    public init(agentId: String, toolId: String) {
        self.agentId = agentId
        self.toolId = toolId
    }


}
