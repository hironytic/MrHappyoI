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

class EditorScenarioViewController: UITableViewController {
    private var scenario: Scenario?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    func setScenario(_ scenario: Scenario) {
        loadViewIfNeeded()
        
        self.scenario = scenario
        tableView.reloadData()
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
            changeSlidePageCell.pageIndexLabel.text = "\(params.page + 1) ページへ" // TODO: localize
            cell = changeSlidePageCell
            
        case .waitForTap:
            cell = tableView.dequeueReusableCell(withIdentifier: "WaitForTap", for: indexPath)

        }
        return cell
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

class WaitForTapCell: UITableViewCell {
    @IBOutlet var typeLabel: UILabel!

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        changeSelectionAppearance(selected: selected, typeLabel: typeLabel, otherLabels: [])
    }
}
