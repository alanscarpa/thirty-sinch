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
    
    class func showSpinnerOnView(_ view: UIView, text: String? = nil, preventUserInteraction: Bool = true) {
        shared.jhSpinner = JHSpinnerView.showOnView(view, spinnerColor: .thPrimaryPurple, overlay:.custom(CGSize(width: 200, height: 200), 100), overlayColor: UIColor.thSecondaryPurple, text: text, textColor: .thPrimaryPurple)
        guard let spinner = shared.jhSpinner else { return }
        spinner.isUserInteractionEnabled = preventUserInteraction
        view.addSubview(spinner)
    }

    class func dismiss() {
        guard let spinner = shared.jhSpinner else { return }
        spinner.dismiss()
    }
}
