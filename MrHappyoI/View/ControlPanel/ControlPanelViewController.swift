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
import Eventitic

class ControlPanelViewController: UIViewController {
    var player: ScenarioPlayer!
    var isOutsideTapEnabled: Bool = true {
        didSet {
            if let tgr = tapGestureRecognizer {
                tgr.isEnabled = isOutsideTapEnabled
            }
        }
    }

    private let listenerStore = ListenerStore()
    
    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet var swipeDownRecognizer: UISwipeGestureRecognizer!
    @IBOutlet weak var pauseOrResumeButton: UIButton!
    @IBOutlet weak var speakButton0: ControlPanelSpeakButton!
    @IBOutlet weak var speakButton1: ControlPanelSpeakButton!
    @IBOutlet weak var speakButton2: ControlPanelSpeakButton!
    @IBOutlet weak var speakButton3: ControlPanelSpeakButton!
    
    public static func instantiateFromStoryboard() -> ControlPanelViewController {
        let storyboard = UIStoryboard(name: "ControlPanel", bundle: nil)
        let controlPanelViewController = storyboard.instantiateInitialViewController() as! ControlPanelViewController
        return controlPanelViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tapGestureRecognizer.delegate = self
        tapGestureRecognizer.isEnabled = isOutsideTapEnabled
        
        swipeDownRecognizer.delegate = self
        swipeDownRecognizer.isEnabled = isOutsideTapEnabled
        
        let speakButtons = [speakButton0!, speakButton1!, speakButton2!, speakButton3!]
        let presetsCount = player.scenario.presets?.count ?? 0
        for (index, button) in speakButtons.enumerated() {
            if index < presetsCount {
                button.setTitle(player.scenario.presets![index].text, for: .normal)
            } else {
                button.setTitle("", for: .normal)
            }
        }
        
        updatePauseOrResumeButtonImage()
        updateSpeakButtons()
        player.playingStateChangeEvent
            .listen({ [weak self] _ in self?.playingStateChanged() })
            .addToStore(listenerStore)
    }

    private func playingStateChanged() {
        updatePauseOrResumeButtonImage()
        updateSpeakButtons()
    }
    
    private func updatePauseOrResumeButtonImage() {
        let image: UIImage
        switch player.playingState {
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
    
    private func updateSpeakButtons() {
        let isEnabled: Bool
        switch player.playingState {
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
        
        let presetsCount = player.scenario.presets?.count ?? 0
        let speakButtons = [speakButton0!, speakButton1!, speakButton2!, speakButton3!]
        for (index, button) in speakButtons.enumerated() {
            button.isEnabled = isEnabled && (index < presetsCount)
        }
    }
    
    @IBAction func outsideTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func swipedTowardDown(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func finishPlaying() {
        dismiss(animated: false) {
            self.player.stop()
        }
    }
    
    @IBAction func pauseOrResume(_ sender: Any) {
        if player.isPausing {
            player.resume()
        } else {
            player.pause()
        }
    }
    
    @IBAction func speakButtonTapped(_ sender: Any) {
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
}

extension ControlPanelViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (gestureRecognizer == tapGestureRecognizer) {
            return touch.view == gestureRecognizer.view
        } else if (gestureRecognizer == swipeDownRecognizer) {
            return !(touch.view is UIButton)
        } else {
            return false
        }
    }
}
