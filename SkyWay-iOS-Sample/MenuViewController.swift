//
//  MenuViewController.swift
//  SkyWay-iOS-Sample
//
//  Author: <a href={@docRoot}/author.html}>Author</a>
//  Copyright: <a href={@docRoot}/copyright.html}>Copyright</a>
//

import UIKit

class MenuViewController: UIViewController {

    enum ViewTag: Int {
        case BTN_VIDEOCHAT
        case BTN_CHAT
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.backgroundColor = UIColor.white
        self.title = "Menu"
        var rcClient: CGRect = self.view.bounds
        if let navigationBar = self.navigationController?.navigationBar {
            let rcTitle: CGRect = navigationBar.frame
            rcClient.origin.y = rcTitle.origin.y + rcTitle.size.height
            rcClient.size.height -= rcClient.origin.y
        }
        let fButtonHeight: CGFloat = rcClient.size.height / 7.0

        // Video chat
        var rcDesign: CGRect = CGRect.zero
        rcDesign.origin.y = fButtonHeight * 1.0
        rcDesign.size.width = rcClient.size.width
        rcDesign.size.height = fButtonHeight

        let rcVideoChat: CGRect = rcDesign.insetBy(dx: 8.0, dy: 4.0)

        let btnVideoChat: UIButton = UIButton(type: .roundedRect)
        btnVideoChat.tag = ViewTag.BTN_VIDEOCHAT.rawValue
        btnVideoChat.setTitle("Media connection", for: UIControlState.normal)
        btnVideoChat.backgroundColor = UIColor.lightGray
        btnVideoChat.frame = rcVideoChat
        btnVideoChat.addTarget(self, action: #selector(self.touchUpInside(_:)), for: UIControlEvents.touchUpInside)

        self.view.addSubview(btnVideoChat)

        // Chat
        rcDesign = CGRect.zero
        rcDesign.origin.y = fButtonHeight * 2.0
        rcDesign.size.width = rcClient.size.width
        rcDesign.size.height = fButtonHeight

        let rcChat: CGRect = rcDesign.insetBy(dx: 8.0, dy: 4.0)

        let btnChat: UIButton = UIButton(type: .roundedRect)
        btnChat.tag = ViewTag.BTN_CHAT.rawValue
        btnChat.setTitle("Data connection", for: UIControlState.normal)
        btnChat.backgroundColor = UIColor.lightGray
        btnChat.frame = rcChat
        btnChat.addTarget(self, action: #selector(self.touchUpInside(_:)), for: UIControlEvents.touchUpInside)
        
        self.view.addSubview(btnChat)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

// MARK: -

    func touchUpInside(_ sender: Any) {
        if let btn: UIButton = sender as? UIButton {
            var vc: UIViewController? = nil
            if ViewTag.BTN_VIDEOCHAT.rawValue == btn.tag {
                let vcVideoChat: MediaConnectionViewController = MediaConnectionViewController(nibName: nil, bundle: Bundle.main)
                let strTitle: String = "MediaConnection"
                vcVideoChat.navigationItem.title = strTitle
                vc = vcVideoChat
            } else if ViewTag.BTN_CHAT.rawValue == btn.tag {
                let vcChat: DataConnectionViewController = DataConnectionViewController(nibName: nil, bundle: Bundle.main)
                let strTitle: String = "DataConnection"
                vcChat.navigationItem.title = strTitle
                vc = vcChat
            }

            if nil != vc {
                self.navigationController?.pushViewController(vc!, animated: true)
            }
        }
    }
}

