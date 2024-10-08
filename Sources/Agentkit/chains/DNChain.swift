//
//  File.swift
//  
//
//  Created by Simon Weniger on 2024/8/9.
//

import Foundation
public class DNChain: DefaultChain {
    public override init(memory: BaseMemory? = nil, outputKey: String = "output", inputKey: String = "input", callbacks: [BaseCallbackHandler] = []) {
        super.init(memory: memory, outputKey: outputKey, inputKey: inputKey, callbacks: callbacks)
    }
    public override func _call(args: String) async -> (LLMResult?, Parsed) {
//        print("Do nothing.")
        return (LLMResult(), Parsed.nothing)
    }
    
}
