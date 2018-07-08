//
// Document.swift
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

import UIKit
import AVKit

enum DocumentError: LocalizedError {
    case invalidContent
    case invalidScenario(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidContent:
            return R.String.documentErrorInvalidContent.localized()
        case .invalidScenario(_):
            return R.String.documentErrorInvalidScenario.localized()
        }
    }
}

class Document: UIDocument {
    private var _slidePDFData = DefaultValue.slidePDFData
    private var _scenario = DefaultValue.scenario
    
    private struct DefaultValue {
        public static let slidePDFData = R.RawData.defaultSlide.data()
        public static let scenario = Scenario(actions: [],
                                              language: "ja-JP",
                                              rate: AVSpeechUtteranceDefaultSpeechRate,
                                              pitch: 1.0,
                                              volume: 1.0)
    }

    public var slidePDFData: Data {
        get {
            return _slidePDFData
        }
        set {
            _slidePDFData = newValue
            if let slidePDFFileWrapper = rootFileWrapper?.fileWrappers?[FileName.slidePDF] {
                rootFileWrapper!.removeFileWrapper(slidePDFFileWrapper)
            }
        }
    }

    public var scenario: Scenario {
        get {
            return _scenario
        }
        set {
            _scenario = newValue
            if let scenarioFileWrapper = rootFileWrapper?.fileWrappers?[FileName.scenario] {
                rootFileWrapper!.removeFileWrapper(scenarioFileWrapper)
            }
        }
    }
    
    
    public var errorHandler: ((/* error: */ Error, /* completionHandler: */ @escaping (/* isRecovered: */ Bool) -> Void) -> Void)? = nil
    
    private var rootFileWrapper: FileWrapper?
    
    private struct FileName {
        public static let slidePDF = "slide.pdf"
        public static let scenario = "scenario.json"
    }
    
    override func contents(forType typeName: String) throws -> Any {
        if rootFileWrapper == nil {
            rootFileWrapper = FileWrapper(directoryWithFileWrappers: [:])
        }
        let rfw = rootFileWrapper!
        
        let fileWrappers = rfw.fileWrappers;

        if fileWrappers?[FileName.slidePDF] == nil {
            let slidePDFFileWrapper = FileWrapper(regularFileWithContents: slidePDFData)
            slidePDFFileWrapper.preferredFilename = FileName.slidePDF
            rfw.addFileWrapper(slidePDFFileWrapper)
        }
        
        if fileWrappers?[FileName.scenario] == nil {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let scenarioData = try! encoder.encode(scenario)
            let scenarioFileWrapper = FileWrapper(regularFileWithContents: scenarioData)
            scenarioFileWrapper.preferredFilename = FileName.scenario
            rfw.addFileWrapper(scenarioFileWrapper)
        }
        
        return rfw
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let fileWrapperContents = contents as? FileWrapper else { throw DocumentError.invalidContent }
        
        rootFileWrapper = fileWrapperContents
        let rfw = fileWrapperContents

        let fileWrappers = rfw.fileWrappers;

        _slidePDFData = {
            if let slidePDFFileWrapper = fileWrappers?[FileName.slidePDF] {
                if let data = slidePDFFileWrapper.regularFileContents {
                    return data
                }
            }
            return DefaultValue.slidePDFData
        }()

        _scenario = try {
            do {
                if let scenarioFileWrapper = fileWrappers?[FileName.scenario] {
                    if let scenarioData = scenarioFileWrapper.regularFileContents {
                        return try JSONDecoder().decode(Scenario.self, from: scenarioData)
                    }
                }
                return DefaultValue.scenario
            } catch (let innerError) {
                throw DocumentError.invalidScenario(innerError)
            }
        }()
    }
    
    override func handleError(_ error: Error, userInteractionPermitted: Bool) {
        Log.warn("Document error: \(String(describing: error))")
        guard userInteractionPermitted else { super.handleError(error, userInteractionPermitted: userInteractionPermitted); return }
        guard let handler = errorHandler else { super.handleError(error, userInteractionPermitted: userInteractionPermitted); return }
        handler(error, { isRecovered in
            self.finishedHandlingError(error, recovered: isRecovered)
        })
    }
}
