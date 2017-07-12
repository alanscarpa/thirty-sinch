//
//  JHSpinnerView+Thirty.swift
//  Thirty
//
//  Created by Alan Scarpa on 6/29/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import JHSpinner

class THSpinner {
    static let shared = THSpinner()
    private var jhSpinner: JHSpinnerView?
    
    private init() {}
    
    class func showSpinnerOnView(_ view: UIView) {
        shared.jhSpinner = JHSpinnerView.showOnView(view, spinnerColor: UIColor.thPrimaryPurple, overlay:.circular, overlayColor: UIColor.thBlack.withAlphaComponent(0.6))
        guard let spinner = shared.jhSpinner else { return }
        view.addSubview(spinner)
    }

    class func dismiss() {
        guard let spinner = shared.jhSpinner else { return }
        spinner.dismiss()
    }
}
