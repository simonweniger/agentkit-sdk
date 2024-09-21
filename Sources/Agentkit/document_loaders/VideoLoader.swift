//
//  VideoLoader.swift
//  agenkit
//
//  Created by vonweniger on 21.09.24.
//
#if os(macOS) || os(iOS) || os(visionOS)
import Foundation
import NIOPosix
import AsyncHTTPClient
import OpenAIKit
import AVFoundation

public class VideoLoader: BaseLoader {
	static let SEG_SIZE = 60 // 60 seconds per segment
	let video: URL
	let fileName: String
	
	public init(video: URL, fileName: String, callbacks: [BaseCallbackHandler] = []) {
		self.video = video
		self.fileName = fileName
		super.init(callbacks: callbacks)
	}
	
	public override func _load() async throws -> [Document] {
		var docs: [Document] = []
		
		let asset: AVAsset = AVAsset(url: video)
		let duration = CMTimeGetSeconds(asset.duration)
		let numOfSegments = Int(ceil(duration / Double(VideoLoader.SEG_SIZE)))
		
		let eventLoopGroup = ThreadManager.thread
		let httpClient = HTTPClient(eventLoopGroupProvider: .shared(eventLoopGroup))
		
		let env = LC.loadEnv()
		
		guard let apiKey = env["OPENAI_API_KEY"] else {
			print("Please set OpenAI API key.")
			return []
		}
		
		let baseUrl = env["OPENAI_API_BASE"] ?? "api.openai.com"
		let configuration = Configuration(apiKey: apiKey, api: API(scheme: .https, host: baseUrl))
		let openAIClient = OpenAIKit.Client(httpClient: httpClient, configuration: configuration)
		
		defer {
			httpClient.shutdown { error in
				if let error = error {
					print("Error shutting down HTTP client: \(error)")
				}
			}
		}
		
		for index in 0..<numOfSegments {
			if let audioUrl = try await extractAudioFromVideoSegment(asset: asset, segment: index) {
				do {
					let audioData = try Data(contentsOf: audioUrl)
					let completion = try await openAIClient.audio.transcribe(file: audioData, fileName: "\(fileName)_\(index).m4a", mimeType: .m4a)
					let doc = Document(page_content: completion.text, metadata: [
						"fileName": "\(fileName)_\(index)",
						"mimeType": "m4a",
						"segmentStart": String(index * VideoLoader.SEG_SIZE),
						"segmentEnd": String(min((index + 1) * VideoLoader.SEG_SIZE, Int(duration)))
					])
					docs.append(doc)
				} catch {
					print("Unable to load data: \(error)")
					throw AgentkitError.LoaderError("Unable to load data: \(error)")
				}
			} else {
				throw AgentkitError.LoaderError("Failed to extract audio from video segment")
			}
		}
		
		return docs
	}
	
	func extractAudioFromVideoSegment(asset: AVAsset, segment: Int) async throws -> URL? {
		let composition = AVMutableComposition()
		guard let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
			return nil
		}
		
		let startTime = CMTimeMake(value: Int64(VideoLoader.SEG_SIZE * segment), timescale: 1)
		let endTime = CMTimeMake(value: Int64(VideoLoader.SEG_SIZE * (segment + 1)), timescale: 1)
		let timeRange = CMTimeRangeFromTimeToTime(start: startTime, end: endTime)
		
		do {
			let assetAudioTrack = try await asset.loadTracks(withMediaType: .audio).first
			try audioTrack.insertTimeRange(timeRange, of: assetAudioTrack!, at: .zero)
		} catch {
			print("Error extracting audio: \(error)")
			return nil
		}
		
		let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)!
		exporter.outputFileType = .m4a
		exporter.outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(segment)-\(UUID().uuidString).m4a")
		
		return try await withCheckedThrowingContinuation { continuation in
			exporter.exportAsynchronously {
				switch exporter.status {
				case .completed:
					continuation.resume(returning: exporter.outputURL)
				case .failed, .cancelled:
					continuation.resume(throwing: AgentkitError.LoaderError("Export failed: \(exporter.error?.localizedDescription ?? "Unknown error")"))
				default:
					continuation.resume(throwing: AgentkitError.LoaderError("Unexpected export status"))
				}
			}
		}
	}
	
	override func type() -> String {
		"Video"
	}
}
#endif
