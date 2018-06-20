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

class EditorViewController: UITabBarController {
    private var document: Document?
    private var slide: PDFDocument?
    private var player: ScenarioPlayer?
    
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

                self.player = ScenarioPlayer(scenario: document.scenario)
                self.scenarioViewController.setScenario(document.scenario)
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
}
