//
// Log.swift
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
import os

public struct Log {
    private init() {}

    public static func error(_ message: String) {
        outputLog("%@", logType: .error, args: [message])
    }

    public static func error(_ message: StaticString, _ args: CVarArg...) {
        outputLog(message, logType: .error, args: args)
    }
    
    public static func warn(_ message: String) {
        outputLog("%@", logType: .default, args: [message])
    }
    
    public static func warn(_ message: StaticString, _ args: CVarArg...) {
        outputLog(message, logType: .default, args: args)
    }
    
    public static func info(_ message: String) {
        outputLog("%@", logType: .info, args: [message])
    }
    
    public static func info(_ message: StaticString, _ args: CVarArg...) {
        outputLog(message, logType: .info, args: args)
    }
    
    public static func debug(_ message: String) {
        outputLog("%@", logType: .debug, args: [message])
    }
    
    public static func debug(_ message: StaticString, _ args: CVarArg...) {
        outputLog(message, logType: .debug, args: args)
    }

    private static let osLog = OSLog(subsystem: "com.hironytic.MrHappyoI", category: "MrHappyoI")
    
    private static func outputLog(_ message: StaticString, logType: OSLogType, args: [CVarArg]) {
        os_log(message, log: osLog, type: logType, args)
    }
}
