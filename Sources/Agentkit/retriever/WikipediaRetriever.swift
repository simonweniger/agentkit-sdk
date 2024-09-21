//
//  File.swift
//  
//
//  Created by Simon Weniger on 2024/11/2.
//

import Foundation
public class WikipediaRetriever: BaseRetriever {
    let client = WikipediaAPIWrapper()
    
    public override func _get_relevant_documents(query: String) async throws -> [Document] {
        try await client.load(query: query)
    }
    
    public override init() {
        
    }
}
