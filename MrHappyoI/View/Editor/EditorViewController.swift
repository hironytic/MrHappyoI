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

class EditorViewController: UITabBarController, UIDocumentPickerDelegate {
    private var document: Document?
    private var slide: PDFDocument?
    private var player: ScenarioPlayer?
    private var exportTempURL: URL?
    
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
            
        }))
        ac.addAction(UIAlertAction(title: R.String.importScenario.localized(), style: .default, handler: { [weak self] _ in
            
        }))
        ac.addAction(UIAlertAction(title: R.String.cancel.localized(), style: .cancel, handler: { _ in }))
        ac.modalPresentationStyle = .popover
        ac.popoverPresentationController?.barButtonItem = (sender as! UIBarButtonItem)
        present(ac, animated: true, completion: nil)
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
            export(data: data, name: "slide.pdf", barButtonItem: barButtonItem)
        }
    }
    
    private func exportScenario(barButtonItem: UIBarButtonItem) {
        if let scenario = document?.scenario {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let scenarioData = try! encoder.encode(scenario)
            export(data: scenarioData, name: "scenario.json", barButtonItem: barButtonItem)
        }
    }
    
    private func export(data: Data, name: String, barButtonItem: UIBarButtonItem) {
        // write to temporary file
        do {
            let tempDirURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            let fileURL = tempDirURL.appendingPathComponent(name)
            try data.write(to: fileURL, options: .atomic)
            
            exportTempURL = fileURL
            let dpvc = UIDocumentPickerViewController(url: fileURL, in: .exportToService)
            dpvc.modalPresentationStyle = .formSheet
            dpvc.delegate = self
            present(dpvc, animated: true, completion: nil)
        } catch let error {
            // TODO
            print("\(error)")
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        removeExportTempFile()
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        removeExportTempFile()
    }
    
    func removeExportTempFile() {
        if let url = exportTempURL {
            exportTempURL = nil
            do {
                try FileManager.default.removeItem(at: url)
            } catch let error {
                // TODO
                print("\(error)")
            }
        }
    }
}
