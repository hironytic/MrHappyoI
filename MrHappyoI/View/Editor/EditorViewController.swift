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

class EditorViewController: UIViewController {
    
    @IBOutlet weak var slideView: PDFView!
    
    var document: Document?
    var slide: PDFDocument?
    var player: ScenarioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        slideView.usePageViewController(true)
        slideView.displayMode = .singlePageContinuous
        slideView.displayDirection = .horizontal
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.slideView.scaleFactor = self.slideView.scaleFactorForSizeToFit
    }
    
    func setDocument(_ document: Document, completion: @escaping (Bool) -> Void) {
        document.open { isSucceeded in
            if isSucceeded {
                self.document = document
                self.loadViewIfNeeded()
                
                if let slidePDFData = document.slidePDFData {
                    if let slidePDFDocument = PDFDocument(data: slidePDFData) {
                        self.slide = slidePDFDocument
                        
                        self.slideView.document = slidePDFDocument
                        self.slideView.autoScales = true
                        self.slideView.minScaleFactor = 0.001
                    }
                }

                do {
                    if let scenario = try document.loadScenario() {
                        self.player = ScenarioPlayer(scenario: scenario)
                    }
                } catch {
                    // TODO: show error message
                }
            }
            completion(isSucceeded)
        }
    }
    
    @IBAction func finishEditing() {
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
    
    @IBAction func play() {
        if let slide = slide, let player = player {
            let storyBoard = UIStoryboard(name: "Player", bundle: nil)
            let playerViewController = storyBoard.instantiateInitialViewController() as! PlayerViewController
            playerViewController.slide = slide
            playerViewController.player = player
            player.currentActionIndex = -1
            present(playerViewController, animated: true, completion: nil)
        }
    }
}
