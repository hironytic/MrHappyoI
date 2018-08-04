//
// ChangeSlidePageActionViewController.swift
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

public class ChangeSlidePageActionViewController: UITableViewController {
    public var params = ChangeSlidePageParameters(page: .next)
    public var paramsChangedHandler: (ChangeSlidePageParameters) -> Void = { _ in }

    public init() {
        super.init(style: .grouped)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        title = R.String.scenarioChangeSlide.localized()
    }

    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    public override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 3
        } else {
            return 0
        }
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .value1, reuseIdentifier: "cell")
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = R.String.scenarioChangeSlidePrevious.localized()
                if case .previous = params.page {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .none
                }
                cell.detailTextLabel?.text = ""

            case 1:
                cell.textLabel?.text = R.String.scenarioChangeSlideNext.localized()
                if case .next = params.page {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .none
                }
                cell.detailTextLabel?.text = ""

            case 2:
                cell.textLabel?.text = R.String.scenarioChangeSlideSpecified.localized()
                if case .to(let pageNumber) = params.page {
                    cell.accessoryType = .checkmark
                    cell.detailTextLabel?.text = R.StringFormat.scenarioChangeSlideTo.localized(pageNumber + 1)
                } else {
                    cell.accessoryType = .none
                    cell.detailTextLabel?.text = ""
                }

            default:
                break
            }

            return cell
        } else {
            return tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        }
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 0 else { return }
        
        switch indexPath.row {
        case 0:
            params.page = .previous
            notifyParamsChanged()
            navigationController?.popViewController(animated: true)
        
        case 1:
            params.page = .next
            notifyParamsChanged()
            navigationController?.popViewController(animated: true)

        case 2:
            // TODO:
            break
        
        default:
            break
        }
    }
    
    private func notifyParamsChanged() {
        self.paramsChangedHandler(self.params)
    }
}
