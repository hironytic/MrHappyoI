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

@MainActor
class PlayerViewController: UIViewController {
    @IBOutlet private weak var slideView: PDFView!
    
    var slide: PDFDocument!
    var player: ScenarioPlayer!
    var finishProc: () -> Void = {}

    private let speechSynthesizer = AVSpeechSynthesizer()
    private var askToSpeakContinuation: CheckedContinuation<Void, Never>?
    
    static func instantiateFromStoryboard() -> PlayerViewController {
        let storyboard = UIStoryboard(name: "Player", bundle: nil)
        let playerViewController = storyboard.instantiateInitialViewController() as! PlayerViewController
        return playerViewController
    }
    
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
        AppDelegate.shared.scenarioPlayer = player
        Task {
            await player.resetRateMultiplier()
            player.start(delegate: self)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return .bottom
    }
    
    @IBAction private func showControlPanel() {
        let controlPanelViewController = ControlPanelViewController.instantiateFromStoryboard()
        controlPanelViewController.player = player
        controlPanelViewController.isOutsideTapEnabled = true
        present(controlPanelViewController, animated: true, completion: nil)
    }
    
    private func finishPlaying() {
        askToSpeakContinuation = nil
        player.stop()
        speechSynthesizer.stopSpeaking(at: .immediate)
        AppDelegate.shared.scenarioPlayer = nil
        UIApplication.shared.isIdleTimerDisabled = false
        finishProc()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func slideDidTap() {
        Task {
            await player.resume()
        }
    }
}

extension PlayerViewController: ScenarioPlayerDelegate {
    func scenarioPlayer(_ player: ScenarioPlayer, askToSpeak params: AskToSpeakParameters) async {
        let utterance = AVSpeechUtterance(string: params.text)
        utterance.voice = AVSpeechSynthesisVoice(language: params.language)
        utterance.pitchMultiplier = params.pitch
        utterance.rate = params.rate
        utterance.volume = params.volume
        utterance.preUtteranceDelay = params.preDelay
        
        return await withCheckedContinuation { continuation in
            askToSpeakContinuation = continuation
            speechSynthesizer.speak(utterance)
        }
    }
    
    func scenarioPlayer(_ player: ScenarioPlayer, askToChangeSlidePage params: AskToChangeSlidePageParameters) async {
        guard params.page < slide.pageCount else { return }
        
        if let pdfPage = slide.page(at: params.page) {
            slideView.go(to: pdfPage)
            slideView.scaleFactor = slideView.scaleFactorForSizeToFit
        }
    }
    
    func scenarioPlayerFinishPlaying(_ player: ScenarioPlayer) async {
        finishPlaying()
    }
}

extension PlayerViewController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if let continuation = askToSpeakContinuation {
            askToSpeakContinuation = nil
            continuation.resume()
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        if let continuation = askToSpeakContinuation {
            askToSpeakContinuation = nil
            continuation.resume()
        }
    }
}
