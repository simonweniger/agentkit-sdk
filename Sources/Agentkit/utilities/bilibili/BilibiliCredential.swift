//
//  File.swift
//  
//
//  Created by Simon Weniger on 2024/7/31.
//

import Foundation

public struct BilibiliCredential {
    let sessin: String
    let jct: String
    
    public init(sessin: String, jct: String) {
        self.sessin = sessin
        self.jct = jct
    }
}
