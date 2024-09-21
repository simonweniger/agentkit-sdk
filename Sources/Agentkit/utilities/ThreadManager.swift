//
//  File.swift
//  
//
//  Created by Simon Weniger on 2024/11/10.
//

import Foundation
import NIOPosix
import NIOCore

struct ThreadManager {
    static let thread: MultiThreadedEventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
}
