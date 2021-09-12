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

public actor ScenarioPlayer {
    public let scenario: Scenario

    private let _currentActionIndexSubject: CurrentValueSubject<Int, Never>
    public nonisolated var currentActionIndex: Int {
        get {
            return _currentActionIndexSubject.value
        }
    }
    public nonisolated var currentActionPublisher: AnyPublisher<Int, Never> {
        return _currentActionIndexSubject.eraseToAnyPublisher()
    }

    private let _rateMultiplierSubject = CurrentValueSubject<Double, Never>(1.0)
    public nonisolated var rateMultiplier: Double {
        get {
            return _rateMultiplierSubject.value
        }
        set {
            _rateMultiplierSubject.value = newValue
        }
    }
    public nonisolated var rateMultiplierPublisher: AnyPublisher<Double, Never> {
        return _rateMultiplierSubject.eraseToAnyPublisher()
    }

    public private(set) weak var delegate: ScenarioPlayerDelegate?
    private var currentPageNumber: Int = 0

    public enum PlayingStatus: Equatable {
        case playing
        case pausing
        case paused
        case stopped
        case speakingPreset(Int)
    }
    private let _playingStatusSubject = CurrentValueSubject<PlayingStatus, Never>(.stopped)
    public nonisolated var playingStatus: PlayingStatus { _playingStatusSubject.value }
    public nonisolated var playingStatusPublisher: AnyPublisher<PlayingStatus, Never> {
        return _playingStatusSubject.eraseToAnyPublisher()
    }
    private func changeStatus(_ status: PlayingStatus) {
        _playingStatusSubject.value = status
        _statusChangeWaiter?.resume()
    }
    private var _statusChangeWaiter: CheckedContinuation<Void, Error>?
    
    @MainActor private var task: Task<Void, Error>?

    public init(scenario: Scenario, currentActionIndex: Int) {
        self.scenario = scenario
        self._currentActionIndexSubject = CurrentValueSubject(currentActionIndex)
    }
    
    @MainActor
    public func start(delegate: ScenarioPlayerDelegate) {
        guard task == nil else { return }
        let clearTask = { [weak self] in self?.task = nil }
        
        task = Task {
            defer {
                Task {
                    await MainActor.run {
                        clearTask()
                    }
                }
            }
            
            try await run(with: delegate)
        }
    }
    
    @MainActor
    public func stop() {
        guard let task = task else { return }
        task.cancel()
    }
    
    @MainActor
    public func pause() {
        Task {
            try await requestToPause()
        }
    }
    
    @MainActor
    public func resume() {
        Task {
            try await requestToResume()
        }
    }
    
    @MainActor
    public func speakPreset(at index: Int) {
        Task {
            try await requestToSpeakPreset(at: index)
        }
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

    private func run(with delegate: ScenarioPlayerDelegate) async throws {
        self.delegate = delegate
        changeStatus(.playing)
        defer {
            Task { await delegate.scenarioPlayerFinishPlaying(self) }
            changeStatus(.stopped)
        }

        // When starting from somewhere other than head of the scenario,
        // first navigate slide to appropriate page.
        if _currentActionIndexSubject.value >= 0 {
            currentPageNumber = detectPageNumber(at: _currentActionIndexSubject.value)
            _currentActionIndexSubject.value -= 1
        } else {
            currentPageNumber = 0
        }
        
        let params = AskToChangeSlidePageParameters(page: currentPageNumber)
        await delegate.scenarioPlayer(self, askToChangeSlidePage: params)
        
        var isStopped = false
        while !isStopped {
            try Task.checkCancellation()
            
            switch playingStatus {
            case .playing:
                try await playNextAction()
                
            case .pausing:
                changeStatus(.paused)

            case .paused:
                defer { _statusChangeWaiter = nil }
                try await withTaskCancellationHandler(operation: {
                    try await withCheckedThrowingContinuation { continuation in
                        _statusChangeWaiter = continuation
                    }
                }, onCancel: {
                    Task {
                        await _statusChangeWaiter?.resume()
                    }
                })

            case .speakingPreset(let index):
                let preset = scenario.presets[index]
                let askParams = makeAskToSpeakParameters(preset)
                await delegate.scenarioPlayer(self, askToSpeak: askParams)
                if (playingStatus == .speakingPreset(index)) {
                    changeStatus(.paused)
                }

            case .stopped:
                isStopped = true
            }
        }
    }

    private func requestToPause() async throws {
        guard playingStatus == .playing else { return }
        changeStatus(.pausing)
    }
    
    private func requestToResume() async throws {
        guard playingStatus == .pausing || playingStatus == .paused else { return }
        changeStatus(.playing)
    }
    
    private func requestToSpeakPreset(at index: Int) async throws {
        guard playingStatus == .paused else { return }
        changeStatus(.speakingPreset(index))
    }
    
    private func playNextAction() async throws {
        guard let delegate = delegate else { return }
        
        if _currentActionIndexSubject.value < scenario.actions.count - 1 {
            _currentActionIndexSubject.value += 1
            let action = scenario.actions[_currentActionIndexSubject.value]
            switch action {
            case .speak(let params):
                let askParams = makeAskToSpeakParameters(params)
                await delegate.scenarioPlayer(self, askToSpeak: askParams)
                let postDelay = (params.postDelay ?? scenario.postDelay) / rateMultiplier
                if postDelay > 0.0 {
                    try await Task.sleep(seconds: postDelay)
                }
                
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
                await delegate.scenarioPlayer(self, askToChangeSlidePage: askParams)
                
            case .pause:
                changeStatus(.paused)
            
            case .wait(let params):
                try await Task.sleep(seconds: params.seconds / rateMultiplier)
            }
        } else {
            changeStatus(.stopped)
        }
    }
}

public protocol ScenarioPlayerDelegate: AnyObject {
    func scenarioPlayer(_ player: ScenarioPlayer, askToSpeak: AskToSpeakParameters) async
    func scenarioPlayer(_ player: ScenarioPlayer, askToChangeSlidePage: AskToChangeSlidePageParameters) async
    func scenarioPlayerFinishPlaying(_ player: ScenarioPlayer) async
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

extension Task where Success == Never, Failure == Never {
    /// Suspends the current task for _at least_ the given duration
    /// in seconds, unless the task is cancelled. If the task is cancelled,
    /// throws \c CancellationError without waiting for the duration.
    ///
    /// This function does _not_ block the underlying thread.
    public static func sleep(seconds duration: Double) async throws {
        try await self.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
    }
}
