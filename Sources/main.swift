//
//  main.swift
//
//
//  Created by Simon Weniger (Aiden Technologies UG) on 19.09.23.
//

import OpenAPIRuntime
import OpenAPIURLSession

// Instantiate your chosen transport library.
let transport: ClientTransport = URLSessionTransport()

let client = Client(
	serverURL: try Servers.server(),
	transport: transport
)

let response = try await client.getGreeting(
	.init(
		query: .init(name: "CLI")
	)
)
print(response)
