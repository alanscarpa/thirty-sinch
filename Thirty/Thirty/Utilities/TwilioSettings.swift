//
//  TwilioSettings.swift
//  Thirty
//
//  Created by Alan Scarpa on 3/8/18.
//  Copyright © 2018 Thirty. All rights reserved.
//

import Foundation
import TwilioVideo

class TwilioSettings {
    static let shared = TwilioSettings()
    private init() { }

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
    
    var maxAudioBitrate: UInt = 0
    var maxVideoBitrate: UInt = 0
    
    func getEncodingParameters() -> TVIEncodingParameters?  {
        guard maxAudioBitrate > 0, maxVideoBitrate > 0 else { return nil }
        return TVIEncodingParameters(audioBitrate: maxAudioBitrate,
                                     videoBitrate: maxVideoBitrate)
    }
}
