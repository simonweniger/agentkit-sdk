//
//  File.swift
//  
//
//  Created by Simon Weniger on 2024/6/24.
//

import Foundation
public struct Document: Equatable {
    public init(page_content: String, metadata: [String : String]) {
        self.page_content = page_content
        self.metadata = metadata
    }
    public let page_content: String
    public var metadata: [String: String]
    public static func == (lhs: Document, rhs: Document) -> Bool {
        return lhs.page_content == rhs.page_content
    }
}
public class BaseLoader {
    
    static let LOADER_TYPE_KEY = "loader_type"
    static let LOADER_REQ_ID = "loader_req_id"
    static let LOADER_COST_KEY = "cost"
    
    let callbacks: [BaseCallbackHandler]
    init(callbacks: [BaseCallbackHandler] = []) {
        var cbs: [BaseCallbackHandler] = callbacks
        if LC.addTraceCallbak() && !cbs.contains(where: { item in item is TraceCallbackHandler}) {
            cbs.append(TraceCallbackHandler())
        }
//        assert(cbs.count == 1)
        self.callbacks = cbs
    }
    func callStart(type: String, reqId: String) {
        do {
            for callback in callbacks {
                try callback.on_loader_start(type: type, metadata: [BaseLoader.LOADER_REQ_ID: reqId, BaseLoader.LOADER_TYPE_KEY: type])
            }
        } catch {
            
        }
    }
    
    func callEnd(type: String, reqId: String, cost: Double) {
        do {
            for callback in callbacks {
                try callback.on_loader_end(type: type, metadata: [BaseLoader.LOADER_REQ_ID: reqId, BaseLoader.LOADER_COST_KEY: "\(cost)", BaseLoader.LOADER_TYPE_KEY: type])
            }
        } catch {
            
        }
    }
    
    func callError(type: String, reqId: String, cause: String) {
        do {
            for callback in callbacks {
                try callback.on_loader_error(type: type, cause: cause, metadata: [BaseLoader.LOADER_REQ_ID: reqId, BaseLoader.LOADER_TYPE_KEY: type])
            }
        } catch {
            
        }
    }
    
    public func load() async -> [Document] {
        let type = type()
        let reqId = UUID().uuidString
        var cost = 0.0
        let now = Date.now.timeIntervalSince1970
        do {
            callStart(type: type, reqId: reqId)
            let docs = try await _load()
            cost = Date.now.timeIntervalSince1970 - now
            callEnd(type: type, reqId: reqId, cost: cost)
            return docs
        } catch AgentkitError.LoaderError(let cause) {
            print("Catch agentkit loader error \(cause)")
            callError(type: type, reqId: reqId, cause: cause)
            return []
        } catch {
            print("Catch other error \(error)")
            return []
        }
    }
    
    func _load() async throws -> [Document] {
        []
    }
    
    func type() -> String {
        "Base"
    }
}
