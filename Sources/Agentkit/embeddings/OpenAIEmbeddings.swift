//
//  File.swift
//  
//
//  Created by Simon Weniger on 2024/6/12.
//

import Foundation
import NIOPosix
import AsyncHTTPClient
import OpenAIKit

public struct OpenAIEmbeddings: Embeddings {
    let session: URLSession
    public init(session: URLSession = URLSession(configuration: .default)) {
        self.session = session
    }
    
//    public func embedDocuments(texts: [String]) -> [[Float]] {
//        []
//    }
    
    public func embedQuery(text: String) async -> [Float] {
       
        let env = LC.loadEnv()
        
        if let apiKey = env["OPENAI_API_KEY"] {
            let baseUrl = env["OPENAI_API_BASE"] ?? "api.openai.com"
            
            let configuration = Configuration(apiKey: apiKey, api: API(scheme: .https, host: baseUrl))

            let openAIClient = OpenAIKit.Client(session: session, configuration: configuration)

            do {
                let embedding = try await openAIClient.embeddings.create(input: text)
                
                //            print(embedding.data[0].embedding)
                return embedding.data[0].embedding
            } catch {
                return []
            }
        } else {
            print("Please set openai api key.")
            return []
        }

        
    }
    
    
}
