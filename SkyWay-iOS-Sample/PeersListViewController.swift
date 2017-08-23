//
//  PeersListViewController.swift
//  SkyWay-iOS-Sample
//
//  Author: <a href={@docRoot}/author.html}>Author</a>
//  Copyright: <a href={@docRoot}/copyright.html}>Copyright</a>
//

import UIKit

class PeersListViewController: UITableViewController {

    static let CellIdentifier = "ITEMS"
    var items: Array<String>?
    var callback: UIViewController?

    override init(style: UITableViewStyle) {
        super.init(style: style)
        self.items = nil
        self.callback = nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.items = nil
        self.callback = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.allowsSelection = true
        self.tableView.allowsMultipleSelection = false

        self.navigationItem.title = "Select Target's PeerID"

        let bbiBack: UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.cancel))
        self.navigationItem.leftBarButtonItem = bbiBack

        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: PeersListViewController.CellIdentifier)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.tableView.delegate = nil
        self.tableView.dataSource = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        guard let items = self.items else {
            return 0
        }
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: PeersListViewController.CellIdentifier, for: indexPath)
        if (cell == nil) {
            cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: PeersListViewController.CellIdentifier)
            cell?.separatorInset = UIEdgeInsets.zero
        }
        if let items = self.items {
            let iRow = indexPath.row
            if items.count > iRow {
                cell?.textLabel?.text = items[iRow]
            }
        }
        return cell!
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let strTo = self.items?[indexPath.row]
        if let callback = self.callback {
            callback.dismiss(animated: true, completion: {
                if let dcvc: DataConnectionViewController = callback as? DataConnectionViewController {
                    if dcvc.responds(to: #selector(dcvc.callingTo(strDestId:))) {
                        dcvc.performSelector(inBackground: #selector(dcvc.callingTo(strDestId:)), with: strTo)
                    }
                } else if let mcvc: MediaConnectionViewController = callback as? MediaConnectionViewController {
                    if mcvc.responds(to: #selector(mcvc.callingTo(strDestId:))) {
                        mcvc.performSelector(inBackground: #selector(mcvc.callingTo(strDestId:)), with: strTo)
                    }
                }
            })
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }

    // MARK: -

    func cancel() {
        if let callback = self.callback {
            callback.dismiss(animated: true, completion: nil)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
}
