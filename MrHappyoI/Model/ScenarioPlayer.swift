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
    private(set) var isPausing: Bool = false
    private var waitingWorkItem: DispatchWorkItem?
    
    public enum PlayingState {
        case playing
        case pausing
        case paused
        case stopped
        case speakingPreset
    }
    var playingState = PlayingState.stopped {
        didSet {
            playingStateChangeEvent.fire(playingState)
        }
    }
    var playingStateChangeEvent = EventSource<PlayingState>()

    init(scenario: Scenario) {
        self.scenario = scenario
        _currentActionIndex = -1
    }
    
    func start() {
        assert(Thread.isMainThread, "Call this method on main thread")
        
        guard !isRunning else { return }
        
        isRunning = true
        isPausing = false
        playingState = .playing
        
        // When starting from somewhere other than head of the scenario,
        // first change slide to appropriate page.
        if _currentActionIndex >= 0 {
            _currentActionIndex -= 1
            switch scenario.actions[_currentActionIndex + 1] {
            case .changeSlidePage(_):
                break
            default:
                for ix in (0 ..< _currentActionIndex + 1).reversed() {
                    if case .changeSlidePage(let params) = scenario.actions[ix] {
                        delegate?.scenarioPlayer(self, askToChangeSlidePage: params, completion: enqueueNextAction)
                        return
                    }
                }
            }
        }
        
        enqueueNextAction()
    }
    
    func stop() {
        assert(Thread.isMainThread, "Call this method on main thread")

        guard isRunning else { return }
        
        isRunning = false
        isPausing = false
        waitingWorkItem?.cancel()
        waitingWorkItem = nil
        playingState = .stopped
        delegate?.scenarioPlayerFinishPlaying(self)
    }
    
    func pause() {
        assert(Thread.isMainThread, "Call this method on main thread")
        
        guard isRunning && !isPausing else { return }

        isPausing = true
        if playingState == .playing {
            playingState = .pausing
        }
    }
    
    func resume() {
        assert(Thread.isMainThread, "Call this method on main thread")
        
        guard isRunning && isPausing else { return }
        guard playingState != .speakingPreset else { return }
        
        isPausing = false
        let prevState = playingState
        playingState = .playing
        if prevState == .paused {
            enqueueNextAction()
        }
    }
    
    func speakPreset(at index: Int) {
        assert(Thread.isMainThread, "Call this method on main thread")

        guard playingState == .paused else { return }
        guard let presets = scenario.presets else { return }
        guard let delegate = delegate else { return }

        playingState = .speakingPreset
        
        let preset = presets[index]
        let askParams = AskToSpeakParameters(text: preset.text,
                                             language: preset.language ?? scenario.language,
                                             rate: preset.rate ?? scenario.rate,
                                             pitch: preset.pitch ?? scenario.pitch,
                                             volume: preset.volume ?? scenario.volume)
        delegate.scenarioPlayer(self, askToSpeak: askParams, completion: {
            if self.playingState == .speakingPreset {
                self.playingState = .paused
            }
        })
    }
    
    private func enqueueNextAction() {
        DispatchQueue.main.async { [weak self] in self?.performNextAction() }
    }
    
    private func performNextAction() {
        if isRunning && isPausing && playingState == .pausing {
            playingState = .paused
        }

        guard isRunning && !isPausing else { return }
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
                
            case .pause:
                pause()
                playingState = .paused
            
            case .wait(let params):
                let workItem = DispatchWorkItem { [weak self] in
                    guard let me = self else { return }
                    me.waitingWorkItem = nil
                    me.enqueueNextAction()
                }
                waitingWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + params.seconds, execute: workItem)
            }
        } else {
            stop()
        }
    }
}

protocol ScenarioPlayerDelegate: class {
    func scenarioPlayer(_ player: ScenarioPlayer, askToSpeak: AskToSpeakParameters, completion: @escaping () -> Void)
    func scenarioPlayer(_ player: ScenarioPlayer, askToChangeSlidePage: ChangeSlidePageParameters, completion: @escaping () -> Void)
    func scenarioPlayerFinishPlaying(_ player: ScenarioPlayer)
}

struct AskToSpeakParameters {
    let text: String
    let language: String
    let rate: Float
    let pitch: Float // 0.5 - 2
    let volume: Float // 0 - 1
}
