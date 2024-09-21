//
//  File.swift
//  
//
//  Created by Simon Weniger on 2024/8/4.
//

import Foundation
public struct ListOutputParser: BaseOutputParser {
    public func parse(text: String) -> Parsed {
        Parsed.list(text.components(separatedBy: ","))
    }
    
    
}
