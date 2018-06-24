//
// ScenarioPlayer.swift
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

import Foundation
import Eventitic

class ScenarioPlayer {
    let scenario: Scenario
    private var _currentActionIndex: Int
    var currentActionIndex: Int {
        get {
            return _currentActionIndex
        }
        set {
            if !isRunning {
                _currentActionIndex = newValue
            }
        }
    }
    weak var delegate: ScenarioPlayerDelegate?
    var currentActionChangeEvent = EventSource<Int>()
    private(set) var isRunning: Bool = false

    init(scenario: Scenario) {
        self.scenario = scenario
        _currentActionIndex = -1
    }
    
    func start() {
        assert(Thread.isMainThread, "Call this method on main thread")
        
        guard !isRunning else { return }
        
        isRunning = true
        enqueueNextAction()
    }
    
    func stop() {
        assert(Thread.isMainThread, "Call this method on main thread")

        guard isRunning else { return }
        
        isRunning = false
        delegate?.scenarioPlayerFinishPlaying(self)
    }
    
    private func enqueueNextAction() {
        DispatchQueue.main.async { [weak self] in self?.performNextAction() }
    }
    
    private func performNextAction() {
        guard isRunning else { return }
        guard let delegate = delegate else { return }
        
        if _currentActionIndex < scenario.actions.count - 1 {
            _currentActionIndex += 1
            currentActionChangeEvent.fire(_currentActionIndex)
            let action = scenario.actions[_currentActionIndex]
            switch action {
            case .speak(let params):
                let askParams = AskToSpeakParameters(text: params.text,
                                                     language: params.language ?? scenario.language,
                                                     rate: params.rate ?? scenario.rate,
                                                     pitch: params.pitch ?? scenario.pitch,
                                                     volume: params.volume ?? scenario.volume)
                delegate.scenarioPlayer(self, askToSpeak: askParams, completion: enqueueNextAction)
            
            case .changeSlidePage(let params):
                delegate.scenarioPlayer(self, askToChangeSlidePage: params, completion: enqueueNextAction)
                
            case .waitForTap:
                delegate.scenarioPlayerWaitForTap(self, completion: enqueueNextAction)
            }
        } else {
            stop()
        }
    }
}

protocol ScenarioPlayerDelegate: class {
    func scenarioPlayer(_ player: ScenarioPlayer, askToSpeak: AskToSpeakParameters, completion: @escaping () -> Void)
    func scenarioPlayer(_ player: ScenarioPlayer, askToChangeSlidePage: ChangeSlidePageParameters, completion: @escaping () -> Void)
    func scenarioPlayerWaitForTap(_ player: ScenarioPlayer, completion: @escaping () -> Void)
    func scenarioPlayerFinishPlaying(_ player: ScenarioPlayer)
}

struct AskToSpeakParameters {
    let text: String
    let language: String
    let rate: Float
    let pitch: Float // 0.5 - 2
    let volume: Float // 0 - 1
}
