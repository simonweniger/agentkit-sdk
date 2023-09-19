//
// PredictAgent.swift
//
//  Created by Simon Weniger (Aiden Technologies) on 09.07.23.
//

import Foundation

public struct Request {
	
	public var input: String
    public var sessionId: String?
	public var enableStreaming: Bool

	public init(input: String, sessionId: String? = "", enableStreaming: Bool) {
        self.input = input
        self.sessionId = sessionId
		self.enableStreaming = enableStreaming
    }

}
