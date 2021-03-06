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

class CallViewController: UIViewController, TVIRoomDelegate, TVIRemoteParticipantDelegate, TVIVideoViewDelegate, TVICameraCapturerDelegate, CallManagerDelegate, FirebaseObserverDelegate {
    
    let simplePushURL = "https://php-ios.herokuapp.com/simplepush.php"
    
    @IBOutlet weak var remoteVideoView: TVIVideoView!
    @IBOutlet weak var localVideoView: TVIVideoView!
    @IBOutlet weak var remoteUserLabel: UILabel!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var callBackgroundImageView: UIImageView!
    @IBOutlet weak var remoteParticipantLabel: UILabel!
    
    let call: Call
    var timer = Timer()
    var outgoingCallRingingTimer = Timer()
    let timeRemainingLabelColor = UIColor.thPrimaryPurple.withAlphaComponent(0.5)
    let callTimeoutLength: Double = 45
    var callHasEnded = false

    var room: TVIRoom?
    var camera: TVICameraCapturer?
    var localAudioTrack = TVILocalAudioTrack()
    var localVideoTrack : TVILocalVideoTrack?
    var remoteParticipant: TVIRemoteParticipant?
    
    // MARK: Init
    
    init(call: Call) {
        self.call = call
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        CallManager.shared.setCallToActive(call)
        remoteVideoView.delegate = self
        CallManager.shared.delegate = self
        FirebaseManager.shared.delegate = self
        setUpUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        RootViewController.shared.showStatusBarBackground = false
        RootViewController.shared.showNavigationBar = false
        startLocalPreviewVideo()
        connectToRoom()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
            self.showCallSpinner()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer.invalidate()
        outgoingCallRingingTimer.invalidate()
    }
    
    // MARK: - Setup
    
    private func setUpUI() {
        view.backgroundColor = .thPrimaryPurple
        remoteVideoView.alpha = 0
        timeRemainingLabel.textColor = timeRemainingLabelColor
        cancelButton.alpha = 0.75
        remoteParticipantLabel.text = call.direction == .outgoing ? call.callee : call.caller
    }
    
    func prepareLocalMedia() {
        // We will share local audio and video when we connect to the Room.
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
        let parameters: Parameters = ["identity": UserManager.shared.currentUserUsername, "room": call.roomName]
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
    
    // MARK: - TVIRoomDelegate
    
    func didConnect(to room: TVIRoom) {
        print("Did connect to Room")
        if let localParticipant = room.localParticipant {
            print("Local identity \(localParticipant.identity)")
        }
        // The room now has 2 participants and we are good to go
        if room.remoteParticipants.count == 1 {
            // Only needed if calling simulator because it doesn't answer fully.
            remoteParticipant = room.remoteParticipants.first
            remoteParticipant?.delegate = self
        } else if let deviceToken = call.calleeDeviceToken {
            makeCallWithDeviceToken(deviceToken, toRoom: room)
        } else {
            FirebaseManager.shared.getDeviceTokenForUsername(call.callee) { [weak self] result in
                guard let strongSelf = self else { return }
                switch result {
                case .success(let token):
                    if token.isEmpty {
                        let alertVC = UIAlertController.createSimpleAlert(withTitle: "User has logged out of 30.", message: "Please try again later.") { action in
                            strongSelf.endCall()
                        }
                        strongSelf.present(alertVC, animated: true, completion: nil)
                    } else {
                        strongSelf.makeCallWithDeviceToken(token, toRoom: room)
                    }
                case .failure(let error):
                    let alertVC = UIAlertController.createSimpleAlert(withTitle: "User has logged out of 30.  Please try again later.", message: error.localizedDescription) { action in
                        strongSelf.endCall()
                    }
                    strongSelf.present(alertVC, animated: true, completion: nil)
                }
            }
        }
    }
    
    private func makeCallWithDeviceToken(_ deviceToken: String, toRoom room: TVIRoom) {
        FirebaseManager.shared.getBusyStatusForCall(call) { [weak self] calleeIsBusy in
            guard let strongSelf = self else { return }
            if calleeIsBusy {
                let alertVC = UIAlertController.createSimpleAlert(withTitle: "\(strongSelf.call.callee) is currently in another 30!", message: "Try again in about 30 seconds.  👍") { action in
                    strongSelf.endCall()
                }
                strongSelf.present(alertVC, animated: true, completion: nil)
            } else {
                FirebaseManager.shared.setBusyStatusForCall(strongSelf.call) { [weak self] result in
                    guard let strongSelf = self else { return }
                    switch result {
                    case .success:
                        FirebaseManager.shared.createCallStatusForCall(strongSelf.call) { [weak self] result in
                            guard let strongSelf = self else { return }
                            switch result {
                            case .success():
                                var parameters: Parameters = ["device_token": deviceToken, "room_name": strongSelf.call.roomName, "uuid_string": strongSelf.call.uuid.uuidString, "caller_full_name" : strongSelf.call.callerFullName]
                                #if DEBUG
                                parameters["dev"] = true
                                #endif
                                strongSelf.sendVOIPPush(parameters)
                            case .failure(let error):
                                let alertVC = UIAlertController.createSimpleAlert(withTitle: "Unable to create call on FB.", message: error.localizedDescription) { action in
                                    strongSelf.endCall()
                                }
                                strongSelf.present(alertVC, animated: true, completion: nil)
                            }
                        }
                    case .failure(let error):
                        let alertVC = UIAlertController.createSimpleAlert(withTitle: "Unable to set busy status for call.", message: error.localizedDescription) { action in
                            strongSelf.endCall()
                        }
                        strongSelf.present(alertVC, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    func sendVOIPPush(_ parameters: Parameters) {
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
                guard let strongSelf = self else { return }
                guard !strongSelf.callHasEnded else { return }
                CallManager.shared.performStartCallAction(call: strongSelf.call) { [weak self] error in
                    if let error = error {
                        let alertVC = UIAlertController.createSimpleAlert(withTitle: "Error", message: error.localizedDescription)  { action in
                            self?.endCall()
                        }
                        self?.present(alertVC, animated: true, completion: nil)
                    } else {
                        DispatchQueue.main.async {
                            strongSelf.outgoingCallRingingTimer = Timer.scheduledTimer(timeInterval: strongSelf.callTimeoutLength, target: strongSelf, selector: #selector(strongSelf.outgoingCallTimerFinished), userInfo: nil, repeats: false)
                        }
                    }
                }
            }
        }
    }
    
    func room(_ room: TVIRoom, didDisconnectWithError error: Error?) {
        print("Disconnected from room \(room.name)")
        endCall()
    }
    
    func room(_ room: TVIRoom, participantDidConnect participant: TVIRemoteParticipant) {
        if (remoteParticipant == nil) {
            remoteParticipant = participant
            remoteParticipant?.delegate = self
        }
        if call.direction == .outgoing {
            CallManager.shared.stopRingbackTone()
        }
        logMessage(messageText: "Participant \(participant.identity) connected with \(participant.remoteAudioTracks.count) audio and \(participant.remoteVideoTracks.count) video tracks")
    }
    
    func room(_ room: TVIRoom, didFailToConnectWithError error: Error) {
        print("Problem connectin to room: \(error.localizedDescription)")
        let alertVC = UIAlertController.createSimpleAlert(withTitle: "Problem Connecting to Chat", message: error.localizedDescription) { [weak self] action in
            self?.endCall()
        }
        present(alertVC, animated: true, completion: nil)
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
            endCall()
        }
    }
    
    // MARK: - TVIVideoViewDelegate
    
    func videoViewDidReceiveData(_ view: TVIVideoView) {
        // First frame has been rendered; only called once
        answerCall()
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
    
    // MARK: - FirebaseObserverDelegate
    
    func callWasDeclinedByCallee() {
        endCall()
    }
    
    // MARK: - Call Handling
    
    @objc func outgoingCallTimerFinished() {
        endCall()
    }
    
    func answerCall() {
        CallManager.shared.stopRingbackTone()
        outgoingCallRingingTimer.invalidate()
        THSpinner.dismiss()
        callBackgroundImageView.shake()
        if call.direction == .outgoing {
            CallManager.shared.playAnsweredTone()
        }
        UIView.animate(withDuration: 1.0, animations: { [weak self] in
            self?.remoteVideoView.alpha = 1
        }) { [weak self] complete in
            if complete {
                guard let strongSelf = self else { return }
                FirebaseManager.shared.answeredCallWithRoomName(strongSelf.call.roomName)
                strongSelf.remoteParticipantLabel.isHidden = true
                strongSelf.callBackgroundImageView.explode(.chaos, duration: 2)
                strongSelf.timer = Timer.scheduledTimer(timeInterval: 1.0, target: strongSelf, selector: #selector(strongSelf.updateTime), userInfo: nil, repeats: true)
            }
        }
    }
    
    @objc func updateTime() {
        guard let timeRemainingString = timeRemainingLabel.text else { return }
        guard var timeRemaining = Int(timeRemainingString) else { return }
        timeRemaining = timeRemaining - 1
        timeRemainingLabel.text = String(timeRemaining)
        if timeRemaining <= 10, timeRemaining > 0 {
            countdownAnimation()
        }
        if timeRemaining == 0 {
            timer.invalidate()
            endCall()
        }
    }
    
    private func countdownAnimation() {
        timeRemainingLabel.textColor = UIColor.red.withAlphaComponent(0.75)
        let duration = 1.0
        let delay = 0.0
        let options: UIViewKeyframeAnimationOptions = [.calculationModeLinear, .repeat]
        UIView.animateKeyframes(withDuration: duration, delay: delay, options: options, animations: { [weak self] in
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5, animations: {
                self?.timeRemainingLabel.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            })
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5, animations: {
                self?.timeRemainingLabel.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            })
        })
    }
    
    func endCall() {
        if !callHasEnded {
            callHasEnded = true
            THSpinner.dismiss()
            room?.disconnect()
            CallManager.shared.performEndCallAction(uuid: call.uuid)
            FirebaseManager.shared.removeBusyStatusForCall(call)
            FirebaseManager.shared.endCallWithRoomName(call.roomName)
            dismiss(animated: true, completion: nil)
            CallManager.shared.stopRingbackTone()
        }
    }
    
    // MARK: - Actions
    
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
    
    private func defaultConnectOptionsWithAccessToken(_ accessToken: String) -> TVIConnectOptions {
        let connectOptions = TVIConnectOptions.init(token: accessToken) { [weak self] builder in
            builder.roomName = self?.call.roomName
            builder.uuid = self?.call.uuid
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
    
    func holdCall(onHold: Bool) {
        localAudioTrack?.isEnabled = !onHold
        localVideoTrack?.isEnabled = !onHold
    }
    
    func logMessage(messageText: String) {
        NSLog(messageText)
    }
    
    func showCallSpinner() {
        let spinnerText: String? = call.direction == .incoming ? "CONNECTING" : "CALLING"
        THSpinner.showSpinnerOnView(view, text: spinnerText, preventUserInteraction: false)
    }
    
}
