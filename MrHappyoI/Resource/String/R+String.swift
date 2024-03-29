//
// R+String.swift
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

extension R {
    enum String: Swift.String {
        case ok = "MrHappyoI.ok"
        case cancel = "MrHappyoI.cancel"
        
        case newDocumentName = "MrHappyoI.new_document_name"
        
        case exportSlide = "MrHappyoI.export_slide"
        case exportScenario = "MrHappyoI.export_scenario"
        case errorExport = "MrHappyoI.error_export"
        case importSlide = "MrHappyoI.import_slide"
        case importScenario = "MrHappyoI.import_scenario"
        case errorImport = "MrHappyoI.error_import"
        case errorImportSlide = "MrHappyoI.error_import_slide"
        case errorImportEncryptedSlide = "MrHappyoI.error_import_encrypted_slide"
        case errorImportScenario = "MrHappyoI.error_import_scenario"
        case errorFailedToOpen = "MrHappyoI.error_failed_to_open"
        case documentErrorInvalidContent = "MyHappyoI.document_error_invalid_content"
        case documentErrorInvalidScenario = "MrHappyoI.document_error_invalid_scenario"
        case documentErrorUnzip = "MrHappyoI.document_error_unzip"
        case documentErrorNotEnoughContent = "MrHappyoI.document_error_not_enough_content"
        case documentErrorZip = "MrHappyoI.document_error_zip"
        
        case scenarioSectionSettings = "MrHappyoI.scenario_section_settings"
        case scenarioSectionPresets = "MrHappyoI.scenario_section_presets"
        case scenarioSectionActions = "MrHappyoI.scenario_section_actions"
        case scenarioParamLanguage = "MrHappyoI.scenario_param_language"
        case scenarioParamRate = "MrHappyoI.scenario_param_rate"
        case scenarioParamPitch = "MrHappyoI.scenario_param_pitch"
        case scenarioParamVolume = "MrHappyoI.scenario_param_volume"
        case scenarioChangeSlidePrevious = "MrHappyoI.scenario_change_slide_previous"
        case scenarioChangeSlideNext = "MrHappyoI.scenario_change_slide_next"
    }
    
    enum StringFormat: Swift.String {
        case scenarioChangeSlideTo = "MrHappyoI.format.scenario_change_slide_to"
        case waitForSeconds = "MrHappyoI.format.scenario.wait_for_seconds"
        case controlPanelSpeedText = "MrHappyoI.format.control_panel.speed_text"
    }
}

extension R.String {
    func localized() -> Swift.String {
        return NSLocalizedString(rawValue, comment: "")
    }
}

extension R.StringFormat {
    func localized(_ arguments: CVarArg...) -> Swift.String {
        return localized(arguments: arguments)
    }
    
    func localized(arguments: [CVarArg]) -> Swift.String {
        let formatString = NSLocalizedString(rawValue, comment: "")
        return Swift.String(format:formatString, arguments: arguments)
    }
}
