//
//  File.swift
//  
//
//  Created by Simon Weniger on 2024/8/7.
//

import Foundation
public class MultiRouteChain: DefaultChain {
    let router_chain: LLMRouterChain
        
    let destination_chains: [String: DefaultChain]

    let default_chain: DefaultChain
    
    public init(router_chain: LLMRouterChain, destination_chains: [String : DefaultChain], default_chain: DefaultChain, memory: BaseMemory? = nil, outputKey: String = "output", inputKey: String = "input", callbacks: [BaseCallbackHandler] = []) {
        self.router_chain = router_chain
        self.destination_chains = destination_chains
        self.default_chain = default_chain
        super.init(memory: memory, outputKey: outputKey, inputKey: inputKey, callbacks: callbacks)
    }
    
    // call route
    public override func _call(args: String) async -> (LLMResult?, Parsed) {
//        print("call route.")
        let route = await self.router_chain.route(args: args)
        if destination_chains.keys.contains(route.destination) {
            return await destination_chains[route.destination]!._call(args: route.next_inputs)
        } else {
            return await default_chain._call(args: route.next_inputs)
        }
    }
}
