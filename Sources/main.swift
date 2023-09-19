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
	
	//MARK: - START VERSION 1.0
	
	
	
	//MARK: - Agent
	
	//List
	///List all agents
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
	
	//Create
	///Create a new agent
	public func createAgent(agent: Agent) async throws -> [String: Any] {
		let payload: [String: Any] = ["isActive": agent.isActive,
									  "name": agent.name,
									  "prompt": agent.prompt ?? "",
									  "llmModel": agent.llmModel,
									  "description": agent.description,
									  "avatar": agent.avatar ?? ""]
		let data = try await request(method: .post, endpoint: "/agents", data: payload)
		
		guard let responseData = data as? [String: Any],
			  let agentData = responseData["data"] as? [String: Any] else {
			throw SuperagentError.requestFailed
		}
#if DEBUG
		Swift.print("createAgent result: \(agentData)")
#endif
		
		return agentData
	}
	
	//Get
	///Get a single agent
	public func getAgent(id: String) async throws -> [String: Any] {
		let data = try await request(method: .get, endpoint: "/agents/\(id)")
		
		guard let responseData = data as? [String: Any],
			  let agentData = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
#if DEBUG
		Swift.print("getAgent result: \(agentData)")
#endif
		
		return agentData
	}
	
	//Update
	///Patch an agent
	public func updateAgent(agentId: String, newAgent: Agent) async throws -> [String: Any] {
		let payload: [String: Any] = ["isActive": newAgent.isActive,
									  "name": newAgent.name,
									  "prompt": newAgent.prompt ?? "",
									  "llmModel": newAgent.llmModel,
									  "description": newAgent.description,
									  "avatar": newAgent.avatar ?? ""]
		let data = try await request(method: .post, endpoint: "/agents/\(agentId)", data: payload)
		
		guard let responseData = data as? [String: Any],
			  let agentData = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToUpdate
		}
#if DEBUG
		Swift.print("createAgent result: \(agentData)")
#endif
		
		return agentData
	}
	
	///Delete agent
	public func deleteAgent(id: String) async throws -> [String: Any] {
		let data = try await request(method: .delete, endpoint: "/agents/\(id)")
		
		guard let responseData = data as? [String: Any],
			  let agentData = responseData["data"] as? [String: Any] else {
			throw SuperagentError.requestFailed
		}
		
#if DEBUG
		Swift.print("deleteAgent result: \(agentData)")
#endif
		
		return agentData
	}
	
	//Invoke
	///Invoke an agent
	public func invokeAgent(agentId: String, agentRequest: Request) async throws -> String {
		let payload: [String: Any] = ["input": agentRequest.input,
									  "sessionId": agentRequest.sessionId as Any,
									  "enableStreaming": agentRequest.enableStreaming as Any]
		
		let data = try await request(method: .post, endpoint: "/agents/\(agentId)/invoke", data: payload)
		
#if DEBUG
		Swift.print("Prediction data:\(data)")
#endif
		
		guard let responseData = data as? [String: Any],
			  let predictionData = responseData["data"] as? String else {
			throw SuperagentError.failedToRetrieve
		}
		
#if DEBUG
		Swift.print("createPrediction result: \(predictionData)")
#endif
		
		return predictionData
	}
	
	//Add LLM
	///Add LLM to agent
	public func addLlmToAgent(agentId: String, llmId: String) async throws -> String {
		let data = try await request(method: .post, endpoint: "/agents/\(agentId)/llms", data: ["llmId": llmId])
		
		guard let responseData = data as? [String: Any],
			  let agentData = responseData["data"] as? String else {
			throw SuperagentError.failedToRetrieve
		}
		
#if DEBUG
		Swift.print("add LLM To Agent result: \(agentData)")
#endif
		
		return agentData
	}
	
	//Remove LLM
	///Remove LLM from agent
	public func removeLlmfromAgent(agentId: String, llmId: String) async throws -> String {
		let data = try await request(method: .delete, endpoint: "/agents/\(agentId)/llms/\(llmId)")
		
		guard let responseData = data as? [String: Any],
			  let agentData = responseData["data"] as? String else {
			throw SuperagentError.failedToRetrieve
		}
		
#if DEBUG
		Swift.print("remove LLM from Agent result: \(agentData)")
#endif
		
		return agentData
	}
	
	//List Tools
	///List agent tools
	public func listAgentTools(agentId: String) async throws -> [String: Any] {
		let data = try await request(method: .get, endpoint: "/agents/\(agentId)/tools")
		
		guard let responseData = data as? [String: Any],
			  let agentTools = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
#if DEBUG
		Swift.print("list agent tools result: \(agentTools)")
#endif
		return agentTools
	}
	
	
	//Add Tool
	///Add tool to agent
	public func addToolToAgent(agentId: String, toolId: String) async throws -> [String: Any] {
		let data = try await request(method: .post, endpoint: "/agents/\(agentId)/tools", data: ["toolId": toolId])
		
		guard let responseData = data as? [String: Any],
			  let agentTools = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
#if DEBUG
		Swift.print("add tool to agent result: \(agentTools)")
#endif
		return agentTools
	}
	
	//Remove Tool
	///Remove tool from agent
	public func removeToolFromAgent(agentId: String, toolId: String) async throws -> [String: Any] {
		let data = try await request(method: .delete, endpoint: "/agents/\(agentId)/tools/\(toolId)")
		
		guard let responseData = data as? [String: Any],
			  let success = responseData["data"] as? [String: Any] else {
			throw SuperagentError.requestFailed
		}
#if DEBUG
		Swift.print("remove tool from agent result: \(success)")
#endif
		return success
	}
	
	//List Datasources
	///List agent datasources
	public func listAgentDatasources(agentId: String) async throws -> [String: Any] {
		let data = try await request(method: .get, endpoint: "/agents/\(agentId)/datasources")
		
		guard let responseData = data as? [String: Any],
			  let agentDatasources = responseData["data"] as? [String: Any] else {
			throw SuperagentError.requestFailed
		}
#if DEBUG
		Swift.print("deleteAgentTool result: \(agentDatasources)")
#endif
		return agentDatasources
	}
	
	//Add Datasource
	///Add datasource to agent
	public func addDatasourceToAgent(agentId: String, datasourceId: String) async throws -> [String: Any] {
		let data = try await request(method: .post, endpoint: "/agents/\(agentId)/datasources", data: ["datasourceId": datasourceId])
		
		guard let responseData = data as? [String: Any],
			  let agentDatasources = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
#if DEBUG
		Swift.print("add datasource to agent result: \(agentDatasources)")
#endif
		return agentDatasources
	}
	
	//Remove Datasource
	///Remove datasource from agent
	public func removeDatasourceFromAgent(agentId: String, datasourceId: String) async throws -> [String: Any] {
		let data = try await request(method: .delete, endpoint: "/agents/\(agentId)/datasources/\(datasourceId)")
		
		guard let responseData = data as? [String: Any],
			  let success = responseData["data"] as? [String: Any] else {
			throw SuperagentError.requestFailed
		}
#if DEBUG
		Swift.print("remove datasource from agent result: \(success)")
#endif
		return success
	}
	
	//List Runs
	///List agent runs
	public func listRuns(agentId: String) async throws -> [String: Any] {
		let data = try await request(method: .get, endpoint: "/agents/\(agentId)/runs")
		
		guard let responseData = data as? [String: Any],
			  let agentRuns = responseData["data"] as? [String: Any] else {
			throw SuperagentError.requestFailed
		}
#if DEBUG
		Swift.print("List agent runs result: \(agentRuns)")
#endif
		return agentRuns
	}
	
	//MARK: - LLM
	
	//List
	///List all LLMs
	public func listLLMs() async throws -> [String: Any] {
		let data = try await request(method: .get, endpoint: "/llms")
		
		guard let responseData = data as? [String: Any],
			  let llms = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
#if DEBUG
		Swift.print("list all LLMs result: \(llms)")
#endif
		
		return llms
	}
	
	//Create
	///Create a new LLM
	
