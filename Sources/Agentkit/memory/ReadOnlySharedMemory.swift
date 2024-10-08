//
//  ReadOnlySharedMemory.swift
//  memory
//
//  Created by Simon Weniger on 2024/7/31.
//

import Foundation
public struct ReadOnlySharedMemory: BaseMemory {
    
    let base: BaseMemory
    public init(base: BaseMemory) {
        self.base = base
    }
    
    public func load_memory_variables(inputs: [String : Any]) -> [String : [String]] {
        base.load_memory_variables(inputs: inputs)
    }
    
    public func save_context(inputs: [String : String], outputs: [String : String]) {
        
    }
    
    public func clear() {
        
    }
    
    
}
