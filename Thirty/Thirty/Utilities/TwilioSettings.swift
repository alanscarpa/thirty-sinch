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
    
    let supportedAudioCodecs: [TVIAudioCodec] = [TVIG722Codec.init(),
                                TVIIsacCodec.init(),
                                TVIOpusCodec.init(),
                                TVIPcmaCodec.init(),
                                TVIPcmuCodec.init()]
    
    let supportedVideoCodecs: [TVIVideoCodec] = [TVIH264Codec.init(),
                                TVIVp8Codec.init(),
                                TVIVp9Codec.init()]
    
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
