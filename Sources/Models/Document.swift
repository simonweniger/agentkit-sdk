//
// Document.swift
//
//  Created by Simon Weniger on 09.07.23.
//

import Foundation



public struct Document {

    public var type: String
    public var url: String?
	public var description: String?
	public var content: String
    public var name: String
    public var authorization: Any?
    public var metadata: Any?
    public var fromPage: Int?
    public var toPage: Int?
    public var splitter: Splitter?

	public init(type: String, url: String? = nil, name: String, description: String, content: String, authorization: Any? = nil, metadata: Any? = nil, fromPage: Int? = nil, toPage: Int? = nil, splitter: Splitter? = nil) {
        self.type = type
        self.url = url
		self.description = description
		self.content = content
        self.name = name
        self.authorization = authorization
        self.metadata = metadata
        self.fromPage = fromPage
        self.toPage = toPage
        self.splitter = splitter
    }

    public enum CodingKeys: String, CodingKey { 
        case type
        case url
        case name
		case description
		case content
        case authorization
        case metadata
        case fromPage = "from_page"
        case toPage = "to_page"
        case splitter
    }
	
	public struct Splitter: Codable {
			public var type: String
			public var chunkSize: Int
			public var chunkOverlap: Int

			public init(type: String, chunkSize: Int, chunkOverlap: Int) {
				self.type = type
				self.chunkSize = chunkSize
				self.chunkOverlap = chunkOverlap
			}
		public enum CodingKeys: String, CodingKey {
			case type
			case chunkSize = "chunk_size"
			case chunkOverlap = "chunk_overlap"
		}
		}
}
