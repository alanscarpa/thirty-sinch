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
    weak var delegate: CallManagerDelegate?
    
    func configure() {
        let configuration = CXProviderConfiguration(localizedName: "THIRTY")
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
    
    func reportIncomingCall(uuid: UUID, roomName: String?, completion: ((NSError?) -> Void)? = nil) {
        let callHandle = CXHandle(type: .generic, value: roomName ?? "")
        let callUpdate = CXCallUpdate()
        callUpdate.remoteHandle = callHandle
        callUpdate.supportsDTMF = false
        callUpdate.supportsHolding = true
        callUpdate.supportsGrouping = false
        callUpdate.supportsUngrouping = false
        callUpdate.hasVideo = true
        
        callKitProvider?.reportNewIncomingCall(with: uuid, update: callUpdate) { error in
            if error == nil {
                NSLog("Incoming call successfully reported.")
            } else {
                NSLog("Failed to report incoming call successfully: \(String(describing: error?.localizedDescription)).")
            }
            completion?(error as NSError?)
        }
    }
    
    func performEndCallAction(uuid: UUID) {
        let endCallAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: endCallAction)
        
        callKitCallController.request(transaction) { error in
            if let error = error {
                NSLog("EndCallAction transaction request failed: \(error.localizedDescription).")
                return
            }
            
            NSLog("EndCallAction transaction request successful")
        }
    }
    
    func performRoomConnect(uuid: UUID, roomName: String? , completionHandler: @escaping (Bool) -> Swift.Void) {
        print("perform room connect")
        // Configure access token either from server or manually.
        // If the default wasn't changed, try fetching from server.
//        if TokenUtils.accessToken.isEmpty {
//            do {
//                TokenUtils.accessToken = try TokenUtils.fetchToken(url: TokenUtils.tokenGeneratorAddress)
//            } catch {
//                let message = "Failed to fetch access token"
//                print(message)
//                return
//            }
//        }
//
//        // Prepare local media which we will share with Room Participants.
//        self.prepareLocalMedia()
//
//        // Preparing the connect options with the access token that we fetched (or hardcoded).
//        let connectOptions = TVIConnectOptions.init(token: TokenUtils.accessToken) { (builder) in
//            // Use the local media that we prepared earlier.
//            builder.audioTracks = self.localAudioTrack != nil ? [self.localAudioTrack!] : [TVILocalAudioTrack]()
//            builder.videoTracks = self.localVideoTrack != nil ? [self.localVideoTrack!] : [TVILocalVideoTrack]()
//
//            // Use the preferred audio codec
//            if let preferredAudioCodec = TwilioSettings.shared.audioCodec {
//                builder.preferredAudioCodecs = [preferredAudioCodec.rawValue]
//            }
//
//            // Use the preferred video codec
//            if let preferredVideoCodec = TwilioSettings.shared.videoCodec {
//                builder.preferredVideoCodecs = [preferredVideoCodec.rawValue]
//            }
//
//            // Use the preferred encoding parameters
//            if let encodingParameters = TwilioSettings.shared.getEncodingParameters() {
//                builder.encodingParameters = encodingParameters
//            }
//
//            // The name of the Room where the Client will attempt to connect to. Please note that if you pass an empty
//            // Room `name`, the Client will create one for you. You can get the name or sid from any connected Room.
//            builder.roomName = roomName
//
//            // The CallKit UUID to assoicate with this Room.
//            builder.uuid = uuid
//        }
//
//        // Connect to the Room using the options we provided.
//        room = TwilioVideo.connect(with: connectOptions, delegate: self)
//
//        print("Attempting to connect to room \(String(describing: roomName))")
//
//        callKitCompletionHandler = completionHandler
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
        performRoomConnect(uuid: action.callUUID, roomName: action.handle.value) { (success) in
            if (success) {
                provider.reportOutgoingCall(with: action.callUUID, connectedAt: Date())
                action.fulfill()
            } else {
                action.fail()
            }
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("provider:performAnswerCallAction:")
        
        /*
         * Configure the audio session, but do not start call audio here, since it must be done once
         * the audio session has been activated by the system after having its priority elevated.
         */
        
        // Stop the audio unit by setting isEnabled to `false`.
        audioDevice.isEnabled = false;
//
//        // Configure the AVAudioSession by executign the audio device's `block`.
        audioDevice.block()
//
//        performRoomConnect(uuid: action.callUUID, roomName: roomName) { (success) in
//            if (success) {
//                action.fulfill(withDateConnected: Date())
//            } else {
//                action.fail()
//            }
//        }
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
