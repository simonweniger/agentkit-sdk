//
//  String+Error.swift
//  
//
//  Created by Simon Weniger on 09.07.23.
//

import Foundation

extension String: LocalizedError {
	public var errorDescription: String? { return self }
}
