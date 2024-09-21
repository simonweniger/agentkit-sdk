//
//  File.swift
//  
//
//  Created by Simon Weniger on 2024/6/23.
//

import Foundation

public class Dummy: BaseTool {
    public override init(callbacks: [BaseCallbackHandler] = []) {
        super.init(callbacks: callbacks)
    }
    public override func name() -> String {
        "dummy"
    }
    
    public override func description() -> String {
        "Useful for test."
    }
    
    public override func _run(args: String) async throws -> String {
        "Dummy test"
    }
    
    
}
