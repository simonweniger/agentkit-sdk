//
// PredictAgent.swift
//
//  Created by Simon Weniger on 09.07.23.
//

import Foundation


public struct PredictAgent {
	
	public var input: [String:String]
    public var hasStreaming: Bool?
	public var session: String?

	public init(input: [String:String], hasStreaming: Bool? = nil, session: String) {
        self.input = input
        self.hasStreaming = hasStreaming
		self.session = session
    }

    public enum CodingKeys: String, CodingKey { 
        case input
        case hasStreaming = "has_streaming"
		case session
    }

}
