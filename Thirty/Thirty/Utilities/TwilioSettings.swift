//
//  TwilioSettings.swift
//  Thirty
//
//  Created by Alan Scarpa on 3/8/18.
//  Copyright © 2018 Thirty. All rights reserved.
//

import Foundation
import TwilioVideo

class TwilioSettings: NSObject {
    
    let supportedAudioCodecs = [TVIAudioCodec.ISAC,
                                TVIAudioCodec.opus,
                                TVIAudioCodec.PCMA,
                                TVIAudioCodec.PCMU,
                                TVIAudioCodec.G722]
    
    let supportedVideoCodecs = [TVIVideoCodec.VP8,
                                TVIVideoCodec.H264,
                                TVIVideoCodec.VP9]
    
    var audioCodec: TVIAudioCodec?
    var videoCodec: TVIVideoCodec?
    
    var maxAudioBitrate = UInt()
    var maxVideoBitrate = UInt()
    
    func getEncodingParameters() -> TVIEncodingParameters?  {
        if maxAudioBitrate == 0 && maxVideoBitrate == 0 {
            return nil;
        } else {
            return TVIEncodingParameters(audioBitrate: maxAudioBitrate,
                                         videoBitrate: maxVideoBitrate)
        }
    }
    
    private override init() {
        // Can't initialize a singleton
    }
    
    // MARK: Shared Instance
    static let shared = TwilioSettings()
}
