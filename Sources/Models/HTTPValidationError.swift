//
// HTTPValidationError.swift
//
//  Created by Simon Weniger on 09.07.23.
//

import Foundation



public struct HTTPValidationError: Codable {

    public var detail: [ValidationError]?

    public init(detail: [ValidationError]? = nil) {
        self.detail = detail
    }


}
