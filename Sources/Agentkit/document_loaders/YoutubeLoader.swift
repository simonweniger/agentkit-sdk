//
//  File.swift
//
//
//  Created by Simon Weniger on 2024/6/29.
//

import Foundation
import AsyncHTTPClient
import Foundation
import NIOPosix


public class YoutubeLoader: BaseLoader {
	let video_id: String
	let language: String
	public init(video_id: String, language: String, callbacks: [BaseCallbackHandler] = []) {
		self.video_id = video_id
		self.language = language
		super.init(callbacks: callbacks)
	}
	public override func _load() async throws -> [Document] {
		
		let eventLoopGroup = ThreadManager.thread
		
		let httpClient = HTTPClient(eventLoopGroupProvider: .shared(eventLoopGroup))
		
		defer {
			httpClient.shutdown { error in
				if let error = error {
					print("Error shutting down HTTP client: \(error)")
				}
			}
		}
		
		let info = await YoutubeHackClient.info(video_id: video_id, httpClient: httpClient)
		let metadata = ["source": self.video_id,
						"title": info!.title,
						"desc": info!.description,
						"thumbnail": info!.thumbnail]
		var transcript_list = await YoutubeHackClient.list_transcripts(video_id: self.video_id, httpClient: httpClient)
		if transcript_list == nil {
			throw AgentkitError.LoaderError("Subtitle not exist")
		}
		if transcript_list!.generated_transcripts.isEmpty && transcript_list!.manually_created_transcripts.isEmpty {
			//            return [Document(page_content: "Content is empty.", metadata: metadata)]
			throw AgentkitError.LoaderError("Subtitle not exist")
		}
		var transcript = transcript_list!.find_transcript(language_codes: [self.language])
		if transcript == nil {
			let en_transcript = transcript_list!.manually_created_transcripts.first!.value
			transcript = en_transcript.translate(language_code: self.language)
		}
		let transcript_pieces = await transcript!.fetch()
		
		let text = transcript_pieces!.map {$0["text"]!}.joined(separator: " ")
		
		return [Document(page_content: text, metadata: metadata)]
		
	}
	
	override func type() -> String {
		"Youtube"
	}
}
