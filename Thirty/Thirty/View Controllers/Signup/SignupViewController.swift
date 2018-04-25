//
//  SignupViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 6/28/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import JHSpinner
import SafariServices

class SignupViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var textFieldsStackView: UIStackView!
    @IBOutlet weak var termsTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .thPrimaryPurple
        textFieldsStackView.arrangedSubviews.forEach { view in
            guard view is UITextField else { return }
            view.keyboardDistanceFromTextField = 44
            view.addPreviousNextDoneOnKeyboardWithTarget(self, previousAction: #selector(previousTapped(_:)), nextAction: #selector(nextTapped(_:)), doneAction: #selector(doneTapped(_:)))
        }
        let attributedString = NSMutableAttributedString(string: "By signing up, you agree to our Terms and Privacy Policy.", attributes: [NSAttributedStringKey.font: UIFont(name: "Avenir-Black", size: 9)!])
        let style = NSMutableParagraphStyle()
        style.alignment = NSTextAlignment.center
        attributedString.addAttribute(.paragraphStyle, value: style, range: NSMakeRange(0, attributedString.length))
        attributedString.addAttribute(.link, value: "https://that30app.com/terms-of-service", range: NSRange(location: 32, length: 5))
        attributedString.addAttribute(.link, value: "https://that30app.com/privacy-policy", range: NSRange(location: 41, length: 16))
        termsTextView.attributedText = attributedString
        termsTextView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        RootViewController.shared.showNavigationBar = true
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let nextTag = textField.tag + 1
        if let nextResponder = textField.superview?.viewWithTag(nextTag) {
            nextResponder.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            signupButtonTapped()
        }
        return false
    }
    
    // MARK: - UITextViewDelegate
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        let vc = SFSafariViewController(url: URL, entersReaderIfAvailable: true)
        vc.modalPresentationStyle = .overFullScreen
        present(vc, animated: true)
        return false
    }
    
    // MARK: - UIResponder
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        let touch = event?.allTouches?.first
        if touch?.view?.isKind(of: UITextField.self) == false {
            view.endEditing(true)
        }
    }
    
    // MARK: - Actions
    
    @IBAction func signupButtonTapped() {
        validateSignUpCredentials { results in
            guard results.areValid else {
                guard let errorText = results.errorText, let textField = results.textField else {
                    assertionFailure("\(#function) - validateSignUpCredentials returned false without description or textField.")
                    return
                }
                present(UIAlertController.createSimpleAlert(withTitle: "Problem Signing Up", message: errorText),
                        animated: true,
                        completion: { textField.becomeFirstResponder() })
                return
            }
            let user = User(username: usernameTextField.text!,
                            email: emailTextField.text!,
                            phoneNumber: phoneNumberTextField.text!.digits,
                            password: passwordTextField.text!,
                            deviceToken: TokenUtils.deviceToken,
                            firstName: firstNameTextField.text ?? "",
                            lastName: lastNameTextField.text ?? "")
            THSpinner.showSpinnerOnView(view)
            FirebaseManager.shared.createNewUser(user: user) { result in
                THSpinner.dismiss()
                switch result {
                case .success(_):
                    RootViewController.shared.goToHomeVC()
                case .failure(let error):
                    let errorInfo = error.alertInfo
                    self.present(UIAlertController.createSimpleAlert(withTitle: errorInfo.title, message: errorInfo.description), animated: true, completion: nil)
                }
            }
        }
    }

    // MARK: Keyboard Buttons

    @objc func previousTapped(_ sender: Any) {
        let textFields = textFieldsStackView.arrangedSubviews
        guard
            let textField = textFields.first(where: { $0.isFirstResponder }) as? UITextField,
            let offset = textFields.index(of: textField)
            else { return }
        if textFields.indices.contains(offset - 1) {
            (textFields[offset - 1] as? UITextField)?.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
    }

    @objc func nextTapped(_ sender: Any) {
        var textFields = textFieldsStackView.arrangedSubviews
        // The last view in our textFields is our terms of service textview.
        textFields.removeLast()
        guard
            let textField = textFields.first(where: { $0.isFirstResponder }) as? UITextField,
            let offset = textFields.index(of: textField)
            else { return }
        if textFields.indices.contains(offset + 1) {
            // The last view in our textFields is our terms of service textview.
            //guard offset != textFields.count - 1 else { textField.resignFirstResponder(); return }
            (textFields[offset + 1] as? UITextField)?.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
    }

    @objc func doneTapped(_ sender: Any) {
        textFieldsStackView.arrangedSubviews.first(where: { $0.isFirstResponder })?.resignFirstResponder()
    }

    // MARK: - Input Validation

    private func validateSignUpCredentials(completion: ((areValid: Bool, errorText: String?, textField: UITextField?)) -> Void) {
        var results: (Bool, String?, UITextField?)?
        textFieldsStackView.arrangedSubviews.forEach { view in
            guard results == nil, let textField = view as? UITextField, let text = textField.text else { return }
            switch textField {
            case emailTextField:
                // TODO: add actual validation, potentially check fb and make this escaping
                if text.isEmpty, text.count < 5, !text.contains("@"), !text.contains(".") {
                    results = (false, "You must enter an email.", textField)
                }
            case usernameTextField:
                // TODO: add actual validation, potentially check fb and make this escaping
                if text.isEmpty {
                    results = (false, "You must enter a username.", textField)
                }
            case passwordTextField:
                if text.count < 6 {
                    results = (false, "Your password must contain at least 6 characters.", textField)
                }
            case confirmPasswordTextField:
                if text != passwordTextField.text {
                    results = (false, "Your passwords do not match.", textField)
                }
            case phoneNumberTextField:
                // REVIEW: do we want to validate phone number? or even have it?
                // I dont know if/how we're using it, or keeping that info secure (eg - "salting" the database).
                if text.isEmpty {
                    results = (false, "Please enter your phone number, we use it to connect you with friends!", textField)
                } else if text.count != 10 {
                    results = (false, "Please enter a valid U.S. phone number with no spaces or special characters.", textField)
                }
            case firstNameTextField:
                if text.isEmpty {
                    results = (false, "Please enter your first name.", textField)
                }
            case lastNameTextField:
                if text.isEmpty {
                    results = (false, "Please enter your last name.", textField)
                }
            default:
                assertionFailure("Each user input field must be explicitly handled in \(type(of: self)).\(#function).")
            }
        }
        completion(results ?? (true, nil, nil))
    }
}


