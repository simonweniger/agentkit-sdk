//
//  MultiVectorRetriever.swift
//  retriever
//
//  Created by Simon Weniger on 2024/11/17.
//

import Foundation

public class MultiVectorRetriever: BaseRetriever {
    let vectorstore: VectorStore
    let docstore: BaseStore
    let id_key = "doc_id"
    
    public init(vectorstore: VectorStore, docstore: BaseStore) {
        self.vectorstore = vectorstore
        self.docstore = docstore
    }
    
    public override func _get_relevant_documents(query: String) async throws  -> [Document] {
        let sub_docs = await self.vectorstore.similaritySearch(query: query, k: 2)
        var ids: [String] = []
        for d in sub_docs {
            ids.append(d.metadata[self.id_key]!)
        }
        let docs = await self.docstore.mget(keys: ids)
        return docs.map{Document(page_content: $0, metadata: [:])}
    }
}
