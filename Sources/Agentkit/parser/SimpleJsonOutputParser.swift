//
//  SimpleJsonOutputParser.swift
//
//
//  Created by Simon Weniger on 2024/8/4.
//

import Foundation
import SwiftyJSON

public struct SimpleJsonOutputParser: BaseOutputParser {
    public func parse(text: String) -> Parsed {
        do {
            return Parsed.json(try JSON(data: text.data(using: .utf8)!))
        } catch {
            print("Parse json error: \(text)")
            return Parsed.error
        }
    }
    
    
}
