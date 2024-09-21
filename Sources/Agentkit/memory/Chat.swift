//
//  Chat.swift
//  memory
//
//  Created by Simon Weniger on 2024/6/22.
//

import Foundation
public class BaseChatMemory: BaseMemory {
    let chat_memory: ChatMessageHistory = ChatMessageHistory()
    
    public func load_memory_variables(inputs: [String : Any]) -> [String : [String]] {
        [:]
    }
    
    public func save_context(inputs: [String: String], outputs: [String: String]) {
        for (_, input_str) in inputs {
            self.chat_memory.add_user_message(message: input_str)
        }
        for (_, output_str) in outputs {
            self.chat_memory.add_ai_message(message: output_str)
        }
    }
    
    public func clear() {
        
    }
    
    
}

public class ConversationBufferWindowMemory: BaseChatMemory {
    let memory_key = "history"
    let k: Int
    public init(k: Int = 2) {
        self.k = k
    }
    public override func load_memory_variables(inputs: [String: Any]) -> [String: [String]] {
        // Return history buffer.
        
        let buffer = self.chat_memory.messages.suffix(k)

        let bufferString = buffer.map{ "\($0.type): \($0.content)" }
        return [self.memory_key: bufferString]
    }
}

public class ChatMessageHistory: BaseChatMessageHistory {
    public var messages: [BaseMessage] = []
    
    public override func add_message(message: BaseMessage) {
        //        """Add a self-created message to the store"""
        self.messages.append(message)
    }
    
    public override func clear(){
        self.messages = []
    }
}
