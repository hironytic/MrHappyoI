//
// DocumentViewController.swift
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
import PDFKit
import MobileCoreServices

class EditorViewController: UITabBarController {
    private var document: Document?
    private var slide: PDFDocument?
    private var player: ScenarioPlayer?
    
    private var documentPickerDelegate: UIDocumentPickerDelegate?
    
    var slideViewController: EditorSlideViewController {
        return viewControllers![0] as! EditorSlideViewController
    }
    
    var scenarioViewController: EditorScenarioViewController {
        return viewControllers![1] as! EditorScenarioViewController
    }
    
    func setDocument(_ document: Document, completion: @escaping (Bool) -> Void) {
        document.open { isSucceeded in
            if isSucceeded {
                self.document = document
                self.loadViewIfNeeded()
                
                if let slidePDFDocument = PDFDocument(data: document.slidePDFData) {
                    self.slide = slidePDFDocument
                    self.slideViewController.setSlide(slidePDFDocument)
                }

                let player = ScenarioPlayer(scenario: document.scenario)
                self.player = player
                self.scenarioViewController.setPlayer(player)
            }
            completion(isSucceeded)
        }
    }
    
    @IBAction private func finishEditing() {
        if let doc = document {
            doc.close { isSucceeded in
                if isSucceeded {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction private func play() {
        if let slide = slide, let player = player {
            let storyBoard = UIStoryboard(name: "Player", bundle: nil)
            let playerViewController = storyBoard.instantiateInitialViewController() as! PlayerViewController
            playerViewController.slide = slide
            playerViewController.player = player
            player.currentActionIndex = -1
            present(playerViewController, animated: true, completion: nil)
        }
    }
    
    @IBAction private func importData(_ sender: Any) {
        let ac = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: R.String.importSlide.localized(), style: .default, handler: { [weak self] _ in
            self?.importSlide(barButtonItem: (sender as! UIBarButtonItem))
        }))
        ac.addAction(UIAlertAction(title: R.String.importScenario.localized(), style: .default, handler: { [weak self] _ in
            self?.importScenario(barButtonItem: (sender as! UIBarButtonItem))
        }))
        ac.addAction(UIAlertAction(title: R.String.cancel.localized(), style: .cancel, handler: { _ in }))
        ac.modalPresentationStyle = .popover
        ac.popoverPresentationController?.barButtonItem = (sender as! UIBarButtonItem)
        present(ac, animated: true, completion: nil)
    }
    
    private func importSlide(barButtonItem: UIBarButtonItem) {
        Importer.doImport(owner: self, documentTypes: [String(kUTTypeData)], barButtonItem: barButtonItem) { data in
            if let document = self.document {
                if let slidePDFDocument = PDFDocument(data: data) {
                    document.slidePDFData = data
                    document.updateChangeCount(.done)
                    
                    self.slide = slidePDFDocument
                    self.slideViewController.setSlide(slidePDFDocument)
                } else {
                    // TODO: show error
                }

            }
            
        }
    }
    
    private func importScenario(barButtonItem: UIBarButtonItem) {
        
    }
    
    private class Importer: NSObject, UIDocumentPickerDelegate {
        private weak var owner: EditorViewController?
        private var importProc: ((Data) -> Void)?
        
        public static func doImport(owner: EditorViewController, documentTypes: [String], barButtonItem: UIBarButtonItem, importProc: @escaping (Data) -> Void) {
            let importer = Importer()

            importer.owner = owner
            owner.documentPickerDelegate = importer
            
            importer.importProc = importProc
            
            let dpvc = UIDocumentPickerViewController(documentTypes: documentTypes, in: .import)
            dpvc.modalPresentationStyle = .formSheet
            dpvc.delegate = importer
            owner.present(dpvc, animated: true, completion: nil)
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let delegate = owner?.documentPickerDelegate as? Importer, delegate == self {
                owner?.documentPickerDelegate = nil
            }
            
            if let url = urls.first {
                let data: Data
                do {
                    data = try Data(contentsOf: url)
                } catch let error {
                    // TODO
                    print("\(error)")
                    return
                }
                importProc?(data)
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            if let delegate = owner?.documentPickerDelegate as? Importer, delegate == self {
                owner?.documentPickerDelegate = nil
            }
        }
    }
    
    @IBAction private func exportData(_ sender: Any) {
        let ac = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: R.String.exportSlide.localized(), style: .default, handler: { [weak self] _ in
            self?.exportSlide(barButtonItem: (sender as! UIBarButtonItem))
        }))
        ac.addAction(UIAlertAction(title: R.String.exportScenario.localized(), style: .default, handler: { [weak self] _ in
            self?.exportScenario(barButtonItem: (sender as! UIBarButtonItem))
        }))
        ac.addAction(UIAlertAction(title: R.String.cancel.localized(), style: .cancel, handler: { _ in }))
        ac.modalPresentationStyle = .popover
        ac.popoverPresentationController?.barButtonItem = (sender as! UIBarButtonItem)
        present(ac, animated: true, completion: nil)
    }
    
    private func exportSlide(barButtonItem: UIBarButtonItem) {
        if let data = document?.slidePDFData {
            Exporter.doExport(owner: self, data: data, name: "slide.pdf", barButtonItem: barButtonItem)
        }
    }
    
    private func exportScenario(barButtonItem: UIBarButtonItem) {
        if let scenario = document?.scenario {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let scenarioData = try! encoder.encode(scenario)
            Exporter.doExport(owner: self, data: scenarioData, name: "scenario.json", barButtonItem: barButtonItem)
        }
    }

    private class Exporter: NSObject, UIDocumentPickerDelegate {
        private weak var owner: EditorViewController?
        private var fileURL: URL?
        
        public static func doExport(owner: EditorViewController, data: Data, name: String, barButtonItem: UIBarButtonItem) {
            let exporter = Exporter()
            
            do {
                let tempDirURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                let tempFileURL = tempDirURL.appendingPathComponent(name)
                try data.write(to: tempFileURL, options: .atomic)
                exporter.fileURL = tempFileURL
            } catch let error {
                // TODO
                print("\(error)")
            }
            
            if let fileURL = exporter.fileURL {
                exporter.owner = owner
                owner.documentPickerDelegate = exporter
                
                let dpvc = UIDocumentPickerViewController(url: fileURL, in: .exportToService)
                dpvc.modalPresentationStyle = .formSheet
                dpvc.delegate = exporter
                owner.present(dpvc, animated: true, completion: nil)
            }
        }
        
        private func pickerEnded() {
            if let delegate = owner?.documentPickerDelegate as? Exporter, delegate == self {
                owner?.documentPickerDelegate = nil
            }
            
            if let fileURL = fileURL {
                do {
                    try FileManager.default.removeItem(at: fileURL)
                } catch let error {
                    // TODO
                    print("\(error)")
                }
            }
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            pickerEnded()
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            pickerEnded()
        }
    }
}
