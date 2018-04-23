//
//  CameraMicrophoneTipViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 4/22/18.
//  Copyright © 2018 Thirty. All rights reserved.
//

import UIKit
import AVFoundation
import SCLAlertView

class CameraMicrophoneTipViewController: UIViewController {

    var permissionsCompletion: ((Bool) -> Void)!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func enablePermissionsButtonTapped() {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { granted in
            if granted {
                AVAudioSession.sharedInstance().requestRecordPermission({ granted in
                    DispatchQueue.main.async {
                        if !granted {
                            SCLAlertView().showError("Please enable microphone permission", subTitle: "You won't be able to 30 unlesss you enable microphone permissions.  Go to Settings > Privacy > Microphone and please enable.", colorStyle: UIColor.thPrimaryPurple.toHex())
                        }
                        self.dismiss(animated: true) {
                            self.permissionsCompletion(granted)
                        }
                    }
                })
            } else {
                DispatchQueue.main.async {
                    SCLAlertView().showError("Please enable video permission", subTitle: "You won't be able to  30 unlesss you enable video permissions.  Go to Settings > Privacy > Camera and please enable.", colorStyle: UIColor.thPrimaryPurple.toHex())
                    self.dismiss(animated: true) {
                        self.permissionsCompletion(granted)
                    }
                }
            }
        }
    }

}
