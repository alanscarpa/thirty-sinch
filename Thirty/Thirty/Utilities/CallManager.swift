//
//  CallManager.swift
//  Thirty
//
//  Created by Alan Scarpa on 3/12/18.
//  Copyright © 2018 Thirty. All rights reserved.
//

import Foundation
import CallKit
import UIKit
import TwilioVideo

protocol CallManagerDelegate: class {
    func callDidEnd()
    func callIsOnHold(_ onHold: Bool)
}

class CallManager: NSObject, CXProviderDelegate {
    
    static let shared = CallManager()
    var call: Call?
    // CallKit components
    var callKitProvider: CXProvider?
    var callKitCallController = CXCallController()
    /**
     * We will create an audio device and manage it's lifecycle in response to CallKit events.
     */
    private var audioDevice: TVIDefaultAudioDevice = TVIDefaultAudioDevice()
    weak var delegate: CallManagerDelegate?
    private var ringbackAudioPlayer: AVAudioPlayer?
    private var synthesizer = AVSpeechSynthesizer()

    func configure() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, mode: AVAudioSessionModeVideoChat, options: [.mixWithOthers, .allowBluetooth, .defaultToSpeaker])
        } catch {
            print(error.localizedDescription)
        }
        
        let configuration = CXProviderConfiguration(localizedName: "Thirty")
        configuration.maximumCallGroups = 1
        configuration.maximumCallsPerCallGroup = 1
        configuration.supportsVideo = true
        configuration.supportedHandleTypes = [.generic]
        if let callKitIcon = UIImage(named: "callkitIcon") {
            configuration.iconTemplateImageData = UIImagePNGRepresentation(callKitIcon)
        }
        configuration.ringtoneSound = "ringtone.mp3"

        callKitProvider = CXProvider(configuration: configuration)
        callKitProvider?.setDelegate(self, queue: nil)
    }
    
    func setCallToActive(_ call: Call) {
        self.call = call
        self.call!.state = .active
    }
    
    func playRingbackTone() {
        let path = Bundle.main.path(forResource: "chill-ringback-quiet.m4a", ofType:nil)!
        let url = URL(fileURLWithPath: path)
        ringbackAudioPlayer = try? AVAudioPlayer(contentsOf: url)
        ringbackAudioPlayer?.numberOfLoops = -1
        ringbackAudioPlayer?.prepareToPlay()
        ringbackAudioPlayer?.play()
    }
    
    func playAnsweredTone() {
        stopRingbackTone()
        let path = Bundle.main.path(forResource: "answeredChime.wav", ofType: nil)!
        let url = URL(fileURLWithPath: path)
        ringbackAudioPlayer = try? AVAudioPlayer(contentsOf: url)
        ringbackAudioPlayer?.numberOfLoops = 0
        ringbackAudioPlayer?.prepareToPlay()
        ringbackAudioPlayer?.play()
    }
    
    func stopRingbackTone() {
        ringbackAudioPlayer?.stop()
        ringbackAudioPlayer?.currentTime = 0.0
    }
    
    func stopSiriAnswerInstructions() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    // MARK -
    
    func performStartCallAction(call: Call, completion: @escaping ((Error?) -> Void)) {
        self.call = call
        let callHandle = CXHandle(type: .generic, value: call.callee)
        let startCallAction = CXStartCallAction(call: call.uuid, handle: callHandle)
        startCallAction.isVideo = true
        let transaction = CXTransaction(action: startCallAction)
        if call.direction == .incoming {
            stopRingbackTone()
        }
        callKitCallController.request(transaction)  { error in
            completion(error)
        }
        
    }
    
    func performEndCallAction(uuid: UUID) {
        let endCallAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: endCallAction)
        callKitCallController.request(transaction) { error in
            if let error = error {
                print("EndCallAction transaction request failed: \(error.localizedDescription).")
                self.endCall()
            } else {
                print("EndCallAction transaction request successful")
            }
        }
    }
    
    func reportIncomingCall(_ call: Call, completion: @escaping ((Error?) -> Void)) {
        var handleValue = call.roomName
        if call.callerFullName.lowercased() != call.roomName.lowercased() {
            handleValue += " (\(call.callerFullName))"
        }
        let callHandle = CXHandle(type: .generic, value: handleValue)
        let callUpdate = CXCallUpdate()
        callUpdate.remoteHandle = callHandle
        callUpdate.supportsDTMF = false
        callUpdate.supportsHolding = false
        callUpdate.supportsGrouping = false
        callUpdate.supportsUngrouping = false
        callUpdate.hasVideo = true
        self.call = call
        callKitProvider?.reportNewIncomingCall(with: call.uuid, update: callUpdate) { [weak self] error in
            if let error = error {
                self?.endCall()
                print(error.localizedDescription)
            }
            completion(error)
        }
    }
    
    // MARK: - CXProviderDelegate
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        // THIS GETS CALLED ON SWIPE TO UNLOCK AND TAP TO ANSWER WHILE UNLOCKED
        print("provider:performAnswerCallAction:")
        /*
         * Configure the audio session, but do not start call audio here, since it must be done once
         * the audio session has been activated by the system after having its priority elevated.
         */
        
        // Stop the audio unit by setting isEnabled to `false`.
        audioDevice.isEnabled = false;
        // Configure the AVAudioSession by executing the audio device's `block`.
        audioDevice.block()

        if UIApplication.shared.applicationState == .background {
            // We used to send a local push to tell the user to tap the "Start 30" button but this was confusing.  Removing for now.
            // let appDelegate = UIApplication.shared.delegate as! AppDelegate
            // appDelegate.sendLocalNotification()
        }
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("provider:performStartCallAction:")
        
        /*
         * Configure the audio session, but do not start call audio here, since it must be done once
         * the audio session has been activated by the system after having its priority elevated.
         */
        
        // Stop the audio unit by setting isEnabled to `false`.
        audioDevice.isEnabled = false;
        
        // Configure the AVAudioSession by executing the audio device's `block`.
        audioDevice.block()
        call!.state = .active
        callKitProvider?.reportOutgoingCall(with: action.callUUID, startedConnectingAt: nil)
        UIApplication.shared.isIdleTimerDisabled = true
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        NSLog("provider:performEndCallAction:")
        if call?.state == .pending {
            FirebaseManager.shared.declineCall(call!)
        }
        endCall()
        if UIApplication.shared.applicationState == .background {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.removeLocalNotifications()
        }
        action.fulfill()
    }
    
    func providerDidReset(_ provider: CXProvider) {
        print("providerDidReset:")
        endCall()
    }
    
    func providerDidBegin(_ provider: CXProvider) {
        print("providerDidBegin")
    }
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("provider:didActivateAudioSession:")
        audioDevice.isEnabled = true
        if call?.direction == .outgoing {
            playRingbackTone()
        }
        if UIApplication.shared.applicationState == .background {
            synthesizer = AVSpeechSynthesizer()
            let utterance = AVSpeechUtterance(string: "Tap the \"Start 30\" button to begin.  It's in the bottom right corner.  Tap the \"Start 30\" button to get started.")
            utterance.rate = 0.48
            utterance.preUtteranceDelay = 1.5
            synthesizer.speak(utterance)
        }
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("provider:didDeactivateAudioSession:")
        stopRingbackTone()
    }
    
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        print("provider:timedOutPerformingAction:")
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        NSLog("provier:performSetMutedCallAction:")
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        NSLog("provier:performSetHeldCallAction:")
        let cxObserver = callKitCallController.callObserver
        let calls = cxObserver.calls
        guard let call = calls.first(where:{$0.uuid == action.callUUID}) else {
            action.fail()
            return
        }
        delegate?.callIsOnHold(!call.isOnHold)
        action.fulfill()
    }
    
    // MARK: - Helpers
    
    func endCall() {
        call = nil
        // AudioDevice is enabled by default
        audioDevice.isEnabled = true
        delegate?.callDidEnd()
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}
