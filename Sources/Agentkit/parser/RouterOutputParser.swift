//
//  File.swift
//  
//
//  Created by Simon Weniger on 2024/8/7.
//

import Foundation
import SwiftyJSON

public struct RouterOutputParser: BaseOutputParser {
    let default_destination = "DEFAULT"
//    next_inputs_type: Type = str
//    let next_inputs_inner_key = "input"
    public init() {
        
    }
    public func parse(text: String) -> Parsed {
        // "```(json)?(.*)```"
        print("router text: \(text)")
        if let jsonText = findJSON(text: text) {
//            let expected_keys = ["destination", "next_inputs"]
            let json = JSON(jsonText.data(using: .utf8)!)
            return Parsed.dict(["destination": json["destination"].stringValue, "next_inputs": json["next_inputs"].stringValue])
        } else {
            return .error
        }
//        try:
//                   expected_keys = ["destination", "next_inputs"]
//                   parsed = parse_and_check_json_markdown(text, expected_keys)
//                   if not isinstance(parsed["destination"], str):
//                       raise ValueError("Expected 'destination' to be a string.")
//                   if not isinstance(parsed["next_inputs"], self.next_inputs_type):
//                       raise ValueError(
//                           f"Expected 'next_inputs' to be {self.next_inputs_type}."
//                       )
//                   parsed["next_inputs"] = {self.next_inputs_inner_key: parsed["next_inputs"]}
//                   if (
//                       parsed["destination"].strip().lower()
//                       == self.default_destination.lower()
//                   ):
//                       parsed["destination"] = None
//                   else:
//                       parsed["destination"] = parsed["destination"].strip()
//                   return parsed
//               except Exception as e:
//                   raise OutputParserException(
//                       f"Parsing text\n{text}\n raised following error:\n{e}"
//                   )
        
        
    }
    
    func findJSON(text: String) -> String? {
//        let pattern = "```(json)?(.*)```"
//
//        do {
////            print(text)
//            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
//            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
//            if matches.isEmpty {
//                return nil
//            } else {
//                return String(text[Range(matches.first!.range, in: text)!])
//            }
//        } catch {
//            print("Error: \(error.localizedDescription)")
//            return nil
//        }
        text
    }
}
