//
//  TokenUtils.swift
//  Thirty
//
//  Created by Alan Scarpa on 3/8/18.
//  Copyright © 2018 Thirty. All rights reserved.
//

import Foundation

struct TokenUtils {
    static var deviceToken = ""
    static var accessToken = ""
    static var tokenGeneratorAddress = "https://php-ios.herokuapp.com/token.php"
    static func fetchTwilioToken(url : String) throws -> String {
        var token = ""
        let requestURL: URL = URL(string: url)!
        do {
            let data = try Data(contentsOf: requestURL)
            if let tokenReponse = String.init(data: data, encoding: String.Encoding.utf8) {
                token = tokenReponse
            }
        } catch let error as NSError {
            print ("Invalid token url, error = \(error)")
            throw error
        }
        return token
    }
}
