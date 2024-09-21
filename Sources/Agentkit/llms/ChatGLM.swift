//
//  File.swift
//  
//
//  Created by Simon Weniger on 2024/8/30.
//

import Foundation

public class ChatGLM: LLM {
    public override func _send(text: String, stops: [String]) async throws -> LLMResult {
        return LLMResult(llm_output: try await api.call(text: text))
    }
    
    let api: ChatGLMAPIWrapper
    
    public init(model: ChatGLMModel = ChatGLMModel.chatglm_std, temperature: Double = 0.0) {
        api = ChatGLMAPIWrapper(model: model, temperature: temperature)
    }
    
}
