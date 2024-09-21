//
//  Agent.swift
//	agent
//
//  Created by Simon Weniger on 2024/6/19.
//

import Foundation
public class AgentExecutor: DefaultChain {
    static let AGENT_REQ_ID = "agent_req_id"
    let agent: Agent
    let tools: [BaseTool]
    public init(agent: Agent, tools: [BaseTool], memory: BaseMemory? = nil, outputKey: String = "output", inputKey: String = "input", callbacks: [BaseCallbackHandler] = []) {
        self.agent = agent
        self.tools = tools
        var cbs: [BaseCallbackHandler] = callbacks
        if LC.addTraceCallbak() && !cbs.contains(where: { item in item is TraceCallbackHandler}) {
            cbs.append(TraceCallbackHandler())
        }
//        assert(cbs.count == 1)
        super.init(memory: memory, outputKey: outputKey, inputKey: inputKey, callbacks: cbs)
    }
    
    func take_next_step(input: String, intermediate_steps: [(AgentAction, String)]) async -> (Parsed, String) {
        let step = await self.agent.plan(input: input, intermediate_steps: intermediate_steps)
        switch step {
        case .finish(let finish):
            return (step, finish.final)
        case .action(let action):
            let tool = tools.filter{$0.name() == action.action}.first!
            do {
                print("try call \(tool.name()) tool.")
                var observation = try await tool.run(args: action.input)
                if observation.count > 1000 {
                    observation = String(observation.prefix(1000))
                }
                return (step, observation)
            } catch {
                print("\(error.localizedDescription) at run \(tool.name()) tool.")
                let observation = try! await InvalidTool(tool_name: tool.name()).run(args: action.input)
                return (step, observation)
            }
        default:
            return (step, "fail")
        }
    }
    public override func _call(args: String) async -> (LLMResult?, Parsed) {
        // chain run -> call -> agent plan -> llm send
        
        // while should_continue and call
//        let name_to_tool_map = tools.map { [$0.name(): $0] }
        let reqId = UUID().uuidString
        do {
            for callback in self.callbacks {
                try callback.on_agent_start(prompt: args, metadata: [AgentExecutor.AGENT_REQ_ID: reqId])
            }
        } catch {
            
        }
        var intermediate_steps: [(AgentAction, String)] = []
        while true {
            let next_step_output = await self.take_next_step(input: args, intermediate_steps: intermediate_steps)
            
            switch next_step_output.0 {
            case .finish(let finish):
                print("Found final answer.")
                do {
                for callback in self.callbacks {
                    try callback.on_agent_finish(action: finish, metadata: [AgentExecutor.AGENT_REQ_ID: reqId])
                }
                } catch {
                    
                }
                return (LLMResult(llm_output: next_step_output.1), Parsed.str(next_step_output.1))
            case .action(let action):
                    do {
                for callback in self.callbacks {
                    try callback.on_agent_action(action: action, metadata: [AgentExecutor.AGENT_REQ_ID: reqId])
                }
                    } catch {
                        
                    }
                intermediate_steps.append((action, next_step_output.1))
            default:
//                print("error step.")
                return (nil, Parsed.error)
            }
        }
    }
}

public func initialize_agent(llm: LLM, tools: [BaseTool], callbacks: [BaseCallbackHandler] = []) -> AgentExecutor {
    return AgentExecutor(agent: ZeroShotAgent(llm_chain: LLMChain(llm: llm, prompt: ZeroShotAgent.create_prompt(tools: tools), parser: ZeroShotAgent.output_parser, stop: ["\nObservation: ", "\n\tObservation: "])), tools: tools, callbacks: callbacks)
}

public class Agent {
    let llm_chain: LLMChain
    
    public init(llm_chain: LLMChain) {
        self.llm_chain = llm_chain
//        prompt = cls.create_prompt(
//                   tools,
//                   prefix=prefix,
//                   suffix=suffix,
//                   format_instructions=format_instructions,
//                   input_variables=input_variables,
//               )
//               llm_chain = LLMChain(
//                   llm=llm,
//                   prompt=prompt,
//                   callback_manager=callback_manager,
//               )
//               tool_names = [tool.name for tool in tools]
//               _output_parser = output_parser or cls._get_default_output_parser()
    }
    
    public func plan(input: String, intermediate_steps: [(AgentAction, String)]) async -> Parsed {
//        """Given input, decided what to do.
//
//                Args:
//                    intermediate_steps: Steps the LLM has taken to date,
//                        along with observations
//                    callbacks: Callbacks to run.
//                    **kwargs: User inputs.
//
//                Returns:
//                    Action specifying what tool to use.
//                """
//                output = self.llm_chain.run(
//                    intermediate_steps=intermediate_steps,
//                    stop=self.stop,
//                    callbacks=callbacks,
//                    **kwargs,
//                )
//                return self.output_parser.parse(output)
        return await llm_chain.plan(input: input, agent_scratchpad: construct_agent_scratchpad(intermediate_steps: intermediate_steps))
    }
    
    func construct_agent_scratchpad(intermediate_steps: [(AgentAction, String)]) -> String{
        if intermediate_steps.isEmpty {
            return ""
        }
        var thoughts = ""
        for (action, observation) in intermediate_steps {
            thoughts += action.log
            thoughts += "\nObservation: \(observation)\nThought: "
        }
        let ret = """
            This was your previous work
            but I haven't seen any of it! I only see what "
            you return as final answer):\n\(thoughts)
        """
        print(ret)
        return ret
    }
    
}

public class ZeroShotAgent: Agent {
    static let output_parser: MRKLOutputParser = MRKLOutputParser()
        
    public static func create_prompt(tools: [BaseTool], prefix0: String = PREFIX, suffix: String = SUFFIX, format_instructions: String = FORMAT_INSTRUCTIONS)
        -> PromptTemplate
    {
        let tool_strings = tools.map{$0.name() + ":" + $0.description()}.joined(separator: "\n")
        let tool_names = tools.map{$0.name()}.joined(separator: ", ")
        let format_instructions2 = String(format: format_instructions, tool_names)
        let template = [prefix0, tool_strings, format_instructions2, suffix].joined(separator: "\n\n")
        return PromptTemplate(input_variables: ["question", "thought"], partial_variable: [:], template: template)
    }
}
