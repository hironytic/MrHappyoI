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
import AVFoundation

/*
  Sample scenario.json:
    {
      "language": "en-US",
      "rate": 1.25,
      "pitch": 0.8,
      "volume": 1,
      "presets": [
        {
          "text": "I'm ready.",
          "pitch": 1.0
        },
        {
          "text": "Thank you!"
        }
      ]
      "actions": [
        {
          "type": "changeSlidePage",
          "page": 0
        },
        {
          "type": "pause"
        },
        {
          "type": "speak",
          "text": "Let me start talking.",
          "rate": 1.5
        }
      ]
    }
*/

public enum ScenarioAction: Codable {
    case speak(SpeakParameters)
    case changeSlidePage(ChangeSlidePageParameters)
    case pause
    case wait(WaitParameters)
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    public enum CodingError: Error {
        case unknownType(String)
    }
    
    private struct TypeValue {
        static let speak = "speak"
        static let changeSlidePage = "changeSlidePage"
        static let pause = "pause"
        static let wait = "wait"
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        let type = try values.decode(String.self, forKey: .type)
        switch type {
        case TypeValue.speak:
            let params = try SpeakParameters(from: decoder)
            self = .speak(params)
            
        case TypeValue.changeSlidePage:
            let params = try ChangeSlidePageParameters(from: decoder)
            self = .changeSlidePage(params)
            
        case TypeValue.pause:
            self = .pause
        
        case TypeValue.wait:
            let params = try WaitParameters(from: decoder)
            self = .wait(params)
            
        default:
            throw CodingError.unknownType(type)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .speak(let params):
            try container.encode(TypeValue.speak, forKey: .type)
            try params.encode(to: encoder)
            
        case .changeSlidePage(let params):
            try container.encode(TypeValue.changeSlidePage, forKey: .type)
            try params.encode(to: encoder)
            
        case .pause:
            try container.encode(TypeValue.pause, forKey: .type)
            
        case .wait(let params):
            try container.encode(TypeValue.wait, forKey: .type)
            try params.encode(to: encoder)
        }
    }
}

public struct SpeakParameters: Codable {
    public let text: String
    public let language: String?
    public let rate: Float?
    public let pitch: Float? // 0.5 - 2
    public let volume: Float? // 0 - 1
    public let preDelay: Double?
    public let postDelay: Double?
}

public struct ChangeSlidePageParameters: Codable {
    public let page: Page

    public enum Page {
        case previous
        case next
        case to(Int)
    }

    public enum CodingError: Error {
        case unknownPageValue(String)
    }

    private enum CodingKeys: String, CodingKey {
        case page
    }

    private struct PageValue {
        static let previous = "previous"
        static let next = "next"
    }
    
    public init(page: Page) {
        self.page = page
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        if let pageString = try? values.decode(String.self, forKey: .page) {
            switch pageString {
            case PageValue.previous:
                page = .previous
            case PageValue.next:
                page = .next
            default:
                throw CodingError.unknownPageValue(pageString)
            }
        } else {
            let pageNumber = try values.decode(Int.self, forKey: .page)
            page = .to(pageNumber)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch page {
        case .previous:
            try container.encode(PageValue.previous, forKey: .page)
        case .next:
            try container.encode(PageValue.next, forKey: .page)
        case .to(let pageNumber):
            try container.encode(pageNumber, forKey: .page)
        }
    }
}

public struct WaitParameters: Codable {
    public let seconds: Double
}

public struct Scenario: Codable {
    public let actions: [ScenarioAction]
    public let presets: [SpeakParameters]
    public let language: String
    public let rate: Float
    public let pitch: Float
    public let volume: Float
    public let preDelay: Double
    public let postDelay: Double
    
    public init(actions: [ScenarioAction], presets: [SpeakParameters], language: String, rate: Float, pitch: Float, volume: Float, preDelay: Double, postDelay: Double) {
        self.actions = actions
        self.presets = presets
        self.language = language
        self.rate = rate
        self.pitch = pitch
        self.volume = volume
        self.preDelay = preDelay
        self.postDelay = postDelay
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        actions = try values.decode([ScenarioAction].self, forKey: .actions)
        presets = try values.decodeIfPresent([SpeakParameters].self, forKey: .presets) ?? []
        language = try values.decodeIfPresent(String.self, forKey: .language) ?? "ja-JP"
        rate = try values.decodeIfPresent(Float.self, forKey: .rate) ?? AVSpeechUtteranceDefaultSpeechRate
        pitch = try values.decodeIfPresent(Float.self, forKey: .pitch) ?? 1.0
        volume = try values.decodeIfPresent(Float.self, forKey: .volume) ?? 1.0
        preDelay = try values.decodeIfPresent(Double.self, forKey: .preDelay) ?? 0.0
        postDelay = try values.decodeIfPresent(Double.self, forKey: .postDelay) ?? 0.0
    }
}
