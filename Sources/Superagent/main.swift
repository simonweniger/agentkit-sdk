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
		let data = try await request(method: .patch, endpoint: "/agents/\(agentId)", data: payload)
		
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
	public func createLLM(provider: String, apiKey: String, options: [String: Any]?) async throws -> [String: Any] {
		var payload: [String: Any] = ["provider": provider, "apiKey": apiKey, "options": options as Any]
		
		let data = try await request(method: .post, endpoint: "/llms", data: payload)
		
		guard let responseData = data as? [String: Any],
			  let llm = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
#if DEBUG
		Swift.print("create new llm result: \(llm)")
#endif
		
		return llm
	}
	
	//Get
	///Get a single LLM
	public func getLLM(llmId: String) async throws -> [String: Any] {
		let data = try await request(method: .get, endpoint: "/llms/\(llmId)")
		
		guard let responseData = data as? [String: Any],
			  let llm = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
#if DEBUG
		Swift.print("get LLM result: \(llm)")
#endif
		
		return llm
	}
	
	//Update
	///Patch an LLM
	public func createLLM(llmId: String ,provider: String, apiKey: String, options: [String: Any]?) async throws -> [String: Any] {
		var payload: [String: Any] = ["provider": provider, "apiKey": apiKey]
		
		if let options = options {
			payload["options"] = options
		} else {
			payload["options"] = nil
		}
		
		let data = try await request(method: .patch, endpoint: "/llms/\(llmId)", data: payload)
		
		guard let responseData = data as? [String: Any],
			  let llm = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
#if DEBUG
		Swift.print("create new llm result: \(llm)")
#endif
		
		return llm
	}
	
	//MARK: - API User
	
	//Create
	///Create a new API user
	public func createNewApiUser() async throws -> [String: Any] {
		let data = try await request(method: .post, endpoint: "/api-users")
		
		guard let responseData = data as? [String: Any],
			  let success = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
#if DEBUG
		Swift.print("create new API user result: \(success)")
#endif
		
		return success
	}
	
	//Get
	///Get a single api user
	public func getApiUser() async throws -> [String: Any] {
		let data = try await request(method: .get, endpoint: "/api-users/me")
		
		guard let responseData = data as? [String: Any],
			  let success = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
#if DEBUG
		Swift.print("get API user result: \(success)")
#endif
		
		return success
	}
	
	//Delete
	///Delete an api user
	public func deleteApiUser() async throws -> [String: Any] {
		let data = try await request(method: .delete, endpoint: "/api-users/me")
		
		guard let responseData = data as? [String: Any],
			  let success = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
#if DEBUG
		Swift.print("delete API user result: \(success)")
#endif
		
		return success
	}
	
	//MARK: - Datasource
	
	//List
	///List all datasources
	public func listDatasources() async throws -> [String: Any] {
		let data = try await request(method: .get, endpoint: "/datasources")
		
		guard let responseData = data as? [String: Any],
			  let datasources = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
#if DEBUG
		Swift.print("list datasources result: \(datasources)")
#endif
		
		return datasources
	}
	
	//Create
	///Create a new datasource
	public func createDatasource(datasource: Datasource) async throws -> [String: Any] {
		var payload: [String: Any] = ["name": datasource.name,
									  "description": datasource.description,
									  "type": datasource.type,
									  "url": datasource.url,
									  "metadata": datasource.metadata as Any]
		
		let data = try await request(method: .post, endpoint: "/datasources", data: payload)
		
		guard let responseData = data as? [String: Any],
			  let llm = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
#if DEBUG
		Swift.print("create new llm result: \(llm)")
#endif
		
		return llm
	}
	
	//Get
	///Get a specific datasource
	public func getDatasource(datasourceId: String) async throws -> [String: Any] {
		let data = try await request(method: .get, endpoint: "/datasources/\(datasourceId)")
		
		guard let responseData = data as? [String: Any],
			  let datasource = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
#if DEBUG
		Swift.print("get datasource result: \(datasource)")
#endif
		
		return datasource
	}
	
	//Update
	///Update a specific datasource
	public func updateDatasource(datasourceId: String , newDatasource: Datasource) async throws -> [String: Any] {
		var payload: [String: Any] = ["name": newDatasource.name,
									  "description": newDatasource.description,
									  "type": newDatasource.type,
									  "url": newDatasource.url]
		
		if let metadata = newDatasource.metadata {
			payload["metadata"] = metadata
		} else {
			payload["metadata"] = nil
		}
		
		let data = try await request(method: .patch, endpoint: "/datasources/\(datasourceId)", data: payload)
		
		guard let responseData = data as? [String: Any],
			  let datasource = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
#if DEBUG
		Swift.print("update datasource result: \(datasource)")
#endif
		
		return datasource
	}
	
	//Delete
	///Delete a specific datasource
	public func deleteDatasource(datasourceId: String) async throws -> [String: Any] {
		let data = try await request(method: .delete, endpoint: "/datasources/\(datasourceId)")
		
		guard let responseData = data as? [String: Any],
			  let success = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
#if DEBUG
		Swift.print("delete Datasource result: \(success)")
#endif
		
		return success
	}
	
	//MARK: - Tool
	
	//List
	///List all tools
	public func listTools() async throws -> [String: Any] {
		let data = try await request(method: .get, endpoint: "/tools")
		
		guard let responseData = data as? [String: Any],
			  let tools = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
#if DEBUG
		Swift.print("list tools result: \(tools)")
#endif
		
		return tools
	}
	
	//Create
	///Create a new tool
	public func createTool(tool: Tool) async throws -> [String: Any] {
		var payload: [String: Any] = ["name": tool.name,
									  "description": tool.description,
									  "type": tool.type,
									  "metadata": tool.metadata as Any,
									  "returnDirect": tool.returnDirect as Any]
		
		let data = try await request(method: .post, endpoint: "/tools", data: payload)
		
		guard let responseData = data as? [String: Any],
			  let tool = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
#if DEBUG
		Swift.print("create new tool result: \(tool)")
#endif
		
		return tool
	}
	
	//Get
	///Get a specific tool
	public func getTool(toolId: String) async throws -> [String: Any] {
		let data = try await request(method: .get, endpoint: "/tool/\(toolId)")
		
		guard let responseData = data as? [String: Any],
			  let tool = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
#if DEBUG
		Swift.print("get tool result: \(tool)")
#endif
		
		return tool
	}
	
	//Update
	///Update a specific tool
	public func updateTool(toolId: String , newTool: Tool) async throws -> [String: Any] {
		var payload: [String: Any] = ["name": newTool.name,
									  "description": newTool.description,
									  "type": newTool.type,
									  "metadata": newTool.metadata as Any,
									  "returnDirect": newTool.returnDirect as Any]
		
		let data = try await request(method: .post, endpoint: "/tools/\(toolId)", data: payload)
		
		guard let responseData = data as? [String: Any],
			  let tool = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
#if DEBUG
		Swift.print("create new tool result: \(tool)")
#endif
		
		return tool
	}
	
	//Delete
	///Delete a specific tool
	public func deleteTool(toolId: String) async throws -> [String: Any] {
		let data = try await request(method: .delete, endpoint: "/tools/\(toolId)")
		
		guard let responseData = data as? [String: Any],
			  let success = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
#if DEBUG
		Swift.print("delete Datasource result: \(success)")
#endif
		
		return success
	}

	//MARK: - Workflow
	
	//List
	///List all workflows
	public func listWorkflows() async throws -> [String: Any] {
	let data = try await request(method: .get, endpoint: "/workflows")
	   
	   guard let responseData = data as? [String: Any],
			 let workflows = responseData["data"] as? [String: Any] else {
		   throw SuperagentError.failedToRetrieve
	   }
	   
#if DEBUG
	   Swift.print("list workflows result: \(workflows)")
#endif
	   
	   return workflows
   }
	
	//Create
	///Create a new workflow
	public func createWorkflow(name: String, description: String) async throws -> [String: Any] {
		
		let data = try await request(method: .post, endpoint: "workflows", data: ["name": name, "description": description])
		
		guard let responseData = data as? [String: Any],
			  let workflow = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
 #if DEBUG
		Swift.print("create Workflow result: \(workflow)")
 #endif
		
		return workflow
	}
	
	//Get
	///Get a single workflow
	public func getWorkflow(workflowId: String) async throws -> [String: Any] {
		let data = try await request(method: .get, endpoint: "workflows/\(workflowId)")
		
		guard let responseData = data as? [String: Any],
			  let workflow = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
 #if DEBUG
		Swift.print("get Workflow result: \(workflow)")
 #endif
		
		return workflow
	}
	
	//Update
	///Patch a workflow
	public func updateWorkflow(workflowId: String, newName: String, newDescription: String) async throws -> [String: Any] {
		let data = try await request(method: .get, endpoint: "workflows/\(workflowId)", data: ["name": newName, "description": newDescription])
		
		guard let responseData = data as? [String: Any],
			  let workflow = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
 #if DEBUG
		Swift.print("get Workflow result: \(workflow)")
 #endif
		
		return workflow
	}
	
	//Delete
	///Delete a specific workflow
	public func deleteWorkflow(workflowId: String) async throws -> [String: Any] {
		let data = try await request(method: .delete, endpoint: "workflows/\(workflowId)")
		
		guard let responseData = data as? [String: Any],
			  let workflow = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
 #if DEBUG
		Swift.print("get Workflow result: \(workflow)")
 #endif
		
		return workflow
	}
	
	//Invoke
	///Invoke a specific workflow
	public func invokeWorkflow(workflowId: String, input: String, enableStreaming: Bool) async throws -> [String: Any] {
		let data = try await request(method: .post, endpoint: "workflows/\(workflowId)", data: ["input": input, "enableStreaming": enableStreaming])
		
		guard let responseData = data as? [String: Any],
			  let workflowResponse = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
 #if DEBUG
		Swift.print("invoke Workflow result: \(workflowResponse)")
 #endif
		
		return workflowResponse
	}
	
	//List Steps
	///List all steps of a workflow
	public func listWorkflowSteps(workflowId: String) async throws -> [String: Any] {
		let data = try await request(method: .get, endpoint: "workflows/\(workflowId)/steps")
		
		guard let responseData = data as? [String: Any],
			  let workflowSteps = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
 #if DEBUG
		Swift.print("list Workflow Steps result: \(workflowSteps)")
 #endif
		
		return workflowSteps
	}
	
	
	//Add Step
	///Create a new workflow step
	public func addWorkflowStep(workflowId: String ,workflowStep: WorkflowStep) async throws -> [String: Any] {
		var payload: [String: Any] = ["order": workflowStep.order,
									  "agentId": workflowStep.agentId,
									  "input": workflowStep.input,
									  "output": workflowStep.output]
		
		let data = try await request(method: .post, endpoint: "/workflows/\(workflowId)/steps", data: payload)
		
		guard let responseData = data as? [String: Any],
			  let workflowStep = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
#if DEBUG
		Swift.print("add workflow step result: \(workflowStep)")
#endif
		
		return workflowStep
	}
	
	//Delete Step
	///Delete a specific workflow step
	public func deleteWorkflowStep(workflowId: String, stepId: String) async throws -> [String: Any] {
		let data = try await request(method: .delete, endpoint: "workflows/\(workflowId)/steps\(stepId)")
		
		guard let responseData = data as? [String: Any],
			  let success = responseData["data"] as? [String: Any] else {
			throw SuperagentError.failedToRetrieve
		}
		
 #if DEBUG
		Swift.print("delete workflow step result: \(success)")
 #endif
		
		return success
		
	}

	
}
