//
// Scenario.swift
// MrHappyoI
//
// Copyright (c) 2018 Hironori Ichimiya <hiron@hironytic.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import Foundation

/*
  Sample scenario.json:
    {
      "language": "en-US",
      "rate": 1.25,
      "pitch": 0.8,
      "volume": 1,
      "actions": [
        {
          "type": "changeSlidePage",
          "page": 0
        },
        {
          "type": "waitForTap"
        },
        {
          "type": "speak",
          "text": "Let me start talking.",
          "rate": 1.5
        }
      ]
    }
*/

enum ScenarioAction: Codable {
    case speak(SpeakParameters)
    case changeSlidePage(ChangeSlidePageParameters)
    case waitForTap
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    enum CodingError: Error {
        case unknownType(String)
    }
    
    private class TypeValue {
        static let speak = "speak"
        static let changeSlidePage = "changeSlidePage"
        static let waitForTap = "waitForTap"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        let type = try values.decode(String.self, forKey: .type)
        switch type {
        case TypeValue.speak:
            let params = try SpeakParameters(from: decoder)
            self = .speak(params)
            
        case TypeValue.changeSlidePage:
            let params = try ChangeSlidePageParameters(from: decoder)
            self = .changeSlidePage(params)
            
        case TypeValue.waitForTap:
            self = .waitForTap
            
        default:
            throw CodingError.unknownType(type)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .speak(let params):
            try container.encode(TypeValue.speak, forKey: .type)
            try params.encode(to: encoder)
            
        case .changeSlidePage(let params):
            try container.encode(TypeValue.changeSlidePage, forKey: .type)
            try params.encode(to: encoder)
            
        case .waitForTap:
            try container.encode(TypeValue.waitForTap, forKey: .type)
        }
    }
}

struct SpeakParameters: Codable {
    let text: String
    let language: String?
    let rate: Float?
    let pitch: Float? // 0.5 - 2
    let volume: Float? // 0 - 1
}

struct ChangeSlidePageParameters: Codable {
    let page: Int
}

struct Scenario: Codable {
    let actions: [ScenarioAction]
    let language: String
    let rate: Float
    let pitch: Float
    let volume: Float
}
