//
//  MediaConnectionViewController.swift
//  SkyWay-iOS-Sample
//
//  Author: <a href={@docRoot}/author.html}>Author</a>
//  Copyright: <a href={@docRoot}/copyright.html}>Copyright</a>
//

import UIKit

class MediaConnectionViewController: UIViewController, UINavigationControllerDelegate, UIAlertViewDelegate {

    enum ViewTag: Int {
        case TAG_ID = 1000
        case TAG_WEBRTC_ACTION
        case TAG_REMOTE_VIDEO
        case TAG_LOCAL_VIDEO
    }

    enum AlertType: UInt {
        case ALERT_ERROR
        case ALERT_CALLING
    }

    let kAPIkey = "yourAPIKEY"
    let kDomain = "yourDomain"

    var peerType: UInt = 0
    var serverIP: String?

    var peer: SKWPeer? = nil
    var msLocal: SKWMediaStream? = nil
    var msRemote: SKWMediaStream? = nil
    var mediaConnection: SKWMediaConnection? = nil
    var dataConnection: SKWDataConnection? = nil

    var strOwnId: String? = nil
    var bConnected: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        //
        // Initialize
        //
        self.strOwnId = nil
        self.bConnected = false
        self.view.backgroundColor = UIColor.white
        if let navigationController = self.navigationController {
            navigationController.delegate = self
        }

        //////////////////////////////////////////////////////////////////////
        //////////////////  START: Initialize SkyWay Peer ////////////////////
        //////////////////////////////////////////////////////////////////////
        let option: SKWPeerOption = SKWPeerOption()
        option.key = self.kAPIkey
        option.domain = self.kDomain

        // SKWPeer has many options. Please check the document. >> http://nttcom.github.io/skyway/docs/

        self.peer = SKWPeer(id: nil, options: option)
        self.setCallbacks(peer: self.peer)
        //////////////////////////////////////////////////////////////////////
        ////////////////// END: Initialize SkyWay Peer ///////////////////////
        //////////////////////////////////////////////////////////////////////

        //////////////////////////////////////////////////////////////////////
        ////////////////// START: Get Local Stream   /////////////////////////
        //////////////////////////////////////////////////////////////////////
        SKWNavigator.initialize(self.peer)
        let constraints: SKWMediaConstraints = SKWMediaConstraints.init()
        constraints.maxWidth = 960
        constraints.maxHeight = 540
        //	constraints.cameraPosition = SKWCameraPositionEnum.SKW_CAMERA_POSITION_BACK
        constraints.cameraPosition = SKWCameraPositionEnum.CAMERA_POSITION_FRONT

        self.msLocal = SKWNavigator.getUserMedia(constraints)
        //////////////////////////////////////////////////////////////////////
        //////////////////// END: Get Local Stream   /////////////////////////
        //////////////////////////////////////////////////////////////////////

        //
        // Initialize views
        //
        if self.navigationItem.title == nil {
            let strTitle = "MediaConnection"
            self.navigationItem.title = strTitle
        }

        var rcScreen: CGRect = self.view.bounds
        if floor(NSFoundationVersionNumber_iOS_6_1) < floor(NSFoundationVersionNumber) {
            var fValue: CGFloat = UIApplication.shared.statusBarFrame.size.height
            rcScreen.origin.y = fValue
            if let navigationController: UINavigationController = self.navigationController {
                if !navigationController.isNavigationBarHidden {
                    fValue = navigationController.navigationBar.frame.size.height
                    rcScreen.origin.y += fValue
                }
            }
        }

        // Initialize Remote video view
        var rcRemote: CGRect = CGRect.zero
        if UIUserInterfaceIdiom.pad == UI_USER_INTERFACE_IDIOM() {
            // iPad
            rcRemote.size.width = 480.0
            rcRemote.size.height = 480.0
        } else {
            // iPhone / iPod touch
            rcRemote.size.width = rcScreen.size.width
            rcRemote.size.height = rcRemote.size.width
        }
        rcRemote.origin.x = (rcScreen.size.width - rcRemote.size.width) / 2.0
        rcRemote.origin.y = (rcScreen.size.height - rcRemote.size.height) / 2.0
        rcRemote.origin.y -= 8.0

        // Initialize Local video view
        var rcLocal: CGRect = CGRect.zero
        if UIUserInterfaceIdiom.pad == UI_USER_INTERFACE_IDIOM() {
            rcLocal.size.width = rcScreen.size.width / 5.0
            rcLocal.size.height = rcScreen.size.height / 5.0
        } else {
            rcLocal.size.width = rcScreen.size.height / 5.0
            rcLocal.size.height = rcLocal.size.width
        }
        rcLocal.origin.x = rcScreen.size.width - rcLocal.size.width - 8.0
        rcLocal.origin.y = rcScreen.size.height - rcLocal.size.height - 8.0
        rcLocal.origin.y -= self.navigationController?.toolbar.frame.size.height ?? 0

        //////////////////////////////////////////////////////////////////////
        ////////////  START: Add Remote & Local SKWVideo to View   ///////////
        //////////////////////////////////////////////////////////////////////
        let vwRemote: SKWVideo = SKWVideo(frame: rcRemote)
        vwRemote.tag = ViewTag.TAG_REMOTE_VIDEO.rawValue
        vwRemote.isUserInteractionEnabled = false
        vwRemote.isHidden = true
        self.view.addSubview(vwRemote)

        let vwLocal: SKWVideo = SKWVideo(frame: rcLocal)
        vwLocal.tag = ViewTag.TAG_LOCAL_VIDEO.rawValue
        self.view.addSubview(vwLocal)

        vwLocal.addSrc(self.msLocal, track: 0)
        //////////////////////////////////////////////////////////////////////
        ////////////  END: Add Remote & Local SKWVideo to View   /////////////
        //////////////////////////////////////////////////////////////////////

        // Peer ID View
        let fnt: UIFont = UIFont.systemFont(ofSize: UIFont.labelFontSize)

        var rcId: CGRect = rcScreen
        rcId.size.width = (rcScreen.size.width / 3.0) * 2.0
        rcId.size.height = fnt.lineHeight * 2.0

        let lblId: UILabel = UILabel(frame: rcId)
        lblId.tag = ViewTag.TAG_ID.rawValue
        lblId.font = fnt
        lblId.textAlignment = NSTextAlignment.center
        lblId.numberOfLines = 2
        lblId.text = "your ID:\n ---"
        lblId.backgroundColor = UIColor.white

        self.view.addSubview(lblId)

        // Call View
        var rcCall: CGRect = rcId
        rcCall.origin.x	= rcId.origin.x + rcId.size.width
        rcCall.size.width = (rcScreen.size.width / 3.0) * 1.0
        rcCall.size.height = fnt.lineHeight * 2.0
        let btnCall: UIButton = UIButton(type: UIButtonType.roundedRect)
        btnCall.tag = ViewTag.TAG_WEBRTC_ACTION.rawValue
        btnCall.frame = rcCall
        btnCall.setTitle("Call to", for: UIControlState.normal)
        btnCall.backgroundColor = UIColor.lightGray
        btnCall.addTarget(self, action: #selector(self.onTouchUpInside(_:)), for: UIControlEvents.touchUpInside)

        self.view.addSubview(btnCall)

        // Change Camera
        var rcChange: CGRect = rcScreen
        rcChange.size.width = rcScreen.size.width
        rcChange.size.height = fnt.lineHeight * 2.0
        rcChange.origin.y = rcScreen.size.height - rcChange.size.height

        let btnChange: UIButton = UIButton(type: UIButtonType.roundedRect)
        btnChange.frame = rcChange
        btnChange.setTitle("Change Camera", for: UIControlState.normal)
        btnChange.backgroundColor = UIColor.white
        btnChange.addTarget(self, action: #selector(self.cycleLocalCamera), for: UIControlEvents.touchUpInside)

        self.view.addSubview(btnChange)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        UIApplication.shared.isIdleTimerDisabled = false
        UIApplication.shared.isIdleTimerDisabled = true

        self.updateActionButtonTitle()
    }

    override func viewDidDisappear(_ animated: Bool) {
        UIApplication.shared.isIdleTimerDisabled = true
        UIApplication.shared.isIdleTimerDisabled = false

        super.viewDidDisappear(animated)
    }

    deinit {
        self.msLocal = nil
        self.msRemote = nil
        
        self.strOwnId = nil
        
        self.mediaConnection = nil
        self.peer = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Public method

    internal func callingTo(strDestId: String) {
        //////////////////////////////////////////////////////////////////////
        ////////////////// START: Call SkyWay Peer   /////////////////////////
        //////////////////////////////////////////////////////////////////////
        self.mediaConnection = self.peer?.call(withId: strDestId, stream: self.msLocal)
        
        self.setMediaCallbacks(media: self.mediaConnection)
        //////////////////////////////////////////////////////////////////////
        /////////////////// END: Call SkyWay Peer   //////////////////////////
        //////////////////////////////////////////////////////////////////////
    }

    func closeChat() {
        if let mediaConnection = self.mediaConnection {
            if let msRemote = self.msRemote {
                if let video: SKWVideo = self.view.viewWithTag(ViewTag.TAG_REMOTE_VIDEO.rawValue) as? SKWVideo {
                    video.removeSrc(msRemote, track: 0)
                }
                msRemote.close()
                self.msRemote = nil
            }
            mediaConnection.close()
        }
    }

    func closeMedia() {
        self.unsetRemoteView()

        self.clearMediaCallbacks(media: self.mediaConnection)

        self.mediaConnection = nil
    }

    // MARK: -

    func setCallbacks(peer: SKWPeer?) {
        guard let _peer = peer else {
            return
        }

        //////////////////////////////////////////////////////////////////////////////////
        ///////////////////// START: Set SkyWay peer callback   //////////////////////////
        //////////////////////////////////////////////////////////////////////////////////

        // !!!: Event/Open
        _peer.on(SKWPeerEventEnum.PEER_EVENT_OPEN, callback: { (obj: NSObject?) in
            DispatchQueue.main.async {
                if let strOwnId = obj as? String {
                    self.strOwnId = strOwnId

                    if let lbl: UILabel = self.view.viewWithTag(ViewTag.TAG_ID.rawValue) as? UILabel {
                        lbl.text = String.init(format: "your ID: \n%@", strOwnId)
                        lbl.setNeedsDisplay()
                    }

                    if let btn: UIButton = self.view.viewWithTag(ViewTag.TAG_WEBRTC_ACTION.rawValue) as? UIButton {
                        btn.isEnabled = true
                    }
                }
            }
        })

        // !!!: Event/Call
        _peer.on(SKWPeerEventEnum.PEER_EVENT_CALL) { (obj: NSObject?) in
            if let mediaConnection = obj as? SKWMediaConnection {
                self.mediaConnection = mediaConnection

                self.setMediaCallbacks(media: self.mediaConnection)
                self.mediaConnection?.answer(self.msLocal)
            }
        }

        // !!!: Event/Close
        _peer.on(SKWPeerEventEnum.PEER_EVENT_CLOSE) { (obj: NSObject?) in
        }
        
        // !!!: Event/Disconnected
        _peer.on(SKWPeerEventEnum.PEER_EVENT_DISCONNECTED) { (obj: NSObject?) in
        }

        // !!!: Event/Error
        _peer.on(SKWPeerEventEnum.PEER_EVENT_ERROR) { (obj: NSObject?) in
        }

        //////////////////////////////////////////////////////////////////////////////////
        /////////////////////// END: Set SkyWay peer callback   //////////////////////////
        //////////////////////////////////////////////////////////////////////////////////
    }

    func clearCallbacks(peer: SKWPeer?) {
        guard let _peer = peer else {
            return
        }
        _peer.on(SKWPeerEventEnum.PEER_EVENT_OPEN, callback: nil)
        _peer.on(SKWPeerEventEnum.PEER_EVENT_CONNECTION, callback: nil)
        _peer.on(SKWPeerEventEnum.PEER_EVENT_CALL, callback: nil)
        _peer.on(SKWPeerEventEnum.PEER_EVENT_CLOSE, callback: nil)
        _peer.on(SKWPeerEventEnum.PEER_EVENT_DISCONNECTED, callback: nil)
        _peer.on(SKWPeerEventEnum.PEER_EVENT_ERROR, callback: nil)
    }

    func setMediaCallbacks(media: SKWMediaConnection?) {
        guard let _media = media else {
            return
        }

        //////////////////////////////////////////////////////////////////////////////////
        ////////////////  START: Set SkyWay Media connection callback   //////////////////
        //////////////////////////////////////////////////////////////////////////////////

        // !!!: MediaEvent/Stream
        _media.on(SKWMediaConnectionEventEnum.MEDIACONNECTION_EVENT_STREAM) { (obj: NSObject?) in
            if let stream = obj as? SKWMediaStream {
                self.setRemoteView(stream: stream)
            }
        }

        // !!!: MediaEvent/Close
        _media.on(SKWMediaConnectionEventEnum.MEDIACONNECTION_EVENT_CLOSE) { (obj: NSObject?) in
            self.closeMedia()
        }

        // !!!: MediaEvent/Error
        _media.on(SKWMediaConnectionEventEnum.MEDIACONNECTION_EVENT_ERROR) { (obj: NSObject?) in
        }

        //////////////////////////////////////////////////////////////////////////////////
        /////////////////  END: Set SkyWay Media connection callback   ///////////////////
        //////////////////////////////////////////////////////////////////////////////////
    }

    func clearMediaCallbacks(media: SKWMediaConnection?) {
        guard let _media = media else {
            return
        }

        _media.on(SKWMediaConnectionEventEnum.MEDIACONNECTION_EVENT_STREAM, callback: nil)
        _media.on(SKWMediaConnectionEventEnum.MEDIACONNECTION_EVENT_CLOSE, callback: nil)
        _media.on(SKWMediaConnectionEventEnum.MEDIACONNECTION_EVENT_ERROR, callback: nil)
    }

    func cycleLocalCamera() {
        guard let msLocal = self.msLocal else {
            return
        }

        var pos: SKWCameraPositionEnum = msLocal.getCameraPosition()
        if (SKWCameraPositionEnum.CAMERA_POSITION_BACK == pos) {
            pos = SKWCameraPositionEnum.CAMERA_POSITION_FRONT
        } else if (SKWCameraPositionEnum.CAMERA_POSITION_FRONT == pos) {
            pos = SKWCameraPositionEnum.CAMERA_POSITION_BACK
        } else {
            return
        }
        self.msLocal?.setCameraPosition(pos)
    }

    // MARK: - Utility

    func clearViewController() {
        self.clearMediaCallbacks(media: self.mediaConnection)

        self.closeChat()

        if let msLocal = self.msLocal {
            msLocal.close()
            self.msLocal = nil
        }

        self.clearCallbacks(peer: self.peer)

        for vw in self.view.subviews {
            if let btn = vw as? UIButton {
                btn.removeTarget(self, action: #selector(self.onTouchUpInside(_:)), for: UIControlEvents.touchUpInside)
            }

            vw.removeFromSuperview()
        }

        self.navigationItem.rightBarButtonItem = nil

        SKWNavigator.terminate()

        if let peer = self.peer {
            peer.destroy()
        }
    }

    func setRemoteView(stream: SKWMediaStream) {
        if (self.bConnected) {
            return
        }

        self.bConnected = true

        self.msRemote = stream

        self.updateActionButtonTitle()

        DispatchQueue.main.async {
            if let vwRemote: SKWVideo = self.view.viewWithTag(ViewTag.TAG_REMOTE_VIDEO.rawValue) as? SKWVideo {
                vwRemote.isHidden = false
                vwRemote.isUserInteractionEnabled = true

                vwRemote.addSrc(self.msRemote, track: 0)
            }
        }
    }

    func unsetRemoteView() {
        if (!self.bConnected) {
            return
        }

        self.bConnected = false

        if let vwRemote: SKWVideo = self.view.viewWithTag(ViewTag.TAG_REMOTE_VIDEO.rawValue) as? SKWVideo {
            if let msRemote = self.msRemote {
                vwRemote.removeSrc(self.msRemote, track: 0)

                msRemote.close()

                self.msRemote = nil
            }
            DispatchQueue.main.async {
                vwRemote.isUserInteractionEnabled = false
                vwRemote.isHidden = true
            }
        }

        self.updateActionButtonTitle()
    }

    func updateActionButtonTitle() {
        DispatchQueue.main.async {
            if let btn: UIButton = self.view.viewWithTag(ViewTag.TAG_WEBRTC_ACTION.rawValue) as? UIButton {
                var strTitle: String = "---"
                if (!self.bConnected) {
                    strTitle = "Call to"
                } else {
                    strTitle = "End call"
                }
                btn.setTitle(strTitle, for: UIControlState.normal)
            }
        }
    }

    // MARK: - UINavigationControllerDelegate

    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if UINavigationControllerOperation.pop == operation {
            if fromVC.isKind(of: MediaConnectionViewController.self) {
                self.performSelector(onMainThread: #selector(self.clearViewController), with: nil, waitUntilDone: false)
                navigationController.delegate = nil
            }
        }
        return nil
    }
    
    // MARK: - UIButtonActionDelegate
    
    func onTouchUpInside(_ sender: Any) {
        if let btn: UIButton = sender as? UIButton {
            if (ViewTag.TAG_WEBRTC_ACTION.rawValue == btn.tag) {
                if (nil == self.mediaConnection) {
                    if let peer = self.peer {
                        // Listing all peers
                        peer.listAllPeers({ (aryPeers) in
                            var maItems: Array<Any?> = []
                            if (nil == self.strOwnId) {
                                maItems.append(aryPeers)
                            } else {
                                aryPeers?.forEach({ (element) in
                                    if let strValue: String = element as? String {
                                        if ComparisonResult.orderedSame == self.strOwnId?.caseInsensitiveCompare(strValue) {
                                            return
                                        }
                                        maItems.append(strValue)
                                    }
                                })
                            }

                            let vc: PeersListViewController = PeersListViewController(style: UITableViewStyle.plain)
                            vc.items = maItems as? Array<String>
                            vc.callback = self

                            let nc: UINavigationController = UINavigationController(rootViewController: vc)
                            DispatchQueue.main.async {
                                self.present(nc, animated: true, completion: nil)
                            }

                            maItems.removeAll()
                        })
                    }
                } else {
                    // Closing chat
                    self.performSelector(inBackground: #selector(self.closeChat), with: nil)
                }
            }
        }
    }
}
