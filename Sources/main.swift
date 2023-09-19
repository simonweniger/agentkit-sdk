//
//  main.swift
//
//
//  Created by Simon Weniger (Aiden Technologies UG) on 19.09.23
//


import Foundation

enum HttpMethod: String {
	case get = "GET"
	case post = "POST"
	case delete = "DELETE"
	case patch = "PATCH"
}

enum SuperagentError: Error {
	case invalidResponse
	case requestFailed
	case failedToRetrieve
	case failedToUpdate
	case failedToCreate
}

@available(macOS 12.0, *)
public struct SuperagentSDK {
	
	public var baseUrl: String
	public var apiKey: String
	
	// init auth and api url
	public init(apiKey: String, apiUrl: String?) {
		self.baseUrl = apiUrl ?? "https://api.superagent.sh/api/v1"
		self.apiKey = apiKey
	}
	
	//createRequest
	private func createRequest(method: HttpMethod, endpoint: String, data: [String: Any]? = nil) throws -> URLRequest {
		guard let url = URL(string: "\(self.baseUrl)\(endpoint)") else {
			throw URLError(.badURL)
		}
		
		var request = URLRequest(url: url)
		request.httpMethod = method.rawValue.uppercased()
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		request.addValue("Bearer \(self.apiKey)", forHTTPHeaderField: "Authorization")
		
		if let data = data {
			if method == .get {
				var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
				components.queryItems = data.map {
					URLQueryItem(name: $0.key, value: "\($0.value)")
				}
				guard let componentUrl = components.url else { throw SuperagentError.invalidResponse }
				request.url = componentUrl
			} else {
				let jsonData = try JSONSerialization.data(withJSONObject: data)
				request.httpBody = jsonData
				
				if data.keys.contains("input") {
					request.setValue(self.apiKey, forHTTPHeaderField: "X-SUPERAGENT-API-KEY")
				}
			}
		}
		return request
	}
	
	// defined Request
	private func request(method: HttpMethod, endpoint: String, data: [String: Any]? = nil) async throws -> Any  {
		let request = try createRequest(method: method, endpoint: endpoint, data: data)
		let (data, response) = try await URLSession.shared.data(for: request)
		
		if let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode {
			if let output = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
				return output
			} else {
				throw SuperagentError.invalidResponse
			}
		}
		return response
	}
	
	//Prompts
	///Retuns a specific prompt
	public func getPrompt(id: String) async throws -> [String: Any] {
		let data = try await request(method: .get, endpoint: "/prompts/\(id)")
		guard let responseData = data as? [String: Any],
			  let promptData = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
		Swift.print("getPrompt result: \(promptData)")
		
		//let decoder = JSONDecoder()
		//let jsonDataEncoded = try JSONSerialization.data(withJSONObject: jsonData, options: [])
		//let prompt = try decoder.decode(Prompt.self, from: jsonDataEncoded)
		
		return promptData
	}
	
	///Delete prompt
	public func deletePrompt(id: String) async throws -> [String: Any] {
		let data = try await request(method: .delete, endpoint: "/prompts/\(id)")
		guard let responseData = data as? [String: Any],
			  let success = responseData["success"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
		Swift.print("deletePrompt result: \(success)")
		
		return success
	}
	
	///Lists all prompts
	public func listPrompts() async throws -> [[String: Any]] {
		let data = try await request(method: .get, endpoint: "/prompts")
		
		guard let responseData = data as? [String: Any],
			  let promptsData = responseData["data"] as? [[String: Any]] else {
			throw SuperagentError.failedToRetrieve
		}
		
		Swift.print("listPrompts result: \(promptsData)")
		
		//let decoder = JSONDecoder()
		//var prompts = [Prompt]()
		
		//for json in jsonArray {
		//	let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
		//	let prompt = try decoder.decode(Prompt.self, from: jsonData)
		//	prompts.append(prompt)
		//}
		
		return promptsData
	}
	
	///Patch a specific prompt
	public func updatePrompt(promptId: String, newPrompt: Prompt) async throws -> [String: Any] {
		let payload: [String: Any] = ["name": newPrompt.name, "input_variables": newPrompt.inputVariables, "template": newPrompt.template]
		let data = try await request(method: .patch, endpoint: "/prompts/\(promptId)", data: payload)
		
		guard let responseData = data as? [String: Any],
			  let promptData = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
		Swift.print("updatePrompt result: \(promptData)")
		
		return promptData
	}
	
	///Create a new prompt
	public func createPrompt(prompt: Prompt) async throws -> [String: Any] {
		let payload: [String: Any] = ["name": prompt.name, "input_variables": prompt.inputVariables, "template": prompt.template]
		let data = try await request(method: .post, endpoint: "/prompts", data: payload)
		
		guard let responseData = data as? [String: Any],
			  let promptData = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
		Swift.print("createPrompt result: \(promptData)")
		
		return promptData
	}
	
	//Documents
	///Returns a specific document
	public func getDocument(id: String) async throws -> [String: Any] {
		let data = try await request(method: .get, endpoint: "/documents/\(id)")
		
		guard let responseData = data as? [String: Any],
			  let documentData = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
		Swift.print("getDocument result: \(documentData)")
		
		return documentData
	}
	
	///Delete document
	public func deleteDocument(id: String) async throws -> [String: Any] {
		let data = try await request(method: .delete, endpoint: "/documents/\(id)")
		
		guard let responseData = data as? [String: Any],
			  let documentData = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
		Swift.print("deleteDocument result: \(documentData)")
		
		return documentData
	}
	
	///Lists all documents
	public func listDocuments() async throws -> [String: Any] {
		let data = try await request(method: .get, endpoint: "/documents")
		
		guard let responseData = data as? [String: Any],
			  let documentData = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
		Swift.print("listDocuments result: \(documentData)")
		
		return documentData
	}
	
	///Create a new document
	public func createDocument(document: Document) async throws -> [String: Any] {
		let payload: [String: Any] = ["name": document.name,
									  "description" : document.description as Any,
									  "content" : document.content,
									  "splitter": ["type": document.splitter?.type as Any, "chunk_size": document.splitter?.chunkSize as Any, "chunk_overlap": document.splitter?.chunkOverlap as Any],
									  "url": document.url as Any,
									  "type": document.type,
									  "authorization": document.authorization as Any]
		let data = try await request(method: .post, endpoint: "/documents", data: payload)
		
		guard let responseData = data as? [String: Any],
			  let documentData = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
#if DEBUG
		Swift.print("createDocument result: \(documentData)")
#endif
		
		return documentData
	}
	
	///Patch a document
	public func updateDocument(id: String, document: Document) async throws -> [String: Any] {
		let payload: [String: Any] = ["name": document.name,
									  "description" : document.description as Any,
									  "content" : document.content,
									  "splitter": ["type": document.splitter?.type as Any, "chunk_size": document.splitter?.chunkSize as Any, "chunk_overlap": document.splitter?.chunkOverlap as Any],
									  "url": document.url as Any,
									  "type": document.type,
									  "authorization": document.authorization as Any]
		let data = try await request(method: .patch, endpoint: "/documents/\(id)", data: payload)
		
		guard let responseData = data as? [String: Any],
			  let documentData = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
			
		}
		
#if DEBUG
		Swift.print("updateDocument result: \(documentData)")
#endif
		
		return documentData
	}
	
	//Agents
	///Returns a specific agent
	public func getAgent(id: String) async throws -> [String: Any] {
		let data = try await request(method: .get, endpoint: "/agents/\(id)")
		
		guard let responseData = data as? [String: Any],
			  let agentData = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
#if DEBUG
		Swift.print("getAgent result: \(agentData)")
#endif
		
		//let decoder = JSONDecoder()
		//let jsonDataEncoded = try JSONSerialization.data(withJSONObject: jsonData, options: [])
		//let agent = try decoder.decode(Agent.self, from: jsonDataEncoded)
		
		return agentData
	}
	
	///Delete agent
	public func deleteAgent(id: String) async throws -> [String: Any] {
		let data = try await request(method: .delete, endpoint: "/agents/\(id)")
		
		guard let responseData = data as? [String: Any],
			  let agentData = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
#if DEBUG
		Swift.print("deleteAgent result: \(agentData)")
#endif
		
		return agentData
	}
	
	///Lists all agents
	public func listAgents() async throws -> [String: Any] {
		let data = try await request(method: .get, endpoint: "/agents")
		
		guard let responseData = data as? [String: Any],
			  let agentData = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
#if DEBUG
		Swift.print("listAgents result: \(agentData)")
#endif
		
		return agentData
	}
	
	///Create a new agent
	public func createAgent(agent: Agent) async throws -> [String: Any] {
		let payload: [String: Any] = ["name": agent.name,
									  "llm": ["provider": agent.llm?.provider, "model": agent.llm?.model, "api_key": agent.llm?.apiKey],
									  "type": agent.type,
									  "hasMemory": agent.hasMemory as Any,
									  "promptId": agent.promptId ?? ""]
		let data = try await request(method: .post, endpoint: "/agents", data: payload)
		
		guard let responseData = data as? [String: Any],
			  let agentData = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
#if DEBUG
		Swift.print("createAgent result: \(agentData)")
#endif
		// WE MAY ADD RESPONSE MODELS LATER AND ADD JSON DECODING
		
		//print("response data:\(jsonData)")
		
		//let decoder = JSONDecoder()
		//let jsonDataEncoded = try JSONSerialization.data(withJSONObject: jsonData, options: [])
		
		//print("JsonDataEncoded \(jsonDataEncoded)")
		//let agent = try decoder.decode(Agent.self, from: jsonDataEncoded)
		
		//print("returned Agent: \(agent)")
		
		return agentData
	}
	
	
	///Create a new prediction
	public func createPrediction(agentId: String, prediction: PredictAgent) async throws -> String {
		//print("create Prediction called")
		let payload: [String: Any] = ["input": prediction.input,
									  "has_Streaming": prediction.hasStreaming as Any,
									  "session": prediction.session as Any]

#if DEBUG
		Swift.print("Prediction payload: \(payload)")
#endif
		let data = try await request(method: .post, endpoint: "/agents/\(agentId)/predict", data: payload)
#if DEBUG
		Swift.print("Prediction data:\(data)")
#endif
		guard let responseData = data as? [String: Any],
			  let predictionData = responseData["data"] as? String else {
			throw SuperagentError.failedToRetrieve
		}
		Swift.print("createPrediction result: \(predictionData)")
		return predictionData
	}
	
	//Agent Library
	///Get all Agents from the Library
	public func listLibraryAgents() async throws -> [[String: Any]] {
		let data = try await request(method: .get, endpoint: "/agents/library")
		
		guard let responseData = data as? [String: Any],
			  let agentLibrary = responseData["data"] as? [[String: Any]] else {
			throw SuperagentError.failedToRetrieve
		}
#if DEBUG
		Swift.print("getAgentDocuments result: \(agentLibrary)")
#endif
		return agentLibrary
	}
	
	
	//Agent Documents
	///Get all Documents from an Agent
	public func listAgentDocuments() async throws -> [[String: Any]] {
		let data = try await request(method: .get, endpoint: "/agent-documents")
		
		guard let responseData = data as? [String: Any],
			  let agentDocuments = responseData["data"] as? [[String: Any]] else {
			throw SuperagentError.failedToRetrieve
		}
#if DEBUG
		Swift.print("getAgentDocuments result: \(agentDocuments)")
#endif
		return agentDocuments
	}
	
	///Get all Documents from an Agent
	public func getAgentDocument(agentDocumentId: String) async throws -> [String: Any] {
		let data = try await request(method: .get, endpoint: "/agent-documents\(agentDocumentId)")
		
		guard let responseData = data as? [String: Any],
			  let agentDocument = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
#if DEBUG
		Swift.print("getAgentDocuments result: \(agentDocument)")
#endif
		return agentDocument
	}
	
	///Add a Document to an Agent
	public func addDocumentToAgent(documentId: String, agentId: String) async throws -> [String: Any] {
		let payload: [String: Any] = ["documentId": documentId, "agentId": agentId]
		let data = try await request(method: .post, endpoint: "/agents", data: payload)
		
		guard let responseData = data as? [String: Any],
			  let agentDocument = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToCreate
		}
#if DEBUG
		Swift.print("createAgentDocument result: \(agentDocument)")
#endif
		return agentDocument
	}
	
	///Delete a Document from an Agent
	public func deleteAgentDocument(agentDocumentId: String) async throws -> [String: Any] {
		let data = try await request(method: .delete, endpoint: "/agent-documents/\(agentDocumentId)")
		
		guard let responseData = data as? [String: Any],
			  let agentDocument = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
#if DEBUG
		Swift.print("deleteAgentDocument result: \(agentDocument)")
#endif
		return agentDocument
	}
	
	//Agent Tools
	///Get all Tools from an Agent
	public func listAgentTools(agentToolId: String) async throws -> [String: Any] {
		let data = try await request(method: .get, endpoint: "/agent-tools/\(agentToolId)")
		
		guard let responseData = data as? [String: Any],
			  let agentTool = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
#if DEBUG
		Swift.print("getAgentTools result: \(agentTool)")
#endif
		return agentTool
	}
	
	///Get all Tools from an Agent
	public func getAgentTool() async throws -> [[String: Any]] {
		let data = try await request(method: .get, endpoint: "/agent-tools")
		
		guard let responseData = data as? [String: Any],
			  let agentTools = responseData["data"] as? [[String: Any]] else {
			throw SuperagentError.failedToRetrieve
		}
#if DEBUG
		Swift.print("getAgentTools result: \(agentTools)")
#endif
		return agentTools
	}
	
	///Add a Tool to an Agent
	public func addToolToAgent(agentId: String, toolId: String) async throws -> [String: Any] {
		let payload: [String: Any] = ["agentId": agentId, "toolId": toolId]
		let data = try await request(method: .post, endpoint: "/agent-tools", data: payload)
		
		guard let responseData = data as? [String: Any],
			  let agentToolData = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToUpdate
		}
#if DEBUG
		Swift.print("addToolToAgent result: \(agentToolData)")
#endif
		return agentToolData
	}
	
	///Delete a Tool from an Agent
	public func deleteAgentTool(agentToolId: String) async throws -> [String: Any] {
		let data = try await request(method: .delete, endpoint: "/agent-documents/\(agentToolId)")
		
		guard let responseData = data as? [String: Any],
			  let success = responseData["data"] as? [String: Any] else {
			throw SuperagentError.requestFailed
		}
#if DEBUG
		Swift.print("deleteAgentTool result: \(success)")
#endif
		return success
	}
	
	//Tools
	///Returns a specific tool
	public func getTool(id: String) async throws -> [String: Any] {
		let data = try await request(method: .get, endpoint: "/tools/\(id)")
		
		guard let responseData = data as? [String: Any],
			  let toolData = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
#if DEBUG
		Swift.print("getTool result: \(toolData)")
#endif
		return toolData
	}
	
	///Delete tool
	public func deleteTool(id: String) async throws -> [String: Any] {
		let data = try await request(method: .delete, endpoint: "/tools/\(id)")
		
		guard let responseData = data as? [String: Any],
			  let toolData = responseData["data"] as? [String: Any] else {
			throw SuperagentError.requestFailed
		}
#if DEBUG
		Swift.print("deleteTool result: \(toolData)")
#endif
		return toolData
	}
	
	///Lists all tools
	public func listTools() async throws -> [[String: Any]] {
		let data = try await request(method: .get, endpoint: "/tools")
		
		guard let responseData = data as? [String: Any],
			  let toolData = responseData["data"] as? [[String: Any]] else {
			throw SuperagentError.failedToRetrieve
		}
#if DEBUG
		Swift.print("listTools result: \(toolData)")
#endif
		return toolData
	}
	
	///Create a new tool
	public func createTool(tool: Tool) async throws -> [String: Any] {
		var payload: [String: Any] = ["name": tool.name, "type": tool.type]
		if let metadata = tool.metadata {
			payload["metadata"] = metadata
		}
		let data = try await request(method: .post, endpoint: "/tools", data: payload)
		
		guard let responseData = data as? [String: Any],
			  let toolData = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToCreate
		}
#if DEBUG
		Swift.print("createTool result: \(toolData)")
#endif
		return toolData
	}
	
	//Tags
	///Returns a specific tag
	public func getTag(id: String) async throws -> [String: Any] {
		let data = try await request(method: .get, endpoint: "/tags/\(id)")
		
		guard let responseData = data as? [String: Any],
			  let tagData = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
#if DEBUG
		Swift.print("getTag result: \(tagData)")
#endif
		return tagData
	}

	///Delete tool
	public func deleteTag(id: String) async throws -> [String: Any] {
		let data = try await request(method: .delete, endpoint: "/tags/\(id)")
		
		guard let responseData = data as? [String: Any],
			  let tagData = responseData["data"] as? [String: Any] else {
			throw SuperagentError.requestFailed
		}
#if DEBUG
		Swift.print("deleteTag result: \(tagData)")
#endif
		return tagData
	}

	///Lists all tools
	public func listTags() async throws -> [[String: Any]] {
		let data = try await request(method: .get, endpoint: "/tags")
		
		guard let responseData = data as? [String: Any],
			  let tagsData = responseData["data"] as? [[String: Any]] else {
			throw SuperagentError.failedToRetrieve
		}
#if DEBUG
		Swift.print("listTagss result: \(tagsData)")
#endif
		return tagsData
	}
	///Create a new tool
	public func createTag(tag: Tag) async throws -> [String: Any] {
		var payload: [String: Any] = ["name": tag.name, "type": tag.color, "userId": tag.userId ?? ""]
		let data = try await request(method: .post, endpoint: "/tags", data: payload)
		
		guard let responseData = data as? [String: Any],
			  let tagData = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToCreate
		}
#if DEBUG
		Swift.print("createTag result: \(tagData)")
#endif
		return tagData
	}
	
	///Patch a tag
	public func updateTag(id: String, newTag: Tag) async throws -> [String: Any] {
		var payload: [String: Any] = ["name": newTag.name, "type": newTag.color]
		let data = try await request(method: .post, endpoint: "/tags/\(id)", data: payload)
		
		guard let responseData = data as? [String: Any],
			  let tagData = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToUpdate
		}
#if DEBUG
		Swift.print("updateTag result: \(tagData)")
#endif
		return tagData
	}
}

