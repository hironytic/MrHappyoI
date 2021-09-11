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
import AVFoundation
import Combine

public class ScenarioPlayer {
    public let scenario: Scenario
    private let _currentActionIndexSubject: CurrentValueSubject<Int, Never>
    public var currentActionIndex: Int {
        get {
            return _currentActionIndexSubject.value
        }
    }
    public var currentActionPublisher: AnyPublisher<Int, Never> {
        _currentActionIndexSubject.eraseToAnyPublisher()
    }

    private let _rateMultiplierSubject = CurrentValueSubject<Double, Never>(1.0)
    public var rateMultiplier: Double {
        get {
            return _rateMultiplierSubject.value
        }
        set {
            _rateMultiplierSubject.value = newValue
        }
    }
    public var rateMultiplierPublisher: AnyPublisher<Double, Never> {
        return _rateMultiplierSubject.eraseToAnyPublisher()
    }

    public weak var delegate: ScenarioPlayerDelegate?
    public private(set) var isRunning: Bool = false
    public private(set) var isPausing: Bool = false
    private var waitingWorkItem: DispatchWorkItem?
    private var currentPageNumber: Int = 0
    
    public enum PlayingState {
        case playing
        case pausing
        case paused
        case stopped
        case speakingPreset
    }
    private let _playingStateSubject = CurrentValueSubject<PlayingState, Never>(.stopped)
    public var playingState: PlayingState { _playingStateSubject.value }
    public var playingStatePublisher: AnyPublisher<PlayingState, Never> {
        return _playingStateSubject.eraseToAnyPublisher()
    }

    public init(scenario: Scenario, currentActionIndex: Int) {
        self.scenario = scenario
        _currentActionIndexSubject = CurrentValueSubject<Int, Never>(currentActionIndex)
    }
    
    private func detectPageNumber(at actionIndex: Int) -> Int {
        guard actionIndex >= 1 else { return 0 }
        
        for ix in (0..<actionIndex).reversed() {
            if case .changeSlidePage(let params) = scenario.actions[ix] {
                switch params.page {
                case .previous:
                    let pageNumber = detectPageNumber(at: ix - 1) - 1
                    return (pageNumber >= 0) ? pageNumber : 0
                case .next:
                    let pageNumber = detectPageNumber(at: ix - 1) + 1
                    return pageNumber
                case .to(let pageNumber):
                    return pageNumber
                }
            }
        }
        
        return 0
    }
    
    public func start() {
        assert(Thread.isMainThread, "Call this method on main thread")
        
        guard !isRunning else { return }
        
        isRunning = true
        isPausing = false
        _playingStateSubject.value = .playing
        
        // When starting from somewhere other than head of the scenario,
        // first navigate slide to appropriate page.
        if _currentActionIndexSubject.value >= 0 {
            currentPageNumber = detectPageNumber(at: _currentActionIndexSubject.value)
            _currentActionIndexSubject.value -= 1
        } else {
            currentPageNumber = 0
        }
        
        switch scenario.actions[_currentActionIndexSubject.value + 1] {
        case .changeSlidePage(_):
            enqueueNextAction()
        default:
            let params = AskToChangeSlidePageParameters(page: currentPageNumber)
            delegate?.scenarioPlayer(self, askToChangeSlidePage: params, completion: enqueueNextAction)
        }
    }
    
    public func stop() {
        assert(Thread.isMainThread, "Call this method on main thread")

        guard isRunning else { return }
        
        isRunning = false
        isPausing = false
        waitingWorkItem?.cancel()
        waitingWorkItem = nil
        _playingStateSubject.value = .stopped
        delegate?.scenarioPlayerFinishPlaying(self)
    }
    
    public func pause() {
        assert(Thread.isMainThread, "Call this method on main thread")
        
        guard isRunning && !isPausing else { return }

        isPausing = true
        if _playingStateSubject.value == .playing {
            _playingStateSubject.value = .pausing
        }
    }
    
    public func resume() {
        assert(Thread.isMainThread, "Call this method on main thread")
        
        guard isRunning && isPausing else { return }
        guard _playingStateSubject.value != .speakingPreset else { return }
        
        isPausing = false
        let prevState = _playingStateSubject.value
        _playingStateSubject.value = .playing
        if prevState == .paused {
            enqueueNextAction()
        }
    }
    
    public func speakPreset(at index: Int) {
        assert(Thread.isMainThread, "Call this method on main thread")

        guard _playingStateSubject.value == .paused else { return }
        guard let delegate = delegate else { return }

        _playingStateSubject.value = .speakingPreset
        
        let preset = scenario.presets[index]
        let askParams = makeAskToSpeakParameters(preset)
        delegate.scenarioPlayer(self, askToSpeak: askParams, completion: {
            if self._playingStateSubject.value == .speakingPreset {
                self._playingStateSubject.value = .paused
            }
        })
    }
    
    private func makeAskToSpeakParameters(_ speakParams: SpeakParameters) -> AskToSpeakParameters {
        let preDelay = (speakParams.preDelay ?? scenario.preDelay) / rateMultiplier
        let rate = min(max(Float(Double(speakParams.rate ?? scenario.rate) * rateMultiplier), AVSpeechUtteranceMinimumSpeechRate), AVSpeechUtteranceMaximumSpeechRate)
        return AskToSpeakParameters(text: speakParams.text,
                                    language: speakParams.language ?? scenario.language,
                                    rate: rate,
                                    pitch: speakParams.pitch ?? scenario.pitch,
                                    volume: speakParams.volume ?? scenario.volume,
                                    preDelay: preDelay)
    }
    
    private func enqueueNextAction() {
        DispatchQueue.main.async { [weak self] in self?.performNextAction() }
    }

    private func enqueueNextActionAfter(seconds: Double) {
        let workItem = DispatchWorkItem { [weak self] in
            guard let me = self else { return }
            me.waitingWorkItem = nil
            me.performNextAction()
        }
        waitingWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: workItem)
    }

    private func performNextAction() {
        if isRunning && isPausing && _playingStateSubject.value == .pausing {
            _playingStateSubject.value = .paused
        }

        guard isRunning && !isPausing else { return }
        guard let delegate = delegate else { return }
        
        if _currentActionIndexSubject.value < scenario.actions.count - 1 {
            _currentActionIndexSubject.value += 1
            let action = scenario.actions[_currentActionIndexSubject.value]
            switch action {
            case .speak(let params):
                let postDelay = (params.postDelay ?? scenario.postDelay) / rateMultiplier
                let enqueueProc = (postDelay <= 0.0) ? enqueueNextAction : {
                    self.enqueueNextActionAfter(seconds: postDelay)
                }
                let askParams = makeAskToSpeakParameters(params)
                delegate.scenarioPlayer(self, askToSpeak: askParams, completion: enqueueProc)
            
            case .changeSlidePage(let params):
                switch params.page {
                case .previous:
                    if currentPageNumber > 0 { currentPageNumber -= 1}
                case .next:
                    currentPageNumber += 1
                case .to(let pageNumber):
                    currentPageNumber = pageNumber
                }
                let askParams = AskToChangeSlidePageParameters(page: currentPageNumber)
                delegate.scenarioPlayer(self, askToChangeSlidePage: askParams, completion: enqueueNextAction)
                
            case .pause:
                pause()
                _playingStateSubject.value = .paused
            
            case .wait(let params):
                enqueueNextActionAfter(seconds: params.seconds / rateMultiplier)
            }
        } else {
            stop()
        }
    }
}

public protocol ScenarioPlayerDelegate: AnyObject {
    func scenarioPlayer(_ player: ScenarioPlayer, askToSpeak: AskToSpeakParameters, completion: @escaping () -> Void)
    func scenarioPlayer(_ player: ScenarioPlayer, askToChangeSlidePage: AskToChangeSlidePageParameters, completion: @escaping () -> Void)
    func scenarioPlayerFinishPlaying(_ player: ScenarioPlayer)
}

public struct AskToSpeakParameters {
    public let text: String
    public let language: String
    public let rate: Float
    public let pitch: Float // 0.5 - 2
    public let volume: Float // 0 - 1
    public let preDelay: TimeInterval
}

public struct AskToChangeSlidePageParameters {
    public let page: Int
}
