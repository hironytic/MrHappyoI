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

enum DocumentError: Error {
    case invalidContent
}

class Document: UIDocument {
    public var slidePDFData: Data? {
        didSet {
            if let slidePDFFileWrapper = rootFileWrapper?.fileWrappers?[FileName.slidePDF] {
                rootFileWrapper!.removeFileWrapper(slidePDFFileWrapper)
            }
        }
    }
    
    public var scenarioData: Data? {
        didSet {
            if let scenarioFileWrapper = rootFileWrapper?.fileWrappers?[FileName.scenario] {
                rootFileWrapper!.removeFileWrapper(scenarioFileWrapper)
            }
        }
    }
    
    private var rootFileWrapper: FileWrapper?
    
    private class FileName {
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
            if let slidePDFData = slidePDFData {
                let slidePDFFileWrapper = FileWrapper(regularFileWithContents: slidePDFData)
                slidePDFFileWrapper.preferredFilename = FileName.slidePDF
                rfw.addFileWrapper(slidePDFFileWrapper)
            }
        }
        
        if fileWrappers?[FileName.scenario] == nil {
            if let scenarioData = scenarioData {
                let scenarioFileWrapper = FileWrapper(regularFileWithContents: scenarioData)
                scenarioFileWrapper.preferredFilename = FileName.scenario
                rfw.addFileWrapper(scenarioFileWrapper)
            }
        }
        
        return rfw
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let fileWrapperContents = contents as? FileWrapper else { throw DocumentError.invalidContent }
        
        rootFileWrapper = fileWrapperContents
        let rfw = fileWrapperContents

        let fileWrappers = rfw.fileWrappers;

        if let slidePDFFileWrapper = fileWrappers?[FileName.slidePDF] {
            slidePDFData = slidePDFFileWrapper.regularFileContents
        } else {
            slidePDFData = nil
        }
        
        if let scenarioFileWrapper = fileWrappers?[FileName.scenario] {
            scenarioData = scenarioFileWrapper.regularFileContents
        } else {
            scenarioData = nil
        }
    }
}

extension Document {
    func loadScenario() throws -> Scenario? {
        guard let scenarioData = scenarioData else { return nil }
        return try JSONDecoder().decode(Scenario.self, from: scenarioData)
    }
}
