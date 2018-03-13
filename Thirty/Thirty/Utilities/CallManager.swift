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
    // CallKit components
    var callKitProvider: CXProvider?
    var callKitCallController = CXCallController()
    var callKitCompletionHandler: ((Bool)->Swift.Void?)? = nil
    /**
     * We will create an audio device and manage it's lifecycle in response to CallKit events.
     */
    var audioDevice: TVIDefaultAudioDevice = TVIDefaultAudioDevice()
    var call: Call?
    weak var delegate: CallManagerDelegate?
    
    func configure() {
        let configuration = CXProviderConfiguration(localizedName: "Incoming Thirty")
        configuration.maximumCallGroups = 1
        configuration.maximumCallsPerCallGroup = 1
        configuration.supportsVideo = true
        if let callKitIcon = UIImage(named: "callkitIcon") {
            configuration.iconTemplateImageData = UIImagePNGRepresentation(callKitIcon)
        }
        
        callKitProvider = CXProvider(configuration: configuration)
        callKitProvider!.setDelegate(self, queue: nil)
    }
    
    // MARK -
    
    func performStartCallAction(uuid: UUID, roomName: String?, completion: @escaping ((Error?) -> Void)) {
        let callHandle = CXHandle(type: .generic, value: roomName ?? "")
        let startCallAction = CXStartCallAction(call: uuid, handle: callHandle)
        startCallAction.isVideo = true
        let transaction = CXTransaction(action: startCallAction)
        callKitCallController.request(transaction)  { error in
            completion(error)
        }
    }
    
    func reportIncomingCall(uuid: UUID, roomName: String?, completion: ((Error?) -> Void)? = nil) {
        let callHandle = CXHandle(type: .generic, value: roomName ?? "")
        let callUpdate = CXCallUpdate()
        callUpdate.remoteHandle = callHandle
        callUpdate.supportsDTMF = false
        callUpdate.supportsHolding = true
        callUpdate.supportsGrouping = false
        callUpdate.supportsUngrouping = false
        callUpdate.hasVideo = true
        
        callKitProvider?.reportNewIncomingCall(with: uuid, update: callUpdate) { [weak self] error in
            if let error = error {
                print(error.localizedDescription)
            } else {
                self?.call = Call(uuid: uuid, roomName: roomName ?? "", direction: .incoming)
            }
            completion?(error)
        }
    }
    
    func performEndCallAction(uuid: UUID) {
        let endCallAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: endCallAction)
        callKitCallController.request(transaction) { [weak self] error in
            if let error = error {
                NSLog("EndCallAction transaction request failed: \(error.localizedDescription).")
                return
            }
            self?.call = nil
            NSLog("EndCallAction transaction request successful")
        }
    }
    
    // MARK: - CXProviderDelegate
    
    func providerDidReset(_ provider: CXProvider) {
        print("providerDidReset:")
        // AudioDevice is enabled by default
        audioDevice.isEnabled = true
        delegate?.callDidEnd()
    }
    
    func providerDidBegin(_ provider: CXProvider) {
        print("providerDidBegin")
    }
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("provider:didActivateAudioSession:")
        audioDevice.isEnabled = true
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("provider:didDeactivateAudioSession:")
    }
    
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        print("provider:timedOutPerformingAction:")
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

        // Configure the AVAudioSession by executign the audio device's `block`.
        self.audioDevice.block()
        callKitProvider?.reportOutgoingCall(with: action.callUUID, startedConnectingAt: nil)
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("provider:performAnswerCallAction:")
        
        /*
         * Configure the audio session, but do not start call audio here, since it must be done once
         * the audio session has been activated by the system after having its priority elevated.
         */
        
        // Stop the audio unit by setting isEnabled to `false`.
        audioDevice.isEnabled = false;
        // Configure the AVAudioSession by executing the audio device's `block`.
        audioDevice.block()
        RootViewController.shared.pushCallVC(calleeDeviceToken: nil, call: self.call)
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        NSLog("provider:performEndCallAction:")
        // AudioDevice is enabled by default
        audioDevice.isEnabled = true
        delegate?.callDidEnd()
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        NSLog("provier:performSetMutedCallAction:")
        // toggleMic(sender: self)
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
}
