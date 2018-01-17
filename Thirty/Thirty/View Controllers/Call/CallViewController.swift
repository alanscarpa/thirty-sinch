//
//  CallViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/9/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit

class CallViewController: UIViewController, SINCallDelegate {

    @IBOutlet weak var remoteVideoView: UIView!
    @IBOutlet weak var localVideoView: UIView!
    @IBOutlet weak var remoteUserLabel: UILabel!
    @IBOutlet weak var answerCallButton: UIButton!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    
    let audioController = SinchManager.shared.clientAudioController
    let videoController = SinchManager.shared.clientVideoController
    
    var call: SINCall? {
        didSet {
            call?.delegate = self
        }
    }
    
    var timer = Timer()
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        remoteUserLabel.text = call?.remoteUserId

        audioController?.enableSpeaker()
        
        if call?.direction == SINCallDirection.incoming {
            let incomingSoundPath = Bundle.main.path(forResource: "incoming", ofType: "wav")
            audioController?.startPlayingSoundFile(incomingSoundPath, loop: true)
            answerCallButton.isHidden = false
        } else {
            let callingSoundPath = Bundle.main.path(forResource: "ringback", ofType: "wav")
            audioController?.startPlayingSoundFile(callingSoundPath, loop: true)
        }
        
        if call?.details.isVideoOffered == true {
            if let localView = videoController?.localView() {
                localVideoView.addSubview(localView)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer.invalidate()
    }
    
    // MARK: - SINCallDelegate
    
    func callDidAddVideoTrack(_ call: SINCall!) {
        guard let remoteView = videoController?.remoteView() else { return }
        remoteVideoView.addSubview(remoteView)
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
    }
    
    func callDidProgress(_ call: SINCall!) {
        print("++++++++ callDidProgress  ++++++++++")
    }
    
    func callDidEstablish(_ call: SINCall!) {
        // TODO: Maybe start timer here?
        print("++++++++ CALL DID ESTABLISH  ++++++++++")
        audioController?.stopPlayingSoundFile()
    }
    
    func callDidEnd(_ call: SINCall!) {
        audioController?.stopPlayingSoundFile()
        RootViewController.shared.popViewController()
    }
    
    func call(_ call: SINCall!, shouldSendPushNotifications pushPairs: [Any]!) {
        // TODO: not sure what this is for. maybe multiple accoutns on 1 device?
    }
    
    // MARK: - Actions
    
    @IBAction func answerCallButtonTapped() {
        answerCallButton.isHidden = true
        call?.answer()
    }
    
    @IBAction func cancelButtonTapped() {
        endCall()
    }
    
    // MARK: - Call Handling
    
    @objc func updateTime() {
        guard let timeRemainingString = timeRemainingLabel.text else { return }
        guard var timeRemaining = Int(timeRemainingString) else { return }
        timeRemaining = timeRemaining - 1
        timeRemainingLabel.text = String(timeRemaining)
        if timeRemaining == 0 {
            endCall()
        }
    }
    
    func endCall() {
        call?.hangup()
    }
}
