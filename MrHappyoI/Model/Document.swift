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

public enum DocumentError: LocalizedError {
    case invalidContent
    case invalidScenario(Error)
    case unzipError
    case notEnoughContent
    case zipError
    
    public var errorDescription: String? {
        switch self {
        case .invalidContent:
            return R.String.documentErrorInvalidContent.localized()
        case .invalidScenario(_):
            return R.String.documentErrorInvalidScenario.localized()
        case .unzipError:
            return R.String.documentErrorUnzip.localized()
        case .notEnoughContent:
            return R.String.documentErrorNotEnoughContent.localized()
        case .zipError:
            return R.String.documentErrorZip.localized()
        }
    }
}

public class Document: UIDocument {
    public var slidePDFData = DefaultValue.slidePDFData
    public var scenario = DefaultValue.scenario
    
    private struct DefaultValue {
        public static let slidePDFData = R.RawData.defaultSlide.data()
        public static let scenario = Scenario(actions: [],
                                              presets: [],
                                              language: "ja-JP",
                                              rate: AVSpeechUtteranceDefaultSpeechRate,
                                              pitch: 1.0,
                                              volume: 1.0,
                                              preDelay: 0.0,
                                              postDelay: 0.0)
    }

    public var errorHandler: ((/* error: */ Error, /* completionHandler: */ @escaping (/* isRecovered: */ Bool) -> Void) -> Void)? = nil
    
    private var rootFileWrapper: FileWrapper?
    
    private struct FileName {
        public static let slidePDF = "slide.pdf"
        public static let scenario = "scenario.json"
    }

    public override func contents(forType typeName: String) throws -> Any {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let tempData = tempURL.appendingPathComponent("contents")
        defer { _ = try? FileManager.default.removeItem(at: tempData) }

        do {
            guard let zipHandle = zipOpen64(tempData.path, APPEND_STATUS_CREATE) else { throw DocumentError.zipError }
            defer { zipClose(zipHandle, nil) }
            
            // slidePDF
            try append(to: zipHandle, data: slidePDFData, fileName: FileName.slidePDF)
            
            // scenario
            let encoder = JSONEncoder()
            encoder.outputFormatting = []
            let scenarioData = try! encoder.encode(scenario)
            try append(to: zipHandle, data: scenarioData, fileName: FileName.scenario)
        }
        
        return try Data(contentsOf: tempData)
    }
    
    private func append(to zipHandle: zipFile, data: Data, fileName: String) throws {
        let currentDate = Date()
        let dc = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: currentDate)
        

        var zipFileInfo = zip_fileinfo(tmz_date: tm_zip(tm_sec: UInt32(dc.second!),
                                                        tm_min: UInt32(dc.minute!),
                                                        tm_hour: UInt32(dc.hour!),
                                                        tm_mday: UInt32(dc.day!),
                                                        tm_mon: UInt32(dc.month!) - 1,
                                                        tm_year: UInt32(dc.year!)),
                                       dosDate: 0, internal_fa: 0, external_fa: 0)
        
        let result = zipOpenNewFileInZip3(zipHandle,
                                        fileName,
                                        &zipFileInfo,
                                        nil, 0, nil, 0, nil,
                                        Z_DEFLATED, Z_BEST_COMPRESSION, 0,
                                        -MAX_WBITS, DEF_MEM_LEVEL, Z_DEFAULT_STRATEGY,
                                        nil, 0);
        guard result == ZIP_OK else { throw DocumentError.zipError }
        defer { zipCloseFileInZip(zipHandle) }

        let wroteSize = data.withUnsafeBytes { (body: UnsafeRawBufferPointer) -> Int32 in
            return zipWriteInFileInZip(zipHandle, body.baseAddress!, UInt32(body.count))
        }
        guard wroteSize >= 0 else { throw DocumentError.zipError }
    }

    public override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let contents = contents as? Data else { throw DocumentError.invalidContent }
        
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let tempData = tempURL.appendingPathComponent("contents")
        defer { _ = try? FileManager.default.removeItem(at: tempData) }
        try contents.write(to: tempData)
        
        guard let zipHandle = unzOpen64(tempData.path) else { throw DocumentError.invalidContent }
        defer { unzClose(zipHandle) }
        
        var loadState = LoadState()
        guard unzGoToFirstFile(zipHandle) == UNZ_OK else { throw DocumentError.unzipError }
        while true {
            var fileInfo = unz_file_info64()
            guard unzGetCurrentFileInfo64(zipHandle, &fileInfo, nil, 0, nil, 0, nil, 0) == UNZ_OK else { throw DocumentError.unzipError }
            let fileNameSize = fileInfo.size_filename + 1
            let fileName: String
            do {
                var fileNameBuffer = UnsafeMutablePointer<CChar>.allocate(capacity: Int(fileNameSize))
                defer { fileNameBuffer.deallocate() }
                guard unzGetCurrentFileInfo64(zipHandle, &fileInfo, fileNameBuffer, fileNameSize, nil, 0, nil, 0) == UNZ_OK else { throw DocumentError.unzipError }
                fileNameBuffer[Int(fileNameSize - 1)] = 0
                fileName = String(cString: fileNameBuffer)
            }
            
            do {
                guard unzOpenCurrentFile(zipHandle) == UNZ_OK else { throw DocumentError.unzipError }
                defer { unzCloseCurrentFile(zipHandle) }
                
                let dataBuffer = UnsafeMutableRawPointer.allocate(byteCount: Int(fileInfo.uncompressed_size), alignment: 1)
                defer { dataBuffer.deallocate() }
                
                let readSize = unzReadCurrentFile(zipHandle, dataBuffer, UInt32(fileInfo.uncompressed_size))
                guard readSize >= 0 else { throw DocumentError.unzipError }
                
                let data = Data(bytesNoCopy: dataBuffer, count: Int(readSize), deallocator: .none)
                try load(data: data, fileName: fileName, state: &loadState)
            }
            
            let result = unzGoToNextFile(zipHandle)
            if result == UNZ_END_OF_LIST_OF_FILE {
                break
            }
            guard result == UNZ_OK else { throw DocumentError.unzipError }
        }
        
        guard loadState.isAllLoaded() else { throw DocumentError.notEnoughContent }
    }
    
    private struct LoadState {
        public var isSlidePDFLoaded: Bool = false
        public var isScenarioLoaded: Bool = false
        
        public func isAllLoaded() -> Bool {
            return isSlidePDFLoaded && isScenarioLoaded
        }
    }
    
    private func load(data: Data, fileName: String, state: inout LoadState) throws {
        switch fileName {
        case FileName.slidePDF:
            slidePDFData = Data(data)
            state.isSlidePDFLoaded = true
            
        case FileName.scenario:
            scenario = try JSONDecoder().decode(Scenario.self, from: data)
            state.isScenarioLoaded = true
            
        default:
            break
        }
    }
    
    public override func handleError(_ error: Error, userInteractionPermitted: Bool) {
        Log.warn("Document error: \(String(describing: error))")
        guard userInteractionPermitted else { super.handleError(error, userInteractionPermitted: userInteractionPermitted); return }
        guard let handler = errorHandler else { super.handleError(error, userInteractionPermitted: userInteractionPermitted); return }
        handler(error, { isRecovered in
            self.finishedHandlingError(error, recovered: isRecovered)
        })
    }
}
