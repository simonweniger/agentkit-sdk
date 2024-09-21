//
//  File.swift
//  
//
//  Created by Simon Weniger on 2024/11/4.
//

import Foundation

public class BaseCombineDocumentsChain: DefaultChain {
    public func predict(args: [String: String] ) async -> String? {
        let output = await self.combine_docs(docs: args["docs"]!, question: args["question"]!)
        return output
    }
    
    public func combine_docs(docs: String, question: String) async -> String? {
        ""
    }
}
