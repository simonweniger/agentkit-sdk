////
////  File.swift
////  
////
////  Created by Simon Weniger on 1/22/24.
////
//import llmfarm_core
//import Foundation
//
//public class Local: LLM {
//    let modelPath: String
//    let useMetal: Bool
//    let inference: ModelInference
//    
//    public init(inference: ModelInference, modelPath: String, useMetal: Bool = false, callbacks: [BaseCallbackHandler] = [], cache: BaseCache? = nil) {
//        self.inference = inference
//        self.modelPath = modelPath
//        self.useMetal = useMetal
//        super.init(callbacks: callbacks, cache: cache)
//    }
//    public override func _send(text: String, stops: [String] = []) async throws -> LLMResult {
//        let ai = AI(_modelPath: self.modelPath, _chatName: "chat")
//        var params:ModelAndContextParams = .default
//        params.use_metal = useMetal
//        params.promptFormat = .Custom
//        params.custom_prompt_format = "{{prompt}}"
//        try? ai.loadModel(inference, contextParams: params)
//        let output = try? ai.model.predict(text, mainCallback)
////        print("🚗\(output)")
//        total_output = 0
//        return LLMResult(llm_output: output)
//    }
//    
//    let maxOutputLength = 256
//    var total_output = 0
//
//    func mainCallback(_ str: String, _ time: Double) -> Bool {
//        print("\(str)",terminator: "")
//        total_output += str.count
//        if(total_output>maxOutputLength){
//            return true
//        }
//        return false
//    }
//}
//
