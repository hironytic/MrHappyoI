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
import Eventitic

class EditorScenarioViewController: UITableViewController {
    private var scenario: Scenario?
    private var player: ScenarioPlayer?
    private var listenerStore: ListenerStore?
    public private(set) var currentActionIndex: Int = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if currentActionIndex >= 0 {
            tableView.selectRow(at: IndexPath(row: currentActionIndex, section: 0), animated: true, scrollPosition: .middle)
        }
    }
    
    func setPlayer(_ player: ScenarioPlayer) {
        loadViewIfNeeded()
        
        if currentActionIndex >= 0 {
            tableView.deselectRow(at: IndexPath(row: currentActionIndex, section: 0), animated: false)
            currentActionIndex = -1
        }
        self.scenario = player.scenario
        self.player = player
        tableView.reloadData()
        
        let listenerStore = ListenerStore()
        self.listenerStore = listenerStore
        player.currentActionChangeEvent.listen { [weak self] index in self?.currentActionChange(index) }.addToStore(listenerStore)
    }

    private func currentActionChange(_ index: Int) {
        currentActionIndex = index
        if index >= 0 {
            tableView.selectRow(at: IndexPath(row: index, section: 0), animated: true, scrollPosition: .middle)
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scenario?.actions.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let action = scenario!.actions[indexPath.row]
        let cell: UITableViewCell
        switch action {
        case .speak(let params):
            let speakCell = tableView.dequeueReusableCell(withIdentifier: "Speak", for: indexPath) as! SpeakCell
            speakCell.speakTextLabel.text = params.text
            cell = speakCell
            
        case .changeSlidePage(let params):
            let changeSlidePageCell = tableView.dequeueReusableCell(withIdentifier: "ChangeSlidePage", for: indexPath) as! ChangeSlidePageCell
            changeSlidePageCell.pageIndexLabel.text = R.StringFormat.scenarioChangeSlideTo.localized(params.page + 1)
            cell = changeSlidePageCell
            
        case .pause:
            cell = tableView.dequeueReusableCell(withIdentifier: "Pause", for: indexPath)

        case .wait(let params):
            let waitCell = tableView.dequeueReusableCell(withIdentifier: "Wait") as! WaitCell
            waitCell.secondsLabel.text = R.StringFormat.waitForSeconds.localized(params.seconds)
            cell = waitCell
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            currentActionIndex = indexPath.row
        } else {
            currentActionIndex = -1
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

class SpeakCell: UITableViewCell {
    @IBOutlet var typeLabel: UILabel!
    @IBOutlet var speakTextLabel: UILabel!
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        changeSelectionAppearance(selected: selected, typeLabel: typeLabel, otherLabels: [speakTextLabel])
    }
}

class ChangeSlidePageCell: UITableViewCell {
    @IBOutlet var typeLabel: UILabel!
    @IBOutlet var pageIndexLabel: UILabel!

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        changeSelectionAppearance(selected: selected, typeLabel: typeLabel, otherLabels: [pageIndexLabel])
    }
}

class PauseCell: UITableViewCell {
    @IBOutlet var typeLabel: UILabel!

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        changeSelectionAppearance(selected: selected, typeLabel: typeLabel, otherLabels: [])
    }
}

class WaitCell: UITableViewCell {
    @IBOutlet var typeLabel: UILabel!
    @IBOutlet var secondsLabel: UILabel!
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        changeSelectionAppearance(selected: selected, typeLabel: typeLabel, otherLabels: [secondsLabel])
    }
}
