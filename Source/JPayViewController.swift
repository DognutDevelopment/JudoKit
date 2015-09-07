//
//  Payment.swift
//  Judo
//
//  Copyright (c) 2015 Alternative Payments Ltd
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import UIKit
import Judo
import JudoSecure

let inputFieldBorderColor = UIColor(red: 180/255, green: 180/255, blue: 180/255, alpha: 1.0)

public class JPayViewController: UIViewController, CardTextFieldDelegate, DateTextFieldDelegate, SecurityTextFieldDelegate {
    
    private (set) var amount: Amount?
    private (set) var judoIDString: String = ""
    private (set) var reference: Reference?
    
    var keyboardHeightConstraint: NSLayoutConstraint?
    
    private var currentLocation: CLLocationCoordinate2D?
    
    public static func payment() -> UINavigationController {
        return UINavigationController(rootViewController: JPayViewController())
    }
    
    let cardTextField: CardTextField = {
        let inputField = CardTextField()
        inputField.translatesAutoresizingMaskIntoConstraints = false
        inputField.layer.borderColor = inputFieldBorderColor.CGColor
        inputField.layer.borderWidth = 1.0
        return inputField
    }()
    
    let expiryDateTextField: DateTextField = {
        let inputField = DateTextField()
        inputField.translatesAutoresizingMaskIntoConstraints = false
        inputField.layer.borderColor = inputFieldBorderColor.CGColor
        inputField.layer.borderWidth = 1.0
        return inputField
    }()
    
    let secureCodeTextField: SecurityTextField = {
        let inputField = SecurityTextField()
        inputField.translatesAutoresizingMaskIntoConstraints = false
        inputField.layer.borderColor = inputFieldBorderColor.CGColor
        inputField.layer.borderWidth = 1.0
        return inputField
    }()
    
    let paymentButton: UIButton = {
        let button = UIButton(type: .Custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor(red: 30/255, green: 120/255, blue: 160/255, alpha: 1.0)
        button.setTitle("Pay", forState: .Normal)
        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        button.titleLabel?.font = UIFont.boldSystemFontOfSize(22)
        button.enabled = false
        button.alpha = 0.25
        button.titleLabel?.alpha = 0.5
        return button
    }()
    
    
    // can not initialize because self is not available at this point
    // must be var? because can also not be initialized in init before self is available
    var paymentNavBarButton: UIBarButtonItem?
    
    
    // MARK: Keyboard notification configuration
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(note: NSNotification) {
        guard let info = note.userInfo else { return } // BAIL
        
        guard let animationCurve = info[UIKeyboardAnimationCurveUserInfoKey],
            let animationDuration = info[UIKeyboardAnimationDurationUserInfoKey] else { return } // BAIL
        
        guard let keyboardRect = info[UIKeyboardFrameEndUserInfoKey]?.CGRectValue else { return } // BAIL
        
        self.keyboardHeightConstraint!.constant = -1 * keyboardRect.height
        self.paymentButton.setNeedsUpdateConstraints()
        
        UIView.animateWithDuration(animationDuration.doubleValue, delay: 0.0, options:UIViewAnimationOptions(rawValue: (animationCurve as! UInt)), animations: { () -> Void in
            self.paymentButton.layoutIfNeeded()
            }, completion: nil)
    }
    
    func keyboardWillHide(note: NSNotification) {
        guard let info = note.userInfo else { return } // BAIL
        
        guard let animationCurve = info[UIKeyboardAnimationCurveUserInfoKey],
            let animationDuration = info[UIKeyboardAnimationDurationUserInfoKey] else { return } // BAIL
        
        self.keyboardHeightConstraint!.constant = 0.0
        self.paymentButton.setNeedsUpdateConstraints()

        UIView.animateWithDuration(animationDuration.doubleValue, delay: 0.0, options:UIViewAnimationOptions(rawValue: (animationCurve as! UInt)), animations: { () -> Void in
            self.paymentButton.layoutIfNeeded()
            }, completion: nil)
    }

    // MARK: View Lifecycle
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Payment"
        
        // view
        self.view.backgroundColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1)
        self.view.addSubview(cardTextField)
        self.view.addSubview(expiryDateTextField)
        self.view.addSubview(secureCodeTextField)
        
        self.view.addSubview(paymentButton)
        
        // delegates
        self.cardTextField.delegate = self
        self.expiryDateTextField.delegate = self
        self.secureCodeTextField.delegate = self
        
        // layout constraints
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-(-1)-[card]-(-1)-|", options: .AlignAllBaseline, metrics: nil, views: ["card":self.cardTextField]))
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-(-1)-[expiry]-(-1)-[security(==expiry)]-(-1)-|", options: .AlignAllBaseline, metrics: nil, views: ["expiry":self.expiryDateTextField, "security":self.secureCodeTextField]))
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-79-[card(44)]-(-1)-[expiry(44)]->=20-|", options: .AlignAllLeft, metrics: nil, views: ["card":self.cardTextField, "expiry":self.expiryDateTextField]))
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-79-[card(44)]-(-1)-[security(44)]->=20-|", options: .AlignAllRight, metrics: nil, views: ["card":self.cardTextField, "security":self.secureCodeTextField]))
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|[button]|", options: NSLayoutFormatOptions.AlignAllBaseline, metrics: nil, views: ["button":self.paymentButton]))
        self.paymentButton.addConstraint(NSLayoutConstraint(item: self.paymentButton, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 50))
        self.keyboardHeightConstraint = NSLayoutConstraint(item: self.paymentButton, attribute: .Bottom, relatedBy: .Equal, toItem: self.view, attribute: .Bottom, multiplier: 1.0, constant: 0.0)
        self.view.addConstraint(self.keyboardHeightConstraint!)
        
        // button actions
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .Plain, target: self, action: Selector("doneButtonAction:"))
        self.paymentNavBarButton = UIBarButtonItem(title: "Pay", style: .Done, target: self, action: Selector("payButtonAction:"))
        self.paymentNavBarButton!.enabled = false
        self.navigationItem.rightBarButtonItem = self.paymentNavBarButton
        
        self.navigationController?.navigationBar.tintColor = UIColor(red: 75/255, green: 75/255, blue: 75/255, alpha: 1.0)
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor(red: 75/255, green: 75/255, blue: 75/255, alpha: 1.0)]
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
//        JudoSecure.locationWithCompletion { coordinate, err in
//            if let _ = err {
//                // do nothing
//            } else {
//                self.currentLocation = coordinate
//            }
//        }
    }
    
    // MARK: CardTextFieldDelegate
    
    public func cardTextField(textField: CardTextField, error: ErrorType) {
        self.errorAnimation(textField)
    }
    
    public func cardTextField(textField: CardTextField, didFindValidNumber cardNumberString: String) {
        self.expiryDateTextField.textField.becomeFirstResponder()
    }
    
    public func cardTextField(textField: CardTextField, didDetectNetwork network: CardNetwork) {
        self.cardTextField.updateCardLogo()
        self.secureCodeTextField.cardNetwork = network
        self.secureCodeTextField.updateCardLogo()
        self.secureCodeTextField.titleLabel.text = network.securityCodeTitle()
    }
    
    // MARK: DateTextFieldDelegate
    
    public func dateTextField(textField: DateTextField, error: ErrorType) {
        self.errorAnimation(textField)
    }
    
    public func dateTextField(textField: DateTextField, didFindValidDate date: String) {
        self.secureCodeTextField.textField.becomeFirstResponder()
    }
    
    // MARK: SecurityTextFieldDelegate
    
    public func securityTextFieldDidEnterCode(textField: SecurityTextField, isValid: Bool) {
        self.paymentEnabled(isValid)
    }
    
    // MARK: Button Actions
    
    func payButtonAction(sender: AnyObject) {
        guard let reference = self.reference,
        let amount = self.amount else { return } // delegate method call for error
        
        guard let location = self.currentLocation else { return } // need to send a warning
        
        let card = Card(number: self.cardTextField.textField.text!.stripped, expiryDate: self.expiryDateTextField.textField.text!, cv2: self.secureCodeTextField.textField.text!, address: nil)
        do {
            try Judo.payment(self.judoIDString, amount: amount, reference: reference).card(card).location(location).completion { (response, error) -> () in
                // delegate method call
            }
        } catch {
            
        }
    }
    
    func doneButtonAction(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: Helpers
    
    func errorAnimation(view: JudoPayInputField) {
        let animation = CAKeyframeAnimation()
        animation.keyPath = "position.x"
        animation.values = [0, 8, -8, 4, 0]
        animation.keyTimes = [0, (1 / 6.0), (3 / 6.0), (5 / 6.0), 1]
        animation.duration = 0.4
        animation.additive = true
        view.layer.addAnimation(animation, forKey: "wiggle")
    }
    
    func paymentEnabled(enabled: Bool) {
        self.paymentButton.enabled = enabled
        self.paymentButton.alpha = enabled ? 1.0 : 0.25
        self.paymentButton.titleLabel?.alpha = enabled ? 1.0 : 0.5
        self.paymentNavBarButton!.enabled = enabled
    }
    
}