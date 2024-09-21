//
//  graph.swift
//  agenkit
//
//  Created by vonweniger on 20.09.24.
//
import OSLog

/**
 A typealias representing a partial state of an agent.
 */
public typealias PartialAgentState = [String: Any]

/**
 A typealias representing an action to be performed on an agent state.
 
 - Parameters:
	- Action: The type of the agent state.
 - Returns: A partial state of the agent.
 */
public typealias NodeAction<Action: AgentState> = (Action) async throws -> PartialAgentState

/**
 A typealias representing a condition to be checked on an agent state.
 
 - Parameters:
	- Action: The type of the agent state.
 - Returns: A string representing the result of the condition check.
 */
public typealias EdgeCondition<Action: AgentState> = (Action) async throws -> String

/**
 A typealias representing a reducer function.
 
 - Parameters:
	- Value: The type of the value to be reduced.
 - Returns: A reduced value.
 */
public typealias Reducer<Value> = (Value?, Value) -> Value

/**
 A typealias representing a default value provider.
 
 - Returns: A default value.
 */
public typealias DefaultProvider<Value> = () throws -> Value

/**
 A typealias representing a factory for creating agent states.
 
 - Parameters:
	- State: The type of the agent state.
 - Returns: A new agent state.
 */
public typealias StateFactory<State: AgentState> = ([String: Any]) -> State

/**
 A protocol defining the requirements for a channel.
 */
public protocol ChannelProtocol {
	associatedtype T
	
	/// A reducer function for the channel.
	var reducer: Reducer<T>? { get }
	
	/// A default value provider for the channel.
	var `default`: DefaultProvider<T>? { get }

	/**
	 Updates the channel with a new value.
	 
	 - Parameters:
		- name: The name of attribute that will be updated.
		- oldValue: The old value of the channel.
		- newValue: The new value to update the channel with.
	 - Throws: An error if the update fails.
	 - Returns: The updated value.
	 */
	func updateAttribute(_ name: String, oldValue: Any?, newValue: Any) throws -> Any
}
/**
 A class representing a communication channel that conforms to `ChannelProtocol`.

 `Channel` is a generic class that provides mechanisms to update and manage values
 of a specific type. It supports optional reducer functions and default value providers
 to handle value updates and initializations.

 - Parameters:
	- T: The type of the value managed by the channel.
 */
public class Channel<T> : ChannelProtocol {
	/// A reducer function for the channel.
	public var reducer: Reducer<T>?
	
	/// A default value provider for the channel.
	public var `default`: DefaultProvider<T>?
	
	/**
	 Initializes a new instance of `Channel`.
	 
	 - Parameters:
		- reducer: An optional reducer function to handle value updates.
		- defaultValueProvider: An optional default value provider to initialize the channel's value.
	 */
	public init(reducer: Reducer<T>? = nil, default defaultValueProvider: DefaultProvider<T>? = nil ) {
		self.reducer = reducer
		self.`default` = defaultValueProvider
	}
	
	/**
	 Updates the channel with a new value.
	 
	 This method updates the channel's value by applying the reducer function if provided,
	 or directly setting the new value if no reducer is available. It also handles type
	 mismatches and provides default values when necessary.
	 
	 - Parameters:
		- name: The name of attribute that will be updated.
		- oldValue: The old value of the channel, which can be `nil`.
		- newValue: The new value to update the channel with.
	 - Throws: An error if the update fails due to type mismatches.
	 - Returns: The updated value.
	 */
	public func updateAttribute( _ name: String, oldValue: Any?, newValue: Any ) throws -> Any {
		guard let new = newValue as? T else {
			throw CompiledGraphError.executionError( "Channel: Type mismatch updating 'newValue' for property \(name)!")
		}

//        var old:T?
//        if oldValue == nil {
//            if let `default` {
//                old = try `default`()
//            }
//        }
//        else {
//            guard let _old = oldValue as? T else {
//                throw CompiledGraphError.executionError( "Channel update 'oldValue' type mismatch!")
//            }
//            old = _old
//        }
		
		var old:T?
		if( oldValue != nil ) {
			guard let _old = oldValue as? T else {
				throw CompiledGraphError.executionError( "Channel update 'oldValue' type mismatch!")
			}
			old = _old
		}
		
		if let reducer {
			return reducer( old, new )
		}
		return new
	}
}


/**
 A specialized `Channel` that appends new values to an array of existing values.
 
 `AppenderChannel` is a subclass of `Channel` designed to handle arrays of values.
 It provides functionality to append new values to the existing array, using a reducer function.
 
 - Note: The default value provider initializes the channel with an empty array if not specified.
 
 - Parameters:
	- T: The type of elements in the array managed by this channel.
 */
public class AppenderChannel<T> : Channel<[T]> {
	
	/**
	 Initializes a new instance of `AppenderChannel`.
	 
	 - Parameter defaultValueProvider: A closure that provides the default value for the channel.
	   If not provided, the default value is an empty array.
	 */
	public init(default defaultValueProvider: @escaping DefaultProvider<[T]> = { [] }) {
		super.init()
		self.reducer = { left, right in
			guard var left else {
				return right
			}
			left.append(contentsOf: right)
			return left
		}
		self.default = defaultValueProvider
	}
	
	/**
	 Updates the channel with a new value.
	 
	 This method updates the channel's value by appending the new value to the existing array.
	 If the new value is a single element, it is converted to an array before appending.
	 
	 - Parameters:
		- name: The name of attribute that will be updated.
		- oldValue: The old value of the channel, which can be `nil`.
		- newValue: The new value to update the channel with.
	 - Throws: An error if the update fails due to type mismatches.
	 - Returns: The updated value.
	 */
	public override func updateAttribute( _ name: String, oldValue: Any?, newValue: Any) throws -> Any {
		if let new = newValue as? T {
			return try super.updateAttribute( name, oldValue: oldValue, newValue: [new])
		}
		return try super.updateAttribute( name, oldValue: oldValue, newValue: newValue)
	}
}

/**
 A typealias representing channels' map in the form [<attribute name>:<related channel>].
 */
public typealias Channels = [String: any ChannelProtocol ]

/// A protocol representing the state of an agent.
///
/// The `AgentState` protocol defines the requirements for any type that represents
/// the state of an agent. It includes a dictionary to store state data and an initializer
/// to set up the initial state.
public protocol AgentState {
	
	/// A dictionary to store the state data.
	var data: [String: Any] { get }
	
	/// Initializes a new instance of an agent state with the given initial state.
	///
	/// - Parameter initState: A dictionary representing the initial state.
	init(_ initState: [String: Any])
}

/**
 AgentState extension to define accessor methods
 */
extension AgentState {

	/// Retrieves the value associated with the specified key.
	///
	/// - Parameter key: The key for which to return the corresponding value.
	/// - Returns: The value associated with `key` as type `T`, or `nil` if the key does not exist or the value cannot be cast to type `T`.
	public func value<T>(_ key: String) -> T? {
		return data[key] as? T
	}
	
}

/// A structure representing the output of a node in a state graph.
///
/// `NodeOutput` encapsulates the node identifier and its associated state.
///
/// - Parameters:
///   - State: The type conforming to `AgentState` representing the state of the node.
public struct NodeOutput<State: AgentState> {
	
	/// The identifier of the node.
	public var node: String
	
	/// The state associated with the node.
	public var state: State
	
	/// Initializes a new `NodeOutput` instance with the specified node identifier and state.
	///
	/// - Parameters:
	///   - node: A `String` representing the identifier of the node.
	///   - state: An instance of `State` representing the state associated with the node.
	public init(node: String, state: State) {
		self.node = node
		self.state = state
	}
}


/// A structure representing the base state of an agent.
///
/// `BaseAgentState` conforms to the `AgentState` protocol and provides mechanisms
/// to initialize and access the state data.
///
/// - Tag: BaseAgentState
public struct BaseAgentState: AgentState {
	
	/// Accesses the value associated with the given key.
	///
	/// - Parameter key: The key to find in the state data.
	/// - Returns: The value associated with `key`, or `nil` if the key does not exist.
	public subscript(key: String) -> Any? {
		value(key)
	}
	
	/// A dictionary to store the state data.
	public var data: [String: Any]
	
	/// Initializes a new instance of `BaseAgentState` with an empty state.
	public init() {
		data = [:]
	}
	
	/// Initializes a new instance of `BaseAgentState` with the given initial state.
	///
	/// - Parameter initState: A dictionary representing the initial state.
	public init(_ initState: [String: Any]) {
		data = initState
	}
}
/**
 An enumeration representing various errors that can occur in a `StateGraph`.

 `StateGraphError` conforms to the `Error` and `LocalizedError` protocols to provide
 detailed error descriptions for different failure scenarios in a state graph.

 - Tag: StateGraphError
 */
public enum StateGraphError: Error, LocalizedError {
	/// An error indicating a duplicate node identifier.
	///
	/// - Parameter message: A `String` describing the duplicate node error.
	case duplicateNodeError(String)
	
	/// An error indicating a duplicate edge identifier.
	///
	/// - Parameter message: A `String` describing the duplicate edge error.
	case duplicateEdgeError(String)
	
	/// An error indicating a missing entry point in the state graph.
	case missingEntryPoint
	
	/// An error indicating that the specified entry point does not exist.
	///
	/// - Parameter message: A `String` describing the missing entry point error.
	case entryPointNotExist(String)
	
	/// An error indicating that the specified finish point does not exist.
	///
	/// - Parameter message: A `String` describing the missing finish point error.
	case finishPointNotExist(String)
	
	/// An error indicating a missing node in the edge mapping.
	///
	/// - Parameter message: A `String` describing the missing node in edge mapping error.
	case missingNodeInEdgeMapping(String)
	
	/// An error indicating that the edge mapping is empty.
	case edgeMappingIsEmpty
	
	/// An error indicating an invalid edge identifier.
	///
	/// - Parameter message: A `String` describing the invalid edge identifier error.
	case invalidEdgeIdentifier(String)
	
	/// An error indicating an invalid node identifier.
	///
	/// - Parameter message: A `String` describing the invalid node identifier error.
	case invalidNodeIdentifier(String)
	
	/// An error indicating a missing node referenced by an edge.
	///
	/// - Parameter message: A `String` describing the missing node referenced by edge error.
	case missingNodeReferencedByEdge(String)
	
	/// A localized description of the error.
	public var errorDescription: String? {
		switch self {
		case .duplicateNodeError(let message):
			return message
		case .duplicateEdgeError(let message):
			return message
		case .missingEntryPoint:
			return "Missing entry point!"
		case .entryPointNotExist(let message):
			return message
		case .finishPointNotExist(let message):
			return message
		case .missingNodeInEdgeMapping(let message):
			return message
		case .edgeMappingIsEmpty:
			return "Edge mapping is empty!"
		case .invalidNodeIdentifier(let message):
			return message
		case .missingNodeReferencedByEdge(let message):
			return message
		case .invalidEdgeIdentifier(let message):
			return message
		}
	}
}

/**
 An enumeration representing errors that can occur in a compiled graph.

 The `CompiledGraphError` enumeration defines various error cases that can be encountered
 during the execution and manipulation of a compiled graph. Each case is associated with
 a descriptive message to provide more context about the error.

 - Conforms To: `Error`, `LocalizedError`
 */
public enum CompiledGraphError: Error, LocalizedError {
	/**
	 An error indicating that an edge is missing in the graph.
	 
	 - Parameter message: A `String` describing the missing edge error.
	 */
	case missingEdge(String)
	
	/**
	 An error indicating that a node is missing in the graph.
	 
	 - Parameter message: A `String` describing the missing node error.
	 */
	case missingNode(String)
	
	/**
	 An error indicating a missing node in the edge mapping.
	 
	 - Parameter message: A `String` describing the missing node in edge mapping error.
	 */
	case missingNodeInEdgeMapping(String)
	
	/**
	 An error indicating an execution error in the graph.
	 
	 - Parameter message: A `String` describing the execution error.
	 */
	case executionError(String)
	
	/**
	 A localized description of the error.
	 
	 This property provides a human-readable description of the error, which can be used
	 for displaying error messages to the user.
	 
	 - Returns: A `String` describing the error.
	 */
	public var errorDescription: String? {
		switch self {
		case .missingEdge(let message):
			return message
		case .missingNode(let message):
			return message
		case .missingNodeInEdgeMapping(let message):
			return message
		case .executionError(let message):
			return message
		}
	}
}

/// Identifier of the edge staring workflow ( = `"__START__"` )
public let START = "__START__"
/// Identifier of the edge ending workflow ( = `"__END__"` )
public let END = "__END__"

//enum Either<Left, Right> {
//    case left(Left)
//    case right(Right)
//}

/// private log for module
let log = Logger( subsystem: Bundle.module.bundleIdentifier ?? "agentkit", category: "main")

/// A class representing a state graph.
///
/// `StateGraph` is a generic class that manages the state transitions and actions within a state graph.
/// It allows adding nodes and edges, including conditional edges, and provides functionality to compile
/// the graph into a `CompiledGraph`.
///
/// - Parameters:
///    - State: The type of the agent state managed by the graph.
public class StateGraph<State: AgentState>  {
	
	/// An enumeration representing the value of an edge.
	///
	/// `EdgeValue` can either be an identifier or a condition with edge mappings.
	enum EdgeValue {
		/// Represents an edge with a target identifier.
		case id(String)
		
		/// Represents an edge with a condition and edge mappings.
		case condition( ( EdgeCondition<State>, [String:String] ) )
	}
	
	/// A structure representing an edge in the state graph.
	///
	/// `Edge` conforms to `Hashable` and `Identifiable` protocols.
	struct Edge : Hashable, Identifiable {
		var id: String {
			sourceId
		}
		
		static func == (lhs: StateGraph.Edge, rhs: StateGraph.Edge) -> Bool {
			lhs.id == rhs.id
		}
		
		func hash(into hasher: inout Hasher) {
			id.hash(into: &hasher)
		}
		
		var sourceId: String
		var target: EdgeValue
	}

	private var edges: Set<Edge> = []
	
	/// A structure representing a node in the state graph.
	///
	/// `Node` conforms to `Hashable` and `Identifiable` protocols.
	struct Node : Hashable, Identifiable {
		static func == (lhs: StateGraph.Node, rhs: StateGraph.Node) -> Bool {
			lhs.id == rhs.id
		}
		
		func hash(into hasher: inout Hasher) {
			id.hash(into: &hasher)
		}
		
		var id: String
		var action: NodeAction<State>
	}
	
	private var nodes: Set<Node> = []

	private var entryPoint: EdgeValue?
	private var finishPoint: String?

	private var stateFactory: StateFactory<State>
	private var channels: Channels
	
	/// Initializes a new instance of `StateGraph`.
	///
	/// - Parameters:
	///    - channels: A dictionary representing the channels in the graph.
	///    - stateFactory: A closure that provides the state factory for creating agent states.
	public init( channels: Channels = [:], stateFactory: @escaping StateFactory<State> ) {
		self.channels = channels
		self.stateFactory = stateFactory
	}
	
	/// Adds a node to the state graph.
	///
	/// - Parameters:
	///    - id: The identifier of the node.
	///    - action: A closure representing the action to be performed on the node.
	/// - Throws: An error if the node identifier is invalid or if a node with the same identifier already exists.
	public func addNode( _ id: String, action: @escaping NodeAction<State> ) throws  {
		guard id != END else {
			throw StateGraphError.invalidNodeIdentifier( "END is not a valid node id!")
		}
		let node = Node(id: id, action: action)
		if nodes.contains(node) {
			throw StateGraphError.duplicateNodeError("node with id:\(id) already exist!")
		}
		nodes.insert( node )
	}
	
	/// Adds an edge to the state graph.
	///
	/// - Parameters:
	///    - sourceId: The identifier of the source node.
	///    - targetId: The identifier of the target node.
	/// - Throws: An error if the edge identifiers are invalid or if an edge with the same source identifier already exists.
	public func addEdge( sourceId: String, targetId: String ) throws {
		guard sourceId != END else {
			throw StateGraphError.invalidEdgeIdentifier( "END is not a valid edge sourceId!")
		}
		guard sourceId != START else {
			if targetId == END  {
				throw StateGraphError.invalidNodeIdentifier( "END is not a valid node entry point!")
			}
			entryPoint = EdgeValue.id(targetId)
			return
		}

		let edge = Edge(sourceId: sourceId, target: .id(targetId) )
		if edges.contains(edge) {
			throw StateGraphError.duplicateEdgeError("edge with id:\(sourceId) already exist!")
		}
		edges.insert( edge )
	}
	
	/// Adds a conditional edge to the state graph.
	///
	/// - Parameters:
	///    - sourceId: The identifier of the source node.
	///    - condition: A closure representing the condition to be checked on the edge.
	///    - edgeMapping: A dictionary representing the edge mappings.
	/// - Throws: An error if the edge identifiers are invalid or if the edge mapping is empty.
	public func addConditionalEdge( sourceId: String, condition: @escaping EdgeCondition<State>, edgeMapping: [String:String] ) throws {
		guard sourceId != END else {
			throw StateGraphError.invalidEdgeIdentifier( "END is not a valid edge sourceId!")
		}
		if edgeMapping.isEmpty {
			throw StateGraphError.edgeMappingIsEmpty
		}
		guard sourceId != START else {
			entryPoint = EdgeValue.condition((condition, edgeMapping))
			return
		}

		let edge = Edge(sourceId: sourceId, target: .condition(( condition, edgeMapping)) )
		if edges.contains(edge) {
			throw StateGraphError.duplicateEdgeError("edge with id:\(sourceId) already exist!")
		}
		edges.insert( edge)
		return
	}
	
	/// Sets the entry point of the state graph.
	///
	/// - Parameter nodeId: The identifier of the entry point node.
	/// - Throws: An error if the entry point is invalid.
	@available(*, deprecated, message: "This method is deprecated. Use `addEdge( START, nodeId )` instead.")
	public func setEntryPoint( _ nodeId: String ) throws {
		let _ = try addEdge( sourceId: START, targetId: nodeId )
	}

	/// Sets the conditional entry point of the state graph.
	///
	/// - Parameters:
	///    - condition: A closure representing the condition to be checked on the edge.
	///    - edgeMapping: A dictionary representing the edge mappings.
	/// - Throws: An error if the entry point is invalid.
	@available(*, deprecated, message: "This method is deprecated. Use `addConditionalEdge( START, condition, edgeMappings )` instead.")
	public func setConditionalEntryPoint( condition: @escaping EdgeCondition<State>, edgeMapping: [String:String] ) throws {
		let _ = try self.addConditionalEdge(sourceId: START, condition: condition, edgeMapping: edgeMapping )
	}
	
	/// Sets the finish point of the state graph.
	///
	/// - Parameter nodeId: The identifier of the finish point node.
	@available(*, deprecated, message: "This method is deprecated. Use `addEdge( nodeId, END )` instead.")
	public func setFinishPoint( _ nodeId: String ) {
		finishPoint = nodeId
	}
	
	private var fakeAction: NodeAction<State> = { _ in return [:] }

	private func makeFakeNode( _ id: String ) -> Node {
		Node(id: id, action: fakeAction)
	}
	
	/// Compiles the state graph into a `CompiledGraph`.
	///
	/// - Throws: An error if the entry point or finish point is invalid, or if there are missing nodes referenced by edges.
	/// - Returns: A `CompiledGraph` instance representing the compiled state graph.
	public func compile() throws -> CompiledGraph {
		guard let entryPoint else {
			throw StateGraphError.missingEntryPoint
		}
		
		switch( entryPoint ) {
			case .id( let targetId ):
				guard nodes.contains( makeFakeNode( targetId ) ) else {
					throw StateGraphError.entryPointNotExist( "entryPoint: \(targetId) doesn't exist!")
				}
			break
			case .condition((_, let edgeMappings)):
				for (_,nodeId) in edgeMappings {
					guard nodeId == END || nodes.contains(makeFakeNode(nodeId) ) else {
						throw StateGraphError.missingNodeInEdgeMapping( "edge mapping for entryPoint contains a not existent nodeId \(nodeId)!")
					}
				}
			break
		}
		
		if let finishPoint {
			guard nodes.contains( makeFakeNode( finishPoint ) ) else {
				throw StateGraphError.finishPointNotExist( "finishPoint: \(finishPoint) doesn't exist!")
			}
		}
		
		for edge in edges {
			guard nodes.contains( makeFakeNode(edge.sourceId) ) else {
				throw StateGraphError.missingNodeReferencedByEdge( "edge sourceId: \(edge.sourceId) reference to non existent node!")
			}

			switch( edge.target ) {
			case .id( let targetId ):
				guard targetId == END || nodes.contains(makeFakeNode(targetId) ) else {
					throw StateGraphError.missingNodeReferencedByEdge( "edge sourceId: \(edge.sourceId) reference to non existent node targetId: \(targetId) node!")
				}
				break
			case .condition((_, let edgeMappings)):
				for (_,nodeId) in edgeMappings {
					guard nodeId == END || nodes.contains(makeFakeNode(nodeId) ) else {
						throw StateGraphError.missingNodeInEdgeMapping( "edge mapping for sourceId: \(edge.sourceId) contains a not existent nodeId \(nodeId)!")
					}
				}
			}
		}
		
		return CompiledGraph( owner: self )
	}
}


extension StateGraph {
	
	/**
	 A class representing a compiled state graph.
	 
	 The `CompiledGraph` class is responsible for managing the state transitions and actions
	 within a state graph. It initializes the state data, updates partial states, merges states,
	 and determines the next node in the graph based on conditions and mappings.
	 
	 - Note: This class is intended to be used internally by the `StateGraph` class.
	 */
	public class CompiledGraph {
	
		/// A factory for creating agent states.
		var stateFactory: StateFactory<State>
		
		/// A dictionary mapping node IDs to their corresponding actions.
		var nodes: Dictionary<String, NodeAction<State>>
		
		/// A dictionary mapping edge source IDs to their corresponding edge values.
		var edges: Dictionary<String, EdgeValue>
		
		/// The entry point of the graph.
		var entryPoint: EdgeValue
		
		/// The finish point of the graph, if any.
		var finishPoint: String?
		
		/// The schema representing the channels in the graph.
		let schema: Channels
		
		/**
		 Initializes a new instance of `CompiledGraph`.
		 
		 - Parameter owner: The `StateGraph` instance that owns this compiled graph.
		 */
		init(owner: StateGraph) {
			self.schema = owner.channels
			self.stateFactory = owner.stateFactory
			self.nodes = Dictionary()
			self.edges = Dictionary()
			self.entryPoint = owner.entryPoint!
			self.finishPoint = owner.finishPoint
			
			owner.nodes.forEach { [unowned self] node in
				nodes[node.id] = node.action
			}
			
			owner.edges.forEach { [unowned self] edge in
				edges[edge.sourceId] = edge.target
			}
		}
		
		/**
		 Initializes the state data from the schema.
		 
		 - Returns: A dictionary representing the initial state data.
		 */
		private func initStateDataFromSchema() throws -> [String: Any] {
			let mappedValues = try schema.compactMap { key, channel in
				if let def = channel.`default` {
					return (key, try def())
				}
				return nil
			}
			
			return Dictionary(uniqueKeysWithValues: mappedValues)
		}
		
		/**
		 Updates the partial state from the schema.
		 
		 - Parameters:
			- currentState: The current state of the agent.
			- partialState: The partial state to be updated.
		 - Throws: An error if the update fails.
		 - Returns: The updated partial state.
		 */
		private func updatePartialStateFromSchema(currentState: State, partialState: PartialAgentState) throws -> PartialAgentState {
			let mappedValues = try partialState.map { key, value in
				if let channel = schema[key] {
					do {
						let newValue = try channel.updateAttribute( key, oldValue: currentState.data[key], newValue: value)
						return (key, newValue)
					} catch CompiledGraphError.executionError(let message) {
						throw CompiledGraphError.executionError("error processing property: '\(key)' - \(message)")
					}
				}
				return (key, value)
			}
			
			return Dictionary(uniqueKeysWithValues: mappedValues)
		}
		
		/**
		 Merges the current state with the partial state.
		 
		 - Parameters:
			- currentState: The current state of the agent.
			- partialState: The partial state to be merged.
		 - Throws: An error if the merge fails.
		 - Returns: The merged state.
		 */
		private func mergeState(currentState: State, partialState: PartialAgentState) throws -> State {
			if partialState.isEmpty {
				return currentState
			}
			
			let partialSchemaUpdated = try updatePartialStateFromSchema(currentState: currentState, partialState: partialState)
			
			let newState = currentState.data.merging(partialSchemaUpdated, uniquingKeysWith: { (current, new) in
				return new
			})
			return State.init(newState)
		}
		
		/**
		 Determines the next node ID based on the given route and agent state.
		 
		 - Parameters:
			- route: The edge value representing the route.
			- agentState: The current state of the agent.
			- nodeId: The current node ID.
		 - Throws: An error if the next node ID cannot be determined.
		 - Returns: The next node ID.
		 */
		private func nextNodeId(route: EdgeValue?, agentState: State, nodeId: String) async throws -> String {
			guard let route else {
				throw CompiledGraphError.missingEdge("edge with node: \(nodeId) not found!")
			}
			
			switch(route) {
			case .id(let nextNodeId):
				return nextNodeId
			case .condition(let (condition, mapping)):
				let newRoute = try await condition(agentState)
				guard let result = mapping[newRoute] else {
					throw CompiledGraphError.missingNodeInEdgeMapping("cannot find edge mapping for id: \(newRoute) in conditional edge with sourceId:\(nodeId)")
				}
				return result
			}
		}

		/**
		 Determines the next node ID based on the current node ID and agent state.
		 
		 - Parameters:
			- nodeId: The current node ID.
			- agentState: The current state of the agent.
		 - Throws: An error if the next node ID cannot be determined.
		 - Returns: The next node ID.
		 */
		private func nextNodeId(nodeId: String, agentState: State) async throws -> String {
			try await nextNodeId(route: edges[nodeId], agentState: agentState, nodeId: nodeId)
		}

		/**
		 Determines the entry point of the graph based on the agent state.
		 
		 - Parameter agentState: The current state of the agent.
		 - Throws: An error if the entry point cannot be determined.
		 - Returns: The entry point node ID.
		 */
		private func getEntryPoint(agentState: State) async throws -> String {
			try await nextNodeId(route: self.entryPoint, agentState: agentState, nodeId: "entryPoint")
		}

		/**
		 Streams the node outputs based on the given inputs.
		 
		 - Parameters:
			- inputs: The partial state inputs.
			- verbose: A boolean indicating whether to enable verbose logging.
		 - Returns: An `AsyncThrowingStream` of `NodeOutput<State>`.
		 */
		public func stream(inputs: PartialAgentState, verbose: Bool = false) -> AsyncThrowingStream<NodeOutput<State>, Error> {
			let (stream, continuation) = AsyncThrowingStream.makeStream(of: NodeOutput<State>.self, throwing: Error.self)
			
			Task {
				do {
					let initData = try initStateDataFromSchema()
					var currentState = try mergeState(currentState: self.stateFactory(initData), partialState: inputs)
					var currentNodeId = try await self.getEntryPoint(agentState: currentState)

					repeat {
						guard let action = nodes[currentNodeId] else {
							continuation.finish(throwing: CompiledGraphError.missingNode("node: \(currentNodeId) not found!"))
							break
						}
						
						if(verbose) {
							log.debug("start processing node \(currentNodeId)")
						}
						
						try Task.checkCancellation()
						let partialState = try await action(currentState)
						currentState = try mergeState(currentState: currentState, partialState: partialState)
						let output = NodeOutput(node: currentNodeId, state: currentState)
						
						try Task.checkCancellation()
						continuation.yield(output)

						if(currentNodeId == finishPoint) {
							break
						}
						
						currentNodeId = try await nextNodeId(nodeId: currentNodeId, agentState: currentState)
						
					} while(currentNodeId != END && !Task.isCancelled)
					
					continuation.finish()
				} catch {
					continuation.finish(throwing: error)
				}
			}
			
			return stream
		}
		
		/**
		 Runs the graph and returns the final state.
		 
		 - Parameters:
			- inputs: The partial state inputs.
			- verbose: A boolean indicating whether to enable verbose logging.
		 - Throws: An error if the invocation fails.
		 - Returns: The final state.
		 */
		public func invoke(inputs: PartialAgentState, verbose: Bool = false) async throws -> State {
			let initResult: [NodeOutput<State>] = []
			let result = try await stream(inputs: inputs).reduce(initResult, { partialResult, output in
				[output]
			})
			if result.isEmpty {
				throw CompiledGraphError.executionError("no state has been produced! probably processing has been interrupted")
			}
			return result[0].state
		}
	}

}