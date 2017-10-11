//
//  ProviderDelegate.swift
//  Thirty
//
//  Created by Alan Scarpa on 10/3/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import AVFoundation
import CallKit

class ProviderDelegate: NSObject {
    
    fileprivate let callManager: CallManager
    fileprivate let provider: CXProvider
    
    init(callManager: CallManager) {
        self.callManager = callManager
        provider = CXProvider(configuration: type(of: self).providerConfiguration)
        super.init()
        provider.setDelegate(self, queue: nil)
    }
    
    static var providerConfiguration: CXProviderConfiguration {
        let providerConfiguration = CXProviderConfiguration(localizedName: "30")
        providerConfiguration.supportsVideo = true
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.supportedHandleTypes = [.generic]
        return providerConfiguration
    }
    
    func reportIncomingCall(uuid: UUID, handle: String, completion: ((NSError?) -> Void)?) {
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: handle)
        update.hasVideo = true
        provider.reportNewIncomingCall(with: uuid, update: update) { error in
            if error == nil {
                let call = Call(uuid: uuid, handle: handle)
                self.callManager.add(call: call)
            }
            completion?(error as NSError?)
        }
    }
}

extension ProviderDelegate: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        for call in callManager.calls {
            call.end()
        }
        callManager.removeAllCalls()
    }
    
    func providerDidBegin(_ provider: CXProvider) {
        print("beginning provider!")
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("tapped answer button")
        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        call.answer()
        action.fulfill()
        
        let transaction = CXTransaction(action: CXEndCallAction(call: action.callUUID))
        callManager.requestTransaction(transaction)
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("tapped end button")
        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        call.end()
        action.fulfill()
        callManager.remove(call: call)
    }
}
