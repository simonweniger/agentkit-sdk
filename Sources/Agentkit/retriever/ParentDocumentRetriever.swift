//
//  File.swift
//  
//
//  Created by Simon Weniger on 2024/11/17.
//
import CryptoKit
import Foundation

public class ParentDocumentRetriever: MultiVectorRetriever {
	public init(child_splitter: TextSplitter, parent_splitter: TextSplitter? = nil, vectorstore: VectorStore, docstore: BaseStore) {
		self.child_splitter = child_splitter
		self.parent_splitter = parent_splitter
		super.init(vectorstore: vectorstore, docstore: docstore)
	}
	let child_splitter: TextSplitter
	// The text splitter to use to create child documents."""
	
	
	let parent_splitter: TextSplitter?
	//The text splitter to use to create parent documents.
	//If none, then the parent documents will be the raw documents passed in.
	public func add_documents(documents: [Document]) async -> [String] {
		if documents.isEmpty {
			return []
		}
		var parent_documents: [Document]
		if let p = self.parent_splitter {
			parent_documents = p.split_documents(documents: documents)
		} else {
			parent_documents = documents
		}
		let doc_ids = parent_documents.map{_ in UUID().uuidString}
		
		var docs: [Document] = []
		var full_docs:[(String, String)] = []
		for i in 0..<parent_documents.count {
			let doc = parent_documents[i]
			let _id = doc_ids[i]
			let sub_docs = self.child_splitter.split_documents(documents: [doc])
			let sub_docs__with_id = sub_docs.map{Document(page_content: $0.page_content, metadata: [self.id_key: _id])}
			docs.append(contentsOf: sub_docs__with_id)
			full_docs.append((_id, doc.page_content))
		}
		print("🚀 Begin add sub document \(docs.count), main document \(full_docs.count)")
		await self.vectorstore.add_documents(documents: docs)
		await self.docstore.mset(kvpairs: full_docs)
		print("🚀 End add sub document \(docs.count), main document \(full_docs.count)")
		return doc_ids
	}
	
	public func remove_documents(documents: [Document]) async {
		if documents.isEmpty {
			return
		}
		await self.docstore.mdelete(keys: documents.map {$0.metadata["id"]!})
		var all_sub_docs = [Document]()
		for main_doc in documents {
			let sub_docs = self.child_splitter.split_documents(documents: [main_doc])
			all_sub_docs.append(contentsOf: sub_docs)
		}
		print("🚀 Begin remove sub document \(all_sub_docs.count), main document \(documents.count)")
		await self.vectorstore.remove_documents(sha256s: all_sub_docs.map {sha256(str: $0.page_content)})
		print("🚀 End remove sub document \(all_sub_docs.count), main document \(documents.count)")
	}
	
	fileprivate func sha256(str: String) -> String {
		let data = Data(str.utf8)
		let hash = SHA256.hash(data: data)
		return hash.compactMap { String(format: "%02x", $0) }.joined()
	}
}
