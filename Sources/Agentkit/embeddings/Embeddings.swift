//
//  File.swift
//  
//
//  Created by Simon Weniger on 2024/6/12.
//

import Foundation
public protocol Embeddings {
    // Interface for embedding models.
    
//    func embedDocuments(texts: [String]) -> [[Float]]
    
    func embedQuery(text: String) async -> [Float]
}
