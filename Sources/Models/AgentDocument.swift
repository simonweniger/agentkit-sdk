//
// AgentDocument.swift
//
//  Created by Simon Weniger on 09.07.23.
//

import Foundation



public struct AgentDocument: Codable {

    public var agentId: String
    public var documentId: String

    public init(agentId: String, documentId: String) {
        self.agentId = agentId
        self.documentId = documentId
    }


}
