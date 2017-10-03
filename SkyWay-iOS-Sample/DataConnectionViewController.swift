//
//  DataConnectionViewController.swift
//  SkyWay-iOS-Sample
//
//  Author: <a href={@docRoot}/author.html}>Author</a>
//  Copyright: <a href={@docRoot}/copyright.html}>Copyright</a>
//

import UIKit
import SkyWay

class DataConnectionViewController: UIViewController, UINavigationControllerDelegate, UIAlertViewDelegate, UIActionSheetDelegate, UIPopoverPresentationControllerDelegate {

    enum ViewTag: Int {
        case TAG_ID = 1000
        case TAG_WEBRTC_ACTION
        case TAG_VIEW
        case TAG_LOG
        case TAG_DATA_TYPE
        case TAG_SEND_DATA
        case TAG_IMG_VIEW
        case AS_DATA_TYPE
    }

    enum DataType: Int {
        case DT_STRING
        case DT_NUMBER
        case DT_ARRAY
        case DT_DICTIONARY
        case DT_DATA
    }

    let kAPIkey = "yourAPIKEY"
    let kDomain = "yourDomain"

    var peerType: UInt = 0
    var serverIP: String?
    
    var peer: SKWPeer? = nil
    var dataConnection: SKWDataConnection? = nil

    var dataType: DataType = DataType.DT_STRING

    var strOwnId: String? = nil
    var bConnected: Bool = false

    var arySerializationTypes: Array<String> = []
    var aryDataTypes: Array<String> = []

    var aryDataIntTypes: Array<Int> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        //
        // Initialize
        //
        self.strOwnId = nil;
        self.bConnected = false;
        self.dataConnection = nil;

        self.dataType = DataType.DT_STRING

        self.arySerializationTypes = [
            "binary",
            "binary-utf8",
            "json",
            "none"
        ]

        self.aryDataTypes = [
            "Hello SkyWay.        (String)",
            "3.14                    (Number)",
            "[1,2,3]                      (Array)",
            "{'one':1,'two':2}      (Hash)",
            "send Image           (Binary)"
        ]

        self.aryDataIntTypes = [
            DataType.DT_STRING.rawValue,
            DataType.DT_NUMBER.rawValue,
            DataType.DT_ARRAY.rawValue,
            DataType.DT_DICTIONARY.rawValue,
            DataType.DT_DATA.rawValue
        ]

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

        //
        // Initialize views
        //
        if self.navigationItem.title == nil {
            let strTitle = "DataConnection"
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

        // Peer ID
        let fnt: UIFont = UIFont.systemFont(ofSize: UIFont.labelFontSize)
        var rcDesign: CGRect = rcScreen
        rcDesign.size.width = (rcScreen.size.width / 3.0) * 2.0
        rcDesign.size.height = fnt.lineHeight * 3.0

        let rcId: CGRect = rcDesign.insetBy(dx: 2.0, dy: 2.0)

        let lblId: UILabel = UILabel.init(frame: rcId)
        lblId.tag = ViewTag.TAG_ID.rawValue
        lblId.font = fnt
        lblId.textAlignment = NSTextAlignment.center
        lblId.numberOfLines = 2
        lblId.text = "your ID:\n ---"
        lblId.backgroundColor = UIColor.white

        self.view.addSubview(lblId)

        // Connect View
        rcDesign.origin.x	+= rcDesign.size.width
        rcDesign.size.width = rcScreen.size.width - rcDesign.origin.x

        let rcCall: CGRect = rcDesign.insetBy(dx: 2.0, dy: 2.0)

        let btnCall: UIButton = UIButton(type: UIButtonType.roundedRect)
        btnCall.tag = ViewTag.TAG_WEBRTC_ACTION.rawValue
        btnCall.frame = rcCall
        btnCall.setTitle("Connect to", for: UIControlState.normal)
        btnCall.backgroundColor = UIColor.lightGray
        btnCall.addTarget(self, action: #selector(self.onTouchUpInside(_:)), for: UIControlEvents.touchUpInside)
        btnCall.isEnabled = false

        self.view.addSubview(btnCall)

        // Data type View
        rcDesign.origin.x = 0.0
        rcDesign.size.width = (rcScreen.size.width / 3.0) * 2.0
        rcDesign.origin.y = rcId.origin.y + rcId.size.height + 4.0

        let rcDataType: CGRect = rcDesign.insetBy(dx: 2.0, dy: 2.0)

        let btnDataType: UIButton = UIButton(type: UIButtonType.roundedRect)
        btnDataType.tag = ViewTag.TAG_DATA_TYPE.rawValue
        btnDataType.frame = rcDataType
        btnDataType.setTitle("Hello SkyWay.        (String)", for: UIControlState.normal)
        btnDataType.backgroundColor = UIColor.lightGray
        btnDataType.addTarget(self, action: #selector(self.onTouchUpInside(_:)), for: UIControlEvents.touchUpInside)
        btnDataType.isEnabled = false
        
        self.view.addSubview(btnDataType)

        // Send data View
        rcDesign.origin.x	+= rcDesign.size.width
        rcDesign.size.width = rcScreen.size.width - rcDesign.origin.x

        let rcSendData: CGRect = rcDesign.insetBy(dx: 2.0, dy: 2.0)
        
        let btnSendData: UIButton = UIButton(type: UIButtonType.roundedRect)
        btnSendData.tag = ViewTag.TAG_SEND_DATA.rawValue
        btnSendData.frame = rcSendData
        btnSendData.setTitle("Send", for: UIControlState.normal)
        btnSendData.backgroundColor = UIColor.lightGray
        btnSendData.addTarget(self, action: #selector(self.onTouchUpInside(_:)), for: UIControlEvents.touchUpInside)
        btnSendData.isEnabled = false

        self.view.addSubview(btnSendData)

        // Log View
        var rcLog: CGRect = CGRect.zero
        rcLog.origin.y = rcDesign.origin.y + rcDesign.size.height + 4.0
        rcLog.size.width = rcScreen.size.width
        rcLog.size.height = rcScreen.size.height - rcLog.origin.y - 100.0

        let tvLog: UITextView = UITextView(frame: rcLog)
        tvLog.tag = ViewTag.TAG_LOG.rawValue
        tvLog.frame = rcLog
        tvLog.backgroundColor = UIColor.white
        tvLog.layer.borderWidth = 1
        tvLog.layer.borderColor = UIColor.orange.cgColor
        tvLog.isEditable = false

        self.view.addSubview(tvLog)

        // Image View
        let ivIMG: UIImageView = UIImageView()
        ivIMG.contentMode = UIViewContentMode.scaleAspectFill
        ivIMG.frame = CGRect(x: 0.0, y: 0.0, width: 100.0, height: 100.0)
        ivIMG.center = CGPoint(x: rcScreen.size.width / 2.0, y: rcLog.origin.y + rcLog.size.height + 50.0)
        ivIMG.tag = ViewTag.TAG_IMG_VIEW.rawValue

        self.view.addSubview(ivIMG)
    }

    deinit {
        self.strOwnId = nil

        self.dataConnection = nil
        self.peer = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.updateUI()
    }

    // MARK: - Public method

    @objc internal func callingTo(strDestId: String) {
        //////////////////////////////////////////////////////////////////////
        //////////////////  START: Connect SkyWay Peer   /////////////////////
        //////////////////////////////////////////////////////////////////////
        let option: SKWConnectOption = SKWConnectOption()
        option.label = "chat"
        option.metadata = "{'message': 'hi'}"
        option.serialization = SKWSerializationEnum.SERIALIZATION_BINARY
        
        // connect
        if let peer = self.peer {
            self.dataConnection = peer.connect(withId: strDestId, options: option)
            self.setDataCallbacks(data: self.dataConnection)
        }
        //////////////////////////////////////////////////////////////////////
        ///////////////////  END: Connect SkyWay Peer   //////////////////////
        //////////////////////////////////////////////////////////////////////
    }

    @objc func closeChat() {
        if let dataConnection = self.dataConnection {
            dataConnection.close()
        }
    }

    func closeData() {
        self.clearDataCallbacks(data: self.dataConnection)
        self.dataConnection = nil
    }

    // MARK: - Peer

    func setCallbacks(peer: SKWPeer?) {
        guard let _peer = peer else {
            return
        }

        //////////////////////////////////////////////////////////////////////////////////
        ////////////////////  START: Set SkyWay peer callback   //////////////////////////
        //////////////////////////////////////////////////////////////////////////////////
        
        // !!!: Event/Open
        _peer.on(SKWPeerEventEnum.PEER_EVENT_OPEN) { (obj: NSObject?) in
            DispatchQueue.global(qos: .default).async {
                DispatchQueue.main.async {
                    if let strOwnId = obj as? String {
                        self.strOwnId = strOwnId

                        if let lbl: UILabel = self.view.viewWithTag(ViewTag.TAG_ID.rawValue) as? UILabel {
                            lbl.text = String.init(format: "your ID: \n%@", strOwnId)
                            lbl.setNeedsDisplay()
                        }
                    }
                    if let btn: UIButton = self.view.viewWithTag(ViewTag.TAG_WEBRTC_ACTION.rawValue) as? UIButton {
                        btn.isEnabled = true
                        btn.setNeedsDisplay()
                    }
                }
            }
        }

        // !!!: Event/Connection
        _peer.on(SKWPeerEventEnum.PEER_EVENT_CONNECTION) { (obj: NSObject?) in
            if let dataConnection = obj as? SKWDataConnection {
                self.dataConnection = dataConnection
                self.setDataCallbacks(data: self.dataConnection)
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
        /////////////////////  END: Set SkyWay peer callback   ///////////////////////////
        //////////////////////////////////////////////////////////////////////////////////
    }

    // Clear peer callback block
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

    func setDataCallbacks(data: SKWDataConnection?) {
        guard let _data = data else {
            return
        }

        //////////////////////////////////////////////////////////////////////////////////
        /////////////////  START: Set SkyWay Data connection callback   //////////////////
        //////////////////////////////////////////////////////////////////////////////////

        // !!!: DataEvent/Open
        _data.on(SKWDataConnectionEventEnum.DATACONNECTION_EVENT_OPEN) { (obj: NSObject?) in
            self.bConnected = true

            self.updateUI()

            // Log serialization type
            let serialization: String = self.arySerializationTypes[Int(_data.serialization.rawValue)]
            let str: String = String.init(format: "Serialization: %@\n", serialization)

            self.performSelector(onMainThread: #selector(self.appendLogWithMessage(strMessage:)), with: str, waitUntilDone: true)
        }
 
        // !!!: DataEvent/Data
        _data.on(SKWDataConnectionEventEnum.DATACONNECTION_EVENT_DATA) { (obj: NSObject?) in
            var strData: String? = nil
            if let data: String = obj as? String {
                strData = data
            } else if let aryData: NSArray = obj as? NSArray {
                strData = String.init(format: "%@", aryData)
            } else if let dctData: NSDictionary = obj as? NSDictionary {
                strData = String.init(format: "%@", dctData)
            } else if let datData: Data = obj as? Data {
                if let image: UIImage = UIImage(data: datData) {
                    DispatchQueue.global(qos: .default).async {
                        DispatchQueue.main.async {
                            if let ivImg: UIImageView = self.view.viewWithTag(ViewTag.TAG_IMG_VIEW.rawValue) as? UIImageView {
                                ivImg.image = image
                            }
                        }
                    }
                }

                strData = "Received Image (displayed below)"
            } else if let numData: NSNumber = obj as? NSNumber {
                strData = String.init(format: "[%s]%@", numData.objCType, numData)
            }

            if let _strData = strData {
                self.appendLogWithHead(strHeader: "Partner", strValue: _strData)
            }
        }

        // !!!: DataEvent/Close
        _data.on(SKWDataConnectionEventEnum.DATACONNECTION_EVENT_CLOSE) { (obj: NSObject?) in
            self.bConnected = false

            self.updateUI()

            self.performSelector(onMainThread: #selector(self.closeChat), with: nil, waitUntilDone: false)
        }

        // !!!: DataEvent/Error
        _data.on(SKWDataConnectionEventEnum.DATACONNECTION_EVENT_ERROR) { (obj: NSObject?) in
            if let err = obj as? SKWPeerError {
                self.showError(strMsg: err.message)
            }
        }

        //////////////////////////////////////////////////////////////////////////////////
        /////////////////  END: Set SkyWay Data connection callback   ////////////////////
        //////////////////////////////////////////////////////////////////////////////////
    }

    func clearDataCallbacks(data: SKWDataConnection?) {
        guard let _data = data else {
            return
        }

        _data.on(SKWDataConnectionEventEnum.DATACONNECTION_EVENT_OPEN, callback: nil)
        _data.on(SKWDataConnectionEventEnum.DATACONNECTION_EVENT_DATA, callback: nil)
        _data.on(SKWDataConnectionEventEnum.DATACONNECTION_EVENT_CLOSE, callback: nil)
        _data.on(SKWDataConnectionEventEnum.DATACONNECTION_EVENT_ERROR, callback: nil)
    }

    // MARK: - Send Data

    func updateDataType(type: Int) {
        DispatchQueue.global(qos: .default).async {
            DispatchQueue.main.async {
                if let btn: UIButton = self.view.viewWithTag(ViewTag.TAG_DATA_TYPE.rawValue) as? UIButton {
                    let strTitle: String = self.aryDataTypes[type]
                    btn.setTitle(strTitle, for: UIControlState.normal)
                }
            }
        }

        if let dataType: DataConnectionViewController.DataType = DataConnectionViewController.DataType(rawValue: type) {
            self.dataType = dataType
        }
    }

    func executeDataSend(data: SKWDataConnection, type: DataType) {
        var bResult = false
        var strMsg: String = String.init()
        if DataType.DT_STRING == type {
            let strData = "Hello SkyWay."

            bResult = data.send(strData as NSString)

            strMsg = String.init(format: "%@", strData)
        } else if DataType.DT_NUMBER == type {
            let numData = NSNumber(value: 3.14)

            bResult = data.send(numData)

            strMsg = String.init(format: "%@", numData)
        } else if DataType.DT_ARRAY == type {
            let aryData = [1, 2, 3]

            bResult = data.send(aryData as NSArray)
            
            strMsg = String.init(format: "%@", aryData)
        } else if DataType.DT_DICTIONARY == type {
            let dctData = ["one": 1, "two": 2]

            bResult = data.send(dctData as NSDictionary)
            
            strMsg = String.init(format: "%@", dctData)
        } else if DataType.DT_DATA == type {
            if let image: UIImage = UIImage(named: "image.png") {
                if let pngData: Data = UIImageJPEGRepresentation(image, 1.0) {
                    bResult = data.send(pngData as NSData)
                    strMsg = "Send Image"
                }
            }
        }

        // successfully send
        if bResult {
            self.appendLogWithHead(strHeader: "You", strValue: strMsg)
        }
    }

    // MARK: - Utility

    func showError(strMsg: String) {
        DispatchQueue.global(qos: .default).async {
            DispatchQueue.main.async {
                if #available(iOS 8.0, *) {
                    // Use UIAlertController
                    let ac: UIAlertController = UIAlertController(title: "Error", message: strMsg, preferredStyle: UIAlertControllerStyle.alert)

                    ac.addAction(UIAlertAction(title: "Done", style: UIAlertActionStyle.cancel, handler: { (action: UIAlertAction) in
                        
                    }))

                    self.present(ac, animated: true, completion: { () in
                        
                    })
                } else {
                    // Use UIAlertView
                    let av: UIAlertView = UIAlertView(title: "Error", message: strMsg, delegate: self, cancelButtonTitle: "Done")

                    av.show()
                }
            }
        }
    }

    @objc func clearViewController() {
        self.closeChat()

        self.clearCallbacks(peer: self.peer)

        for vw in self.view.subviews {
            if let btn = vw as? UIButton {
                btn.removeTarget(self, action: #selector(self.onTouchUpInside(_:)), for: UIControlEvents.touchUpInside)
            }
            
            vw.removeFromSuperview()
        }

        SKWNavigator.terminate()

        if let peer = self.peer {
            peer.destroy()
        }
    }

    func updateUI() {
        DispatchQueue.global(qos: .default).async {
            DispatchQueue.main.async {
                var strTitle = "---"
                if let btn: UIButton = self.view.viewWithTag(ViewTag.TAG_WEBRTC_ACTION.rawValue) as? UIButton {
                    if !self.bConnected {
                        strTitle = "Connect to"
                    } else {
                        strTitle = "Disconnect"
                    }

                    btn.setTitle(strTitle, for: UIControlState.normal)
                }

                if let btn: UIButton = self.view.viewWithTag(ViewTag.TAG_DATA_TYPE.rawValue) as? UIButton {
                    btn.isEnabled = self.bConnected
                }

                if let btn: UIButton = self.view.viewWithTag(ViewTag.TAG_SEND_DATA.rawValue) as? UIButton {
                    btn.isEnabled = self.bConnected
                }
            }
        }
    }

    @objc func appendLogWithMessage(strMessage: String) {
        DispatchQueue.global(qos: .default).async {
            DispatchQueue.main.async {
                if let tvLog: UITextView = self.view.viewWithTag(ViewTag.TAG_LOG.rawValue) as? UITextView {
                    var rng: NSRange = NSMakeRange(tvLog.text.characters.count, 0)
                    tvLog.selectedRange = rng

                    tvLog.replace(tvLog.selectedTextRange!, withText: strMessage)

                    rng = NSMakeRange(tvLog.text.characters.count, 0)
                    tvLog.scrollRangeToVisible(rng)
                }
            }
        }
    }

    func appendLogWithHead(strHeader: String, strValue: String) {
        guard strValue.characters.count > 0 else {
            return
        }
        var mstrValue: String = String.init()

        mstrValue += "["
        mstrValue += strHeader
        mstrValue += "]"

        if 32000 < strValue.characters.count {
            var rng: NSRange = NSMakeRange(0, 32)
            mstrValue += (strValue as NSString).substring(with: rng)
            mstrValue += "..."
            rng = NSMakeRange(strValue.characters.count - 32, 32)
            mstrValue += (strValue as NSString).substring(with: rng)
        } else {
            mstrValue += strValue
        }

        mstrValue += "\n"

        self.performSelector(onMainThread: #selector(self.appendLogWithMessage(strMessage:)), with: mstrValue, waitUntilDone: true)
    }

    // MARK: - UINavigationControllerDelegate
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if UINavigationControllerOperation.pop == operation {
            if fromVC.isKind(of: DataConnectionViewController.self) {
                self.performSelector(onMainThread: #selector(self.clearViewController), with: nil, waitUntilDone: false)
                navigationController.delegate = nil
            }
        }
        return nil
    }
    
    // MARK: - UIButtonActionDelegate
    
    @objc func onTouchUpInside(_ sender: Any) {
        if let btn: UIButton = sender as? UIButton {
            if ViewTag.TAG_WEBRTC_ACTION.rawValue == btn.tag {
                if nil == self.dataConnection {
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
                            DispatchQueue.global(qos: .default).async {
                                DispatchQueue.main.async {
                                    self.present(nc, animated: true, completion: nil)
                                }
                            }
                            
                            maItems.removeAll()
                        })
                    }
                } else {
                    // Closing chat
                    self.performSelector(onMainThread: #selector(self.closeChat), with: nil, waitUntilDone: false)
                }
            } else if ViewTag.TAG_DATA_TYPE.rawValue == btn.tag {
                if #available(iOS 8.0, *) {
                    // 8.0 Later
                    let ac: UIAlertController = UIAlertController(title: "Sample Data          (Data types)", message: "", preferredStyle: UIAlertControllerStyle.actionSheet)

                    let aaCancel: UIAlertAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.destructive, handler: { (action: UIAlertAction) in
                    })

                    ac.addAction(aaCancel)

                    var iIndex: Int = 0
                    for strType in self.aryDataTypes {
                        let aaTypes: UIAlertAction = UIAlertAction(title: strType, style: UIAlertActionStyle.destructive, handler: { (action: UIAlertAction) in
                            var iIndex2: Int = 0
                            for strType2 in self.aryDataTypes {
                                if ComparisonResult.orderedSame == action.title?.caseInsensitiveCompare(strType2) {
                                    break
                                }

                                iIndex2 += 1
                                self.updateDataType(type: iIndex2)
                            }
                        })
                        ac.addAction(aaTypes)

                        iIndex += 1
                    }

                    if UIUserInterfaceIdiom.pad == UIDevice.current.userInterfaceIdiom {
                        if let vw: UIView = self.view.viewWithTag(ViewTag.TAG_DATA_TYPE.rawValue) {
                            if let ppc = ac.popoverPresentationController {
                                ac.modalPresentationStyle = .popover
                                ac.preferredContentSize = vw.frame.size
                                ppc.sourceView = vw
                                ppc.sourceRect = btn.frame
                                ppc.permittedArrowDirections = .any
                                ppc.delegate = self
                                self.present(ac, animated: true, completion: nil)
                            }
                        }
                    } else {
                        self.present(ac, animated: true, completion: nil)
                    }
                } else {
                    // 7.1 Earlier
                    let acs: UIActionSheet = UIActionSheet(title:"Sample Data          (Data types)", delegate: self, cancelButtonTitle: nil, destructiveButtonTitle: nil)

                    for strTitle in self.aryDataTypes {
                        acs.addButton(withTitle: strTitle)
                    }

                    acs.cancelButtonIndex = acs.addButton(withTitle: "Cancel")

                    acs.tag = ViewTag.AS_DATA_TYPE.rawValue

                    if UIUserInterfaceIdiom.pad == UIDevice.current.userInterfaceIdiom {
                        acs.show(from: btn.frame, in: self.view, animated: true)
                    } else {
                        acs.show(in: self.view.window!)
                    }
                }
            } else if ViewTag.TAG_SEND_DATA.rawValue == btn.tag {
                if let dataConnection = self.dataConnection {
                    self.executeDataSend(data: dataConnection, type: self.dataType)
                }
            }
        }
    }
}
