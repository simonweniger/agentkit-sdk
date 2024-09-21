//
//  Base.swift
//  memory
//
//  Created by Simon Weniger on 2024/6/22.
//

import Foundation

public struct BaseMessage {
    let content: String
    let type: String
}
public protocol BaseMemory {
    func load_memory_variables(inputs: [String: Any]) -> [String: [String]]
    
    func save_context(inputs: [String: String], outputs: [String: String])
    
    func clear()
}



public class BaseChatMessageHistory {
    public func add_user_message(message: String) {
        self.add_message(message: BaseMessage(content: message, type: "human"))
    }
    
    public func add_ai_message(message: String) {
        self.add_message(message: BaseMessage(content: message, type: "ai"))
    }
    
    public func add_message(message: BaseMessage) {
        
    }
    
    public func clear() {
        
    }
}
