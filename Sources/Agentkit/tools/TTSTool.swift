//
//  File.swift
//  
//
//  Created by Simon Weniger on 2024/11/10.
//

import Foundation
import AVFoundation

public class TTSTool: BaseTool {
    var audioPlayer: AVAudioPlayer?
    public override init(callbacks: [BaseCallbackHandler] = []) {
        super.init(callbacks: callbacks)
    }
    public override func name() -> String {
        "TTS"
    }
    
    public override func description() -> String {
        """
        useful for convert text into sound and play it, returning the sound file path
"""
    }
    
    public override func _run(args: String) async throws -> String {
        let env = LC.loadEnv()
        
        if let apiKey = env["OPENAI_API_KEY"] {
            let baseUrl = env["OPENAI_API_BASE"] ?? "api.openai.com"
            let data = await OpenAITTSAPIWrapper().tts(text: args, key: apiKey, base: baseUrl)
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

            guard let path = paths.first else {
                throw AgentkitError.ToolError
            }

            let url = path.appendingPathComponent("tts-\(UUID().uuidString).mp3")
            do {
                try data?.write(to: url)
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
                return url.absoluteString
            } catch {
                throw AgentkitError.ToolError
            }
        } else {
            throw AgentkitError.ToolError
        }
    }
}
