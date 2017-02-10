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
    
    let audioController = SinchClientManager.shared.client?.audioController()
    let videoController = SinchClientManager.shared.client?.videoController()
    
    var call: SINCall? {
        didSet {
            call?.delegate = self
        }
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if call?.direction == SINCallDirection.incoming {
            //audioController?.startPlayingSoundFile("incoming.wav", loop: true)
            answerCallButton.isHidden = false
        } else {
            // sending call
        }
        
//        if call?.details.isVideoOffered == true {
//            if let localView = videoController?.localView() {
//                localVideoView.addSubview(localView)
//            }
//        }
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

    // MARK: - SINCallDelegate
    
    func callDidAddVideoTrack(_ call: SINCall!) {
        guard let remoteView = videoController?.remoteView() else { return }
        remoteVideoView.addSubview(remoteView)
    }
    
    // MARK: - Actions
    
    @IBAction func answerCallButtonTapped() {
        answerCallButton.isHidden = true
        audioController?.stopPlayingSoundFile()
        call?.answer()
    }
}
