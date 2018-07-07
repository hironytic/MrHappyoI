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

class ControlPanelViewController: UIViewController {
    var player: ScenarioPlayer!
    var isOutsideTapEnabled: Bool = true {
        didSet {
            if let tgr = tapGestureRecognizer {
                tgr.isEnabled = isOutsideTapEnabled
            }
        }
    }

    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!
    
    public static func instantiateFromStoryboard() -> ControlPanelViewController {
        let storyboard = UIStoryboard(name: "ControlPanel", bundle: nil)
        let controlPanelViewController = storyboard.instantiateInitialViewController() as! ControlPanelViewController
        return controlPanelViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tapGestureRecognizer.delegate = self
        tapGestureRecognizer.isEnabled = isOutsideTapEnabled
    }

    @IBAction func outsideTapped() {
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
}

extension ControlPanelViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == gestureRecognizer.view
    }
}
