//
//  ImageOCRLoader.swift
//  ImageOCRLoader
//
//  Created by Simon Weniger on 21/09/2024.
//

import Foundation
import Vision
import UIKit

public class VisionOCRLoader: BaseLoader {
	let image: UIImage
	
	public init(image: UIImage, callbacks: [BaseCallbackHandler] = []) {
		self.image = image
		super.init(callbacks: callbacks)
	}
	
	public override func _load() async throws -> [Document] {
		let request = VNRecognizeTextRequest()
		request.recognitionLevel = .accurate
		
		guard let cgImage = image.cgImage else {
			throw AgentkitError.LoaderError("Failed to get CGImage from UIImage")
		}
		
		let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
		try handler.perform([request])
		
		guard let observations = request.results else {
			return []
		}
		
		let recognizedStrings = observations.compactMap { observation in
			observation.topCandidates(1).first?.string
		}
		
		let text = recognizedStrings.joined(separator: " ")
		return [Document(page_content: text, metadata: [:])]
	}
	
	override func type() -> String {
		"VisionOCR"
	}
}
