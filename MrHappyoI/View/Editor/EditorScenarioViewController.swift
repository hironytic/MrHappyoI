//
// EditorScenarioViewController.swift
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

class EditorScenarioViewController: UITableViewController {
    private var scenario: Scenario?
    private var player: ScenarioPlayer?
    private var cancellables = Set<AnyCancellable>()
    private(set) var currentActionIndex: Int = -1
    
    private enum Section: Int {
        case scenarioSetting = 0
        case presets
        case actions
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if currentActionIndex >= 0 {
            tableView.selectRow(at: IndexPath(row: currentActionIndex, section: Section.actions.rawValue), animated: true, scrollPosition: .middle)
        }
    }
    
    func setScenario(_ scenario: Scenario) {
        loadViewIfNeeded()

        if currentActionIndex >= 0 {
            tableView.deselectRow(at: IndexPath(row: currentActionIndex, section: Section.actions.rawValue), animated: false)
            currentActionIndex = -1
        }

        self.scenario = scenario
        tableView.reloadData()
    }
    
    func setPlayer(_ player: ScenarioPlayer?) {
        self.player = player

        if let player = player {
            player.currentActionIndexPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] index in
                    self?.currentActionChange(index)
                }
                .store(in: &cancellables)
        } else {
            cancellables.removeAll()
        }
    }

    private func currentActionChange(_ index: Int) {
        currentActionIndex = index
        if index >= 0 {
            tableView.selectRow(at: IndexPath(row: index, section: Section.actions.rawValue), animated: true, scrollPosition: .middle)
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.scenarioSetting.rawValue:
            return 1
            
        case Section.presets.rawValue:
            return scenario?.presets.count ?? 0
            
        case Section.actions.rawValue:
            return scenario?.actions.count ?? 0
            
        default:
            return 0
        }
    }

    private func makeSpeakParamText(for speakParameters: SpeakParameters) -> String? {
        let params = [
            speakParameters.language.map { R.String.scenarioParamLanguage.localized() + ":" + $0 },
            speakParameters.rate.map { R.String.scenarioParamRate.localized() + ":" + String(format: "%.2f", $0) },
            speakParameters.pitch.map { R.String.scenarioParamPitch.localized() + ":" + String(format: "%.2f", $0) },
            speakParameters.volume.map { R.String.scenarioParamVolume.localized() + ":" + String(format: "%.2f", $0) },
        ].compactMap({$0})

        if params.count > 0 {
            return "(" + params.joined(separator: ", ") + ")"
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case Section.scenarioSetting.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ScenarioSetting", for: indexPath) as! ScenarioSettingCell
            cell.languageLabel.text = scenario?.language ?? ""
            cell.rateLabel.text = scenario.map { String(format: "%.2f", $0.rate) } ?? ""
            cell.pitchLabel.text = scenario.map { String(format: "%.2f", $0.pitch) } ?? ""
            cell.volumeLabel.text = scenario.map { String(format: "%.2f", $0.volume) } ?? ""
            cell.preDelayLabel.text = scenario.map { String(format: "%.2f", $0.preDelay) } ?? ""
            cell.postDelayLabel.text = scenario.map { String(format: "%.2f", $0.postDelay) } ?? ""
            return cell
        
        case Section.presets.rawValue:
            let preset = scenario!.presets[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "Preset", for: indexPath) as! PresetCell
            let paramText = makeSpeakParamText(for: preset)
            cell.speakParamLabel.text = paramText
            cell.speakParamView.isHidden = (paramText == nil)
            cell.speakTextLabel.text = preset.text
            return cell
            
        case Section.actions.rawValue:
            let action = scenario!.actions[indexPath.row]
            let cell: UITableViewCell
            switch action {
            case .speak(let params):
                let speakCell = tableView.dequeueReusableCell(withIdentifier: "Speak", for: indexPath) as! SpeakCell
                speakCell.speakTextLabel.text = params.text
                let paramText = makeSpeakParamText(for: params)
                speakCell.speakParamLabel.text = paramText
                speakCell.speakParamLabel.isHidden = (paramText == nil)
                cell = speakCell
                
            case .changeSlidePage(let params):
                let changeSlidePageCell = tableView.dequeueReusableCell(withIdentifier: "ChangeSlidePage", for: indexPath) as! ChangeSlidePageCell
                switch params.page {
                case .previous:
                    changeSlidePageCell.pageIndexLabel.text = R.String.scenarioChangeSlidePrevious.localized()
                case .next:
                    changeSlidePageCell.pageIndexLabel.text = R.String.scenarioChangeSlideNext.localized()
                case .to(let pageNumber):
                    changeSlidePageCell.pageIndexLabel.text = R.StringFormat.scenarioChangeSlideTo.localized(pageNumber + 1)
                }
                cell = changeSlidePageCell
                
            case .pause:
                cell = tableView.dequeueReusableCell(withIdentifier: "Pause", for: indexPath)

            case .wait(let params):
                let waitCell = tableView.dequeueReusableCell(withIdentifier: "Wait") as! WaitCell
                waitCell.secondsLabel.text = R.StringFormat.waitForSeconds.localized(params.seconds)
                cell = waitCell
            }
            return cell
        
        default:
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case Section.actions.rawValue:
            currentActionIndex = indexPath.row

        default:
            currentActionIndex = -1
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Section.scenarioSetting.rawValue:
            return R.String.scenarioSectionSettings.localized()
        
        case Section.presets.rawValue:
            return R.String.scenarioSectionPresets.localized()
            
        case Section.actions.rawValue:
            return R.String.scenarioSectionActions.localized()
            
        default:
            return nil
        }
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
}

private extension UITableViewCell {
    func changeSelectionAppearance(selected: Bool, typeLabel: UILabel, otherLabels: [UILabel]) {
        if selected {
            contentView.layer.borderColor = typeLabel.backgroundColor!.cgColor
            contentView.layer.borderWidth = 4
            typeLabel.isHighlighted = true
            otherLabels.forEach { $0.isHighlighted = true }
        } else {
            contentView.layer.borderWidth = 0
            typeLabel.isHighlighted = false
            otherLabels.forEach { $0.isHighlighted = false }
        }
    }
}

class ScenarioSettingCell: UITableViewCell {
    @IBOutlet weak var languageLabel: UILabel!
    @IBOutlet weak var rateLabel: UILabel!
    @IBOutlet weak var pitchLabel: UILabel!
    @IBOutlet weak var volumeLabel: UILabel!
    @IBOutlet weak var preDelayLabel: UILabel!
    @IBOutlet weak var postDelayLabel: UILabel!
}

class PresetCell: UITableViewCell {
    @IBOutlet weak var speakParamView: UIView!
    @IBOutlet weak var speakParamLabel: UILabel!
    @IBOutlet weak var speakTextLabel: UILabel!
}

class SpeakCell: UITableViewCell {
    @IBOutlet private weak var typeLabel: UILabel!
    @IBOutlet weak var speakParamLabel: UILabel!
    @IBOutlet weak var speakTextLabel: UILabel!
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        changeSelectionAppearance(selected: selected, typeLabel: typeLabel, otherLabels: [speakTextLabel, speakParamLabel])
    }
}

class ChangeSlidePageCell: UITableViewCell {
    @IBOutlet private weak var typeLabel: UILabel!
    @IBOutlet weak var pageIndexLabel: UILabel!

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        changeSelectionAppearance(selected: selected, typeLabel: typeLabel, otherLabels: [pageIndexLabel])
    }
}

class PauseCell: UITableViewCell {
    @IBOutlet private weak var typeLabel: UILabel!

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        changeSelectionAppearance(selected: selected, typeLabel: typeLabel, otherLabels: [])
    }
}

class WaitCell: UITableViewCell {
    @IBOutlet private weak var typeLabel: UILabel!
    @IBOutlet weak var secondsLabel: UILabel!
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        changeSelectionAppearance(selected: selected, typeLabel: typeLabel, otherLabels: [secondsLabel])
    }
}
