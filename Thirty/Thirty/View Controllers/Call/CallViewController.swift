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
import JHSpinner

class CallViewController: UIViewController, TVIRoomDelegate, TVIRemoteParticipantDelegate, TVIVideoViewDelegate, TVICameraCapturerDelegate, CallManagerDelegate {
    
    let simplePushURL = "https://php-ios.herokuapp.com/simplepush.php"
    
    @IBOutlet weak var remoteVideoView: TVIVideoView!
    @IBOutlet weak var localVideoView: TVIVideoView!
    @IBOutlet weak var remoteUserLabel: UILabel!
    @IBOutlet weak var answerCallButton: UIButton!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    
    // This will also be the room name
    var calleeDeviceToken = ""
    var call: Call?
    // TODO: Fix this - incorporate into call.  This is quick lazy fix.
    let defaultUUUID = UUID()
    var uuid: UUID {
        return call?.uuid ?? defaultUUUID
    }
    var roomName: String {
        return call?.direction == .incoming ? call!.roomName : UserManager.shared.currentUserUsername!
    }
    var timer = Timer()
    var callHasEnded = false
    /**
     * We will create an audio device and manage it's lifecycle in response to CallKit events.
     */
    var room: TVIRoom?
    var camera: TVICameraCapturer?
    // Create an audio track
    var localAudioTrack = TVILocalAudioTrack()
    // Create a Capturer to provide content for the video track
    var localVideoTrack : TVILocalVideoTrack?
    var remoteParticipant: TVIRemoteParticipant?

    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        remoteVideoView.delegate = self
        remoteVideoView.alpha = 0
        CallManager.shared.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startLocalPreviewVideo()
        connectToRoom()
        let spinnerText: String? = call?.direction == .incoming ? nil : "CALLING"
        THSpinner.showSpinnerOnView(view, text: spinnerText, preventUserInteraction: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer.invalidate()
    }
    
    // MARK: - Setup
    
    func prepareLocalMedia() {
        // We will share local audio and video when we connect to the Room.
        
        // Create an audio track.
        if (localAudioTrack == nil) {
            localAudioTrack = TVILocalAudioTrack.init()
            
            if (localAudioTrack == nil) {
                logMessage(messageText: "Failed to create audio track")
            }
        }
        
        // Create a video track which captures from the camera.
        if (localVideoTrack == nil) {
            self.startLocalPreviewVideo()
        }
    }
    
    private func startLocalPreviewVideo() {
        // Create a video track with the capturer.
        if let camera = TVICameraCapturer(source: .frontCamera),
            let videoTrack = TVILocalVideoTrack(capturer: camera) {
            videoTrack.addRenderer(localVideoView)
            localVideoTrack = videoTrack
            self.camera = camera
            self.camera?.delegate = self
            localVideoView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.flipCamera)))
        } else {
            print("Couldn't create TVICameraCapturer or TVILocalVideoTrack")
        }
    }
    
    private func connectToRoom() {
        let currentUsername = UserManager.shared.currentUserUsername!
        let parameters: Parameters = ["identity": currentUsername, "room": roomName]
        // Generate access token
        Alamofire.request(TokenUtils.tokenGeneratorAddress, parameters: parameters).validate().response { [weak self] response in
            if let error = response.error {
                let alertVC = UIAlertController.createSimpleAlert(withTitle: "Error", message: "Unable to generate access token.  \(error.localizedDescription)") { action in
                    self?.endCall()
                }
                self?.present(alertVC, animated: true, completion: nil)
            } else if let data = response.data, let accessToken = String(data: data, encoding: .utf8) {
                // Create room and connect
                TokenUtils.accessToken = accessToken
                let connectOptions = self?.defaultConnectOptionsWithAccessToken(accessToken)
                self?.room = TwilioVideo.connect(with: connectOptions!, delegate: self)
            }
        }
    }
    
    private func defaultConnectOptionsWithAccessToken(_ accessToken: String) -> TVIConnectOptions {
        let connectOptions = TVIConnectOptions.init(token: accessToken) { [weak self] builder in
            builder.roomName = self?.call?.roomName
            builder.uuid = self?.uuid
            // Will share audio with users in room
            if let audioTrack = self?.localAudioTrack {
                builder.audioTracks = [audioTrack]
            }
            // Will share video with users in room
            if let videoTrack = self?.localVideoTrack {
                builder.videoTracks = [videoTrack]
            }
        }
        return connectOptions
    }
    
    // MARK: - TVIRoomDelegate
    
    func didConnect(to room: TVIRoom) {
        print("Did connect to Room")
        if let localParticipant = room.localParticipant {
            print("Local identity \(localParticipant.identity)")
        }
        // The room now has 2 participants and we are good to go
        if room.remoteParticipants.count == 1 {
            remoteParticipant = room.remoteParticipants.first
            remoteParticipant?.delegate = self
        } else {
            if !calleeDeviceToken.isEmpty {
                makeCallWithDeviceToken(calleeDeviceToken, toRoom: room)
            } else {
                FirebaseManager.shared.getDeviceTokenForUsername(call!.callee) { [weak self] result in
                    guard let strongSelf = self else { return }
                    switch result {
                    case .Success(let token):
                        strongSelf.calleeDeviceToken = token
                        strongSelf.makeCallWithDeviceToken(token, toRoom: room)
                    case .Failure(let error):
                        let alertVC = UIAlertController.createSimpleAlert(withTitle: "Error", message: error.localizedDescription) { action in
                            strongSelf.endCall()
                        }
                        strongSelf.present(alertVC, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    private func makeCallWithDeviceToken(_ deviceToken: String, toRoom room: TVIRoom) {
        var parameters: Parameters = ["device_token": deviceToken, "room_name": roomName, "uuid_string": uuid.uuidString]
        #if DEBUG
            parameters["dev"] = true
        #endif
        // Send voIP Push
        Alamofire.request(simplePushURL, method: .post, parameters: parameters).validate().response { [weak self] response in
            guard let strongSelf = self else { print("Self not available"); return }
            if let error = response.error {
                let alertVC = UIAlertController.createSimpleAlert(withTitle: "Error", message: "Unable to send call request.  \(error.localizedDescription)") { action in
                    strongSelf.endCall()
                }
                strongSelf.present(alertVC, animated: true, completion: nil)
            } else {
                print("successfully sent voIP push")
                CallManager.shared.performStartCallAction(uuid: strongSelf.uuid, calleeHandle: strongSelf.call!.callee) { [weak self] error in
                    if let error = error {
                        let alertVC = UIAlertController.createSimpleAlert(withTitle: "Error", message: error.localizedDescription)  { action in
                            strongSelf.endCall()
                        }
                        self?.present(alertVC, animated: true, completion: nil)
                    } else {
                        CallManager.shared.callKitCompletionHandler?(true)
                    }
                }
            }
        }
    }
    
    func room(_ room: TVIRoom, didDisconnectWithError error: Error?) {
        print("Disconnected from room \(room.name)")
        CallManager.shared.callKitCompletionHandler = nil
        endCall()
    }
    
    func room(_ room: TVIRoom, participantDidConnect participant: TVIRemoteParticipant) {
        if (self.remoteParticipant == nil) {
            self.remoteParticipant = participant
            self.remoteParticipant?.delegate = self
        }
        logMessage(messageText: "Participant \(participant.identity) connected with \(participant.remoteAudioTracks.count) audio and \(participant.remoteVideoTracks.count) video tracks")
    }
    
    func room(_ room: TVIRoom, didFailToConnectWithError error: Error) {
        let alertVC = UIAlertController.createSimpleAlert(withTitle: "Problem Connecting to Chat", message: error.localizedDescription) { [weak self] action in
            self?.endCall()
        }
        present(alertVC, animated: true, completion: nil)
        CallManager.shared.callKitCompletionHandler?(false)
    }
    
    func room(_ room: TVIRoom, participantDidDisconnect participant: TVIRemoteParticipant) {
        logMessage(messageText: "Room \(room.name), Participant \(participant.identity) disconnected")
        endCall()
    }
    
    // MARK: - TVIRemoteParticipantDelegate
    
    func subscribed(to videoTrack: TVIRemoteVideoTrack,
                    publication: TVIRemoteVideoTrackPublication,
                    for participant: TVIRemoteParticipant) {
        
        // We are subscribed to the remote Participant's video Track. We will start receiving the
        // remote Participant's video frames now.
        
        logMessage(messageText: "Subscribed to video track for Participant \(participant.identity)")
        
        if (remoteParticipant == participant) {
            videoTrack.addRenderer(remoteVideoView)
        }
    }
    
    func unsubscribed(from videoTrack: TVIRemoteVideoTrack,
                      publication: TVIRemoteVideoTrackPublication,
                      for participant: TVIRemoteParticipant) {
        
        // We are unsubscribed from the remote Participant's video Track. We will no longer receive the
        // remote Participant's video.
        
        logMessage(messageText: "Unsubscribed from video track for Participant \(participant.identity)")
        
        if (remoteParticipant == participant) {
            videoTrack.removeRenderer(remoteVideoView)
            remoteVideoView.removeFromSuperview()
            endCall()
        }
    }
    
    // MARK: - TVIVideoViewDelegate
    
    func videoViewDidReceiveData(_ view: TVIVideoView) {
        // First frame has been rendered; this prevents the brief black screen that appears first and is only called once
        answerCall()
        UIView.animate(withDuration: 2.0) {
            self.remoteVideoView.alpha = 1
        }
    }
        
    func videoView(_ view: TVIVideoView, videoDimensionsDidChange dimensions: CMVideoDimensions) {
        print("The dimensions of the video track changed to: \(dimensions.width)x\(dimensions.height)")
        self.view.setNeedsLayout()
    }
    
    // MARK: - TVICameraCapturerDelegate
    
    func cameraCapturer(_ capturer: TVICameraCapturer, didStartWith source: TVICameraCaptureSource) {
        localVideoView.shouldMirror = (source == .frontCamera)
    }
    
    // MARK: - Call Manager Delegate
    
    func callDidEnd() {
        endCall()
    }
    
    func callIsOnHold(_ onHold: Bool) {
        holdCall(onHold: onHold)
    }
    
    // MARK: - Call Handling
    
    func answerCall() {
        THSpinner.dismiss()
        answerCallButton.isHidden = true
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
    }
    
    @objc func updateTime() {
        guard let timeRemainingString = timeRemainingLabel.text else { return }
        guard var timeRemaining = Int(timeRemainingString) else { return }
        timeRemaining = timeRemaining - 1
        timeRemainingLabel.text = String(timeRemaining)
        if timeRemaining == 0 {
            timer.invalidate()
            endCall()
        }
    }
    
    func endCall() {
        if !callHasEnded {
            callHasEnded = true
            THSpinner.dismiss()
            room?.disconnect()
            RootViewController.shared.popViewController()
            CallManager.shared.performEndCallAction(uuid: uuid)
        }
    }
    
    // MARK: - Actions
    
    @IBAction func answerCallButtonTapped() {
        answerCall()
    }
    
    @IBAction func cancelButtonTapped() {
        endCall()
    }
    
    @objc func flipCamera() {
        if let camera = camera {
            if (camera.source == .frontCamera) {
                camera.selectSource(.backCameraWide)
            } else {
                camera.selectSource(.frontCamera)
            }
        }
    }
    
    // MARK: - Helpers
    
    func holdCall(onHold: Bool) {
        localAudioTrack?.isEnabled = !onHold
        localVideoTrack?.isEnabled = !onHold
    }
    
    func logMessage(messageText: String) {
        NSLog(messageText)
    }
    
}
