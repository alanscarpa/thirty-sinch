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
    
    let audioController = SinchClientManager.shared.client?.audioController()
    let videoController = SinchClientManager.shared.client?.videoController()
    
    var call: SINCall? {
        didSet {
            call?.delegate = self
        }
    }
    
    var timer = Timer()
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if call?.direction == SINCallDirection.incoming {
            //audioController?.startPlayingSoundFile("incoming.wav", loop: true)
            answerCallButton.isHidden = false
        } else {
            // sending call
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        audioController?.enableSpeaker()
        remoteUserLabel.text = call?.remoteUserId
    }
    
    override func viewDidAppear(_ animated: Bool) {
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
    
    func callDidEstablish(_ call: SINCall!) {
        //timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
    }
    
    func callDidEnd(_ call: SINCall!) {
        RootViewController.shared.popViewController()
    }
    
    // MARK: - Actions
    
    @IBAction func answerCallButtonTapped() {
        answerCallButton.isHidden = true
        audioController?.stopPlayingSoundFile()
        call?.answer()
    }
    
    @IBAction func cancelButtonTapped() {
        endCall()
    }
    
    // MARK: - Call Handling
    
    func updateTime() {
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
