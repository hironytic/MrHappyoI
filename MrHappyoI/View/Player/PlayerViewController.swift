//
// PlayerViewController.swift
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
import AVFoundation

class PlayerViewController: UIViewController {
    @IBOutlet weak var slideView: PDFView!
    
    var slide: PDFDocument!
    var player: ScenarioPlayer!

    private let speechSynthesizer = AVSpeechSynthesizer()
    private var askToSpeakCompletion: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        slideView.displayMode = .singlePage
        slideView.displayDirection = .horizontal
        slideView.displaysPageBreaks = false
        
        speechSynthesizer.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.slideView.document = slide
        slideView.autoScales = true
        slideView.minScaleFactor = 0.001
        
        UIApplication.shared.isIdleTimerDisabled = true
        player.delegate = self
        player.start()
    }
    
    @IBAction func finishPlaying() {
        player.stop()
        player.delegate = nil
        speechSynthesizer.stopSpeaking(at: .immediate)
        UIApplication.shared.isIdleTimerDisabled = false
        dismiss(animated: true, completion: nil)
    }
}

extension PlayerViewController: ScenarioPlayerDelegate {
    func scenarioPlayer(_ player: ScenarioPlayer, askToSpeak params: SpeakParameters, completion: @escaping () -> Void) {
        let utterance = AVSpeechUtterance(string: params.text)
        utterance.voice = AVSpeechSynthesisVoice(language: params.language ?? player.scenario.language)
        utterance.pitchMultiplier = params.pitch ?? player.scenario.pitch
        utterance.rate = params.rate ?? player.scenario.rate
        utterance.volume = params.volume ?? player.scenario.volume
        
        askToSpeakCompletion = completion
        speechSynthesizer.speak(utterance)
    }
    
    func scenarioPlayer(_ player: ScenarioPlayer, askToChangeSlidePage params: ChangeSlidePageParameters, completion: @escaping () -> Void) {
        guard params.page < slide.pageCount else { completion(); return }
        
        if let pdfPage = slide.page(at: params.page) {
            slideView.go(to: pdfPage)
            slideView.scaleFactor = slideView.scaleFactorForSizeToFit
        }
        completion()
    }
    
    func scenarioPlayerWaitForTap(_ player: ScenarioPlayer, completion: @escaping () -> Void) {
        // TODO
        completion()
    }
    
    func scenarioPlayerFinishPlaying(_ player: ScenarioPlayer) {
        finishPlaying()
    }
}

extension PlayerViewController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        askToSpeakCompletion?()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        askToSpeakCompletion?()
    }
}
