//
//  CallViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/9/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit
import TwilioVideo
import CallKit
import Alamofire

class CallViewController: UIViewController, TVIRoomDelegate, TVIParticipantDelegate, TVIVideoViewDelegate {

    @IBOutlet weak var remoteVideoView: UIView!
    @IBOutlet weak var localVideoView: UIView!
    @IBOutlet weak var remoteUserLabel: UILabel!
    @IBOutlet weak var answerCallButton: UIButton!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    
    // This will be the room name
    var caller = ""
    var timer = Timer()
    
    /**
     * We will create an audio device and manage it's lifecycle in response to CallKit events.
     */

    var room: TVIRoom?
    var camera: TVICameraCapturer?
    
    // Create an audio track
    var localAudioTrack = TVILocalAudioTrack()
    
    // Create a Capturer to provide content for the video track
    var localVideoTrack : TVILocalVideoTrack?
    
    var remoteParticipant: TVIParticipant?
    var remoteView: TVIVideoView?

    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Create a video track with the capturer.
        if let camera = TVICameraCapturer(source: .frontCamera),
            let videoTrack = TVILocalVideoTrack(capturer: camera) {
            // TVIVideoView is a TVIVideoRenderer and can be added to any TVIVideoTrack.
            let renderer = TVIVideoView(frame: CGRect(x: localVideoView.frame.origin.x, y: localVideoView.frame.origin.y - 25, width: 350, height: 300))
            renderer.contentMode = .scaleAspectFit
            // Add renderer to the video track
            videoTrack.addRenderer(renderer)
            self.localVideoTrack = videoTrack
            self.camera = camera
            self.view.addSubview(renderer)
            renderer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.flipCamera)))
        } else {
            print("Couldn't create TVICameraCapturer or TVILocalVideoTrack")
        }
        
        let parameters: Parameters = ["identity": UserManager.shared.currentUserUsername!, "room": caller]
        Alamofire.request("https://php-ios.herokuapp.com/token.php", parameters: parameters).response { [weak self] response in
            if let data = response.data, let accessToken = String(data: data, encoding: .utf8) {
                // Create room
                let connectOptions = TVIConnectOptions.init(token: accessToken) { [weak self] builder in
                    builder.roomName = self?.caller
                    // Will share audio with users in room
                    if let audioTrack = self?.localAudioTrack {
                        builder.audioTracks = [audioTrack]
                    }
                    // Will share video with users in room
                    if let videoTrack = self?.localVideoTrack {
                        builder.videoTracks = [videoTrack]
                    }
                }
                self?.room = TwilioVideo.connect(with: connectOptions, delegate: self)
            }
        }

        
    }
    
    // MARK: - TVIRoomDelegate
    
    func didConnect(to room: TVIRoom) {
        print("Did connect to Room")
        // The Local Participant
        if let localParticipant = room.localParticipant {
            print("Local identity \(localParticipant.identity)")
        }
        
        // Connected participants
        let participants = room.participants;
        print("Number of connected Participants \(participants.count)")
    }
    
    
    func room(_ room: TVIRoom, didDisconnectWithError error: Error?) {
        print("Disconnected from room \(room.name)")
    }
    
    func room(_ room: TVIRoom, participantDidConnect participant: TVIParticipant) {
        print ("Participant \(participant.identity) has joined Room \(room.name)")
        participant.delegate = self
        answerCall()
    }
    
    func room(_ room: TVIRoom, participantDidDisconnect participant: TVIParticipant) {
        print ("Participant \(participant.identity) has left Room \(room.name)")
        endCall()
    }
    
    // MARK: - TVIParticipantDelegate
    
    /*
     * In the Participant Delegate, we can respond when the Participant adds a Video
     * Track by rendering it on screen.
     */
    
    func participant(_ participant: TVIParticipant, addedVideoTrack videoTrack: TVIVideoTrack) {
        print("Participant \(participant.identity) added video track")
        remoteView = TVIVideoView(frame: self.view.bounds, delegate: self)
        videoTrack.addRenderer(remoteView!)
        view.addSubview(remoteView!)
    }
    
    func participant(_ participant: TVIParticipant, addedAudioTrack audioTrack: TVIAudioTrack) {
        //
    }
    
    // MARK: - TVIVideoViewDelegate
    
    // Lastly, we can subscribe to important events on the VideoView
    func videoView(_ view: TVIVideoView, videoDimensionsDidChange dimensions: CMVideoDimensions) {
        print("The dimensions of the video track changed to: \(dimensions.width)x\(dimensions.height)")
        self.view.setNeedsLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func answerCall() {
        answerCallButton.isHidden = true
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer.invalidate()
    }
    
    // MARK: - Actions
    
    @IBAction func answerCallButtonTapped() {
        answerCall()
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
        // To disconnect from a Room, we call:
        room?.disconnect()
        RootViewController.shared.popViewController()
    }
    
    // Select between the front and (wide) back camera.
    @objc func flipCamera() {
        if let camera = camera {
            if (camera.source == .frontCamera) {
                camera.selectSource(.backCameraWide)
            } else {
                camera.selectSource(.frontCamera)
            }
        }
    }
}
