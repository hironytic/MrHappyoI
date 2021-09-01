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
import UniformTypeIdentifiers

public class EditorViewController: UITabBarController {
    private var document: Document?
    private var slide: PDFDocument?
    private var player: ScenarioPlayer?
    
    private var documentPickerDelegate: UIDocumentPickerDelegate?
    
    public static func instantiateFromStoryboard() -> (UINavigationController, EditorViewController) {
        let storyboard = UIStoryboard(name: "Editor", bundle: nil)
        let navViewController = storyboard.instantiateInitialViewController() as! UINavigationController
        let editorViewController = navViewController.topViewController as! EditorViewController
        return (navViewController, editorViewController)
    }
    
    public var slideViewController: EditorSlideViewController {
        return viewControllers![0] as! EditorSlideViewController
    }
    
    public var scenarioViewController: EditorScenarioViewController {
        return viewControllers![1] as! EditorScenarioViewController
    }
    
    public func setDocument(_ document: Document, completion: @escaping (Bool) -> Void) {
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
            let playerViewController = PlayerViewController.instantiateFromStoryboard()
            playerViewController.slide = slide
            playerViewController.player = player
            player.currentActionIndex = scenarioViewController.currentActionIndex

            if !UserDefaults.standard.bool(forKey: R.Setting.noExternalDisplaySupport.rawValue) && ExternalDisplayCoordinator.instance.hasAnyDisplay {
                let controlPanelViewController = ControlPanelViewController.instantiateFromStoryboard()
                controlPanelViewController.player = player
                controlPanelViewController.isOutsideTapEnabled = false

                playerViewController.finishProc = {
                    ExternalDisplayCoordinator.instance.playerViewController = nil
                    controlPanelViewController.dismiss(animated: true)
                }
                ExternalDisplayCoordinator.instance.playerViewController = playerViewController
                present(controlPanelViewController, animated: true, completion: nil)
            } else {
                playerViewController.finishProc = {
                    playerViewController.dismiss(animated: true)
                }
                playerViewController.modalPresentationStyle = .fullScreen
                present(playerViewController, animated: true)
            }
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
        Importer.doImport(owner: self, contentTypes: [UTType.pdf], barButtonItem: barButtonItem) { [weak self] data in
            guard let me = self else { return }
            guard let document = me.document else { return }
            
            if let slidePDFDocument = PDFDocument(data: data) {
                if !slidePDFDocument.isEncrypted {
                    document.slidePDFData = data
                    document.updateChangeCount(.done)
                    
                    me.slide = slidePDFDocument
                    me.slideViewController.setSlide(slidePDFDocument)
                } else {
                    let alert = UIAlertController(title: R.String.errorImport.localized(),
                                                  message: R.String.errorImportEncryptedSlide.localized(),
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: R.String.ok.localized(), style: .default))
                    me.present(alert, animated: true)
                }
            } else {
                let alert = UIAlertController(title: R.String.errorImport.localized(),
                                              message: R.String.errorImportSlide.localized(),
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: R.String.ok.localized(), style: .default))
                me.present(alert, animated: true)
            }
        }
    }
    
    private func importScenario(barButtonItem: UIBarButtonItem) {
        Importer.doImport(owner: self, contentTypes: [UTType.json], barButtonItem: barButtonItem) { [weak self] data in
            guard let me = self else { return }
            guard let document = me.document else { return }
            
            do {
                let scenario = try JSONDecoder().decode(Scenario.self, from: data)
                document.scenario = scenario
                document.updateChangeCount(.done)

                let player = ScenarioPlayer(scenario: document.scenario)
                me.player = player
                me.scenarioViewController.setPlayer(player)
            } catch let error {
                Log.error("Error in decoding scenario: [%@]", String(describing: error))
                
                let alert = UIAlertController(title: R.String.errorImport.localized(),
                                              message: R.String.errorImportScenario.localized(),
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: R.String.ok.localized(), style: .default))
                me.present(alert, animated: true)
            }
        }
    }
    
    private class Importer: NSObject, UIDocumentPickerDelegate {
        private weak var owner: EditorViewController?
        private var importProc: ((Data) -> Void)?
        
        public static func doImport(owner: EditorViewController, contentTypes: [UTType], barButtonItem: UIBarButtonItem, importProc: @escaping (Data) -> Void) {
            let importer = Importer()

            importer.owner = owner
            owner.documentPickerDelegate = importer
            
            importer.importProc = importProc
            
            let dpvc = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes, asCopy: true)
            dpvc.delegate = importer
            owner.present(dpvc, animated: true, completion: nil)
        }

        public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let delegate = owner?.documentPickerDelegate as? Importer, delegate == self {
                owner?.documentPickerDelegate = nil
            }
            
            if let url = urls.first {
                let data: Data
                do {
                    data = try Data(contentsOf: url)
                } catch let error {
                    Log.error("Error in loading picked document: [%@]", String(describing: error))
                    
                    let alert = UIAlertController(title: R.String.errorImport.localized(),
                                                  message: "",
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: R.String.ok.localized(), style: .default))
                    owner?.present(alert, animated: true)
                    return
                }
                importProc?(data)
            }
        }
        
        public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
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
                Log.error("Error in writing temporary file: [%@]", String(describing: error))
                
                let alert = UIAlertController(title: R.String.errorExport.localized(),
                                              message: "",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: R.String.ok.localized(), style: .default))
                owner.present(alert, animated: true)
                return
            }
            
            if let fileURL = exporter.fileURL {
                exporter.owner = owner
                owner.documentPickerDelegate = exporter
                
                let dpvc = UIDocumentPickerViewController(forExporting: [fileURL], asCopy: true)
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
                    Log.warn("Error in removing temporary file: [%@]", String(describing: error))
                }
            }
        }
        
        public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            pickerEnded()
        }
        
        public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            pickerEnded()
        }
    }
}
