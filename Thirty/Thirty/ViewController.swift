//
//  ViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/8/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit

// TODO: this should probably not be sinclientdelegate since it is a singleton
class ViewController: UIViewController, SINClientDelegate, SINCallClientDelegate {

    let isAlan = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeSinchClient()
    }

    func initializeSinchClient() {
        SinchClientManager.shared.client = Sinch.client(withApplicationKey: SinchAppKey, applicationSecret: SinchSecret, environmentHost: SinchEnvHost, userId: isAlan ? "alan" : "sean")
        SinchClientManager.shared.client?.delegate = self
        SinchClientManager.shared.client?.setSupportCalling(true)
        SinchClientManager.shared.client?.enableManagedPushNotifications()
        SinchClientManager.shared.client?.start()
        SinchClientManager.shared.client?.startListeningOnActiveConnection()
        SinchClientManager.shared.client?.call().delegate = self
    }
    
    // MARK: - SINClientDelegate
    
    func clientDidStart(_ client: SINClient!) {
        print("Sinch client started.")
    }
    
    func clientDidFail(_ client: SINClient!, error: Error!) {
        print("Sinch client failed!")
    }
    
    // MARK: - SINCallClientDelegate
    
    func client(_ client: SINCallClient!, didReceiveIncomingCall call: SINCall!) {
        performSegue(withIdentifier: "callView", sender: call)
    }

    // MARK: - Actions
    
    @IBAction func callButtonTapped() {
        if SinchClientManager.shared.client?.isStarted() == true {
            let call = SinchClientManager.shared.client?.call().callUserVideo(withId: isAlan ? "sean" : "alan")
            performSegue(withIdentifier: "callView", sender: call)
        }
    }
    
    
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let callViewController = segue.destination as! CallViewController
        callViewController.call = sender as! SINCall?
     }

}

