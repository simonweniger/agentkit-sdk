//
// Prompt.swift
//
//  Created by Simon Weniger on 09.07.23.
//

import Foundation


public struct Prompt: Decodable {

    public var name: String
    public var inputVariables: [String]
    public var template: String
	
	public enum CodingKeys: String, CodingKey {
		case name = "name"
		case inputVariables = "input_variables"
		case template = "template"
	}

    public init(name: String, inputVariables: [String], template: String) {
        self.name = name
        self.inputVariables = inputVariables
        self.template = template
    }

}
