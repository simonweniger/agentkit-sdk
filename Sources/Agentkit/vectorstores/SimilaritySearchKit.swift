//
//  SimilaritySearchKit.swift
//  SimilaritySearchKit
//
//  Created by Simon Weniger on 2024/11/18.
//

import Foundation

#if os(macOS) || os(iOS) || os(visionOS)
import SimilaritySearchKit
import CryptoKit

private struct AgentkitEmbeddingBridge: EmbeddingsProtocol {
    
    var tokenizer: _T?
    
    var model: _M?

    class  _M {
        
    }
    class _T: TokenizerProtocol {
        func tokenize(text: String) -> [String] {
            []
        }
        
        func detokenize(tokens: [String]) -> String {
            ""
        }
        
        
    }
    let embeddings: Embeddings
    func encode(sentence: String) async -> [Float]? {
        let e = await embeddings.embedQuery(text: sentence)
        if e.isEmpty {
            print("⚠️\(sentence.prefix(100))")
        }
        return e
    }
    
    
}
public class SimilaritySearchKit: VectorStore {
    let vs: SimilarityIndex
    
    public init(embeddings: Embeddings, autoLoad: Bool = false) {
        self.vs = SimilarityIndex(
            model: AgentkitEmbeddingBridge(embeddings: embeddings),
            metric: DotProduct()
        )
        if #available(macOS 13.0, *) {
            if #available(iOS 16.0, *) {
                if autoLoad {
                        let _ = try? vs.loadIndex()
                    } else {
                        // Fallback on earlier versions
                    }
                }
        } else {
            // Fallback on earlier versions
        }
    }
    
    override func similaritySearch(query: String, k: Int) async -> [MatchedModel] {
        await vs.search(query, top: k).map{MatchedModel(content: $0.text, similarity: $0.score, metadata: $0.metadata)}
    }
    
    override func addText(text: String, metadata: [String: String]) async {
        await vs.addItem(id: sha256(str: text), text: text, metadata: metadata)
    }
    
    @available(iOS 16.0, *)
    @available(macOS 13.0, *)
    public func writeToFile() {
        let _ = try? vs.saveIndex()
    }
    
    override func removeText(sha256: String) async {
        vs.removeItem(id: sha256)
    }
    
    func sha256(str: String) -> String {
        let data = Data(str.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
#endif
