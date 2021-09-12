//
// ControlPanelViewController.swift
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
import Combine

public class ControlPanelViewController: UIViewController {
    public var player: ScenarioPlayer!
    public var isOutsideTapEnabled: Bool = true {
        didSet {
            if let tgr = tapGestureRecognizer {
                tgr.isEnabled = isOutsideTapEnabled
            }
        }
    }

    private var cancellables = Set<AnyCancellable>()
    
    @IBOutlet private var tapGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet private var swipeDownRecognizer: UISwipeGestureRecognizer!
    @IBOutlet private weak var pauseOrResumeButton: UIButton!
    @IBOutlet private weak var speakButton0: ControlPanelSpeakButton!
    @IBOutlet private weak var speakButton1: ControlPanelSpeakButton!
    @IBOutlet private weak var speakButton2: ControlPanelSpeakButton!
    @IBOutlet private weak var speakButton3: ControlPanelSpeakButton!
    @IBOutlet private weak var speedRatioLabel: UILabel!
    
    public static func instantiateFromStoryboard() -> ControlPanelViewController {
        let storyboard = UIStoryboard(name: "ControlPanel", bundle: nil)
        let controlPanelViewController = storyboard.instantiateInitialViewController() as! ControlPanelViewController
        return controlPanelViewController
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        tapGestureRecognizer.delegate = self
        tapGestureRecognizer.isEnabled = isOutsideTapEnabled
        
        swipeDownRecognizer.delegate = self
        swipeDownRecognizer.isEnabled = isOutsideTapEnabled
        
        let speakButtons = [speakButton0!, speakButton1!, speakButton2!, speakButton3!]
        let presetsCount = player.scenario.presets.count
        for (index, button) in speakButtons.enumerated() {
            if index < presetsCount {
                button.setTitle(player.scenario.presets[index].text, for: .normal)
            } else {
                button.setTitle("", for: .normal)
            }
        }
        
        player.playingStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in self?.playingStatusChanged(status) }
            .store(in: &cancellables)
        updateSpeed()
        player.rateMultiplierPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateSpeed() }
            .store(in: &cancellables)
    }

    private func playingStatusChanged(_ status: ScenarioPlayer.PlayingStatus) {
        updatePauseOrResumeButtonImage(for: status)
        updateSpeakButtons(for: status)
    }
    
    private func updatePauseOrResumeButtonImage(for status: ScenarioPlayer.PlayingStatus) {
        let image: UIImage
        switch status {
        case .playing:
            image = R.Image.cpPause.image()
        case .pausing:
            image = R.Image.cpPausing.image()
        case .paused:
            image = R.Image.cpResume.image()
        case .stopped:
            return
        case .speakingPreset:
            return
        }
        pauseOrResumeButton.setImage(image, for: .normal)
    }
    
    private func updateSpeakButtons(for status: ScenarioPlayer.PlayingStatus) {
        let isEnabled: Bool
        switch status {
        case .playing:
            isEnabled = false
        case .pausing:
            isEnabled = false
        case .paused:
            isEnabled = true
        case .stopped:
            isEnabled = false
        case .speakingPreset:
            isEnabled = false
        }
        
        let presetsCount = player.scenario.presets.count
        let speakButtons = [speakButton0!, speakButton1!, speakButton2!, speakButton3!]
        for (index, button) in speakButtons.enumerated() {
            button.isEnabled = isEnabled && (index < presetsCount)
        }
    }
    
    private func updateSpeed() {
        let rateMultiplier = player.rateMultiplier
        let speedRatio = Int(round(rateMultiplier * 100.0 / 5.0)) * 5
        speedRatioLabel.text = R.StringFormat.controlPanelSpeedText.localized(speedRatio)
    }
    
    @IBAction private func outsideTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func swipedTowardDown(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func finishPlaying() {
        dismiss(animated: false) {
            self.player.stop()
        }
    }
    
    @IBAction private func pauseOrResume(_ sender: Any) {
        let status = player.playingStatus
        if status == .pausing || status == .paused {
            player.resume()
        } else {
            player.pause()
        }
    }
    
    @IBAction private func speakButtonTapped(_ sender: Any) {
        switch sender as! ControlPanelSpeakButton {
        case speakButton0:
            player.speakPreset(at: 0)
        case speakButton1:
            player.speakPreset(at: 1)
        case speakButton2:
            player.speakPreset(at: 2)
        case speakButton3:
            player.speakPreset(at: 3)
        default:
            break
        }
    }
    
    @IBAction private func speedDownButtonTapped(_ sender: Any) {
        let rateMultiplier = player.rateMultiplier
        let level = Int(round(rateMultiplier * 100.0 / 5.0))
        let newLevel = level - 1
        if newLevel >= 1 {
            let newRate = Double(newLevel) * 5.0 / 100.0
            player.rateMultiplier = newRate
        }
    }
    
    @IBAction func speedUpButtonTapped(_ sender: Any) {
        let rateMultiplier = player.rateMultiplier
        let level = Int(round(rateMultiplier * 100.0 / 5.0))
        let newLevel = level + 1
        if newLevel <= 40 {
            let newRate = Double(newLevel) * 5.0 / 100.0
            player.rateMultiplier = newRate
        }
    }
}

extension ControlPanelViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (gestureRecognizer == tapGestureRecognizer) {
            return touch.view == gestureRecognizer.view
        } else if (gestureRecognizer == swipeDownRecognizer) {
            return !(touch.view is UIButton)
        } else {
            return false
        }
    }
}
