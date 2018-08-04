//
// WaitActionViewController.swift
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

public class WaitActionViewController: UITableViewController {
    public var params: WaitParameters!
    public var paramsChangedHandler: (WaitParameters) -> Void = { _ in }
    private var notifyWorkItem: DispatchWorkItem?

    @IBOutlet private weak var secondsSlider: UISlider!
    @IBOutlet private weak var secondsLabel: UILabel!
    
    public static func instantiateFromStoryboard() -> WaitActionViewController {
        let storyboard = UIStoryboard(name: "WaitAction", bundle: nil)
        let navController = storyboard.instantiateInitialViewController() as! UINavigationController
        return navController.topViewController as! WaitActionViewController
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        secondsSlider.minimumValue = 0.0
        secondsSlider.maximumValue = 10.0
        secondsSlider.value = Float(params.seconds)
        secondsLabel.text = "\(params.seconds)"
    }
    
    @IBAction private func sliderValueChanged(_ sender: Any) {
        params.seconds = Double(secondsSlider.value)
        secondsLabel.text = "\(params.seconds)"
        notifyParamsChanged()
    }
    
    private func notifyParamsChanged() {
        if let workItem = notifyWorkItem {
            workItem.cancel()
        }
        let workItem = DispatchWorkItem {
            self.notifyWorkItem = nil
            self.paramsChangedHandler(self.params)
        }
        notifyWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
}
