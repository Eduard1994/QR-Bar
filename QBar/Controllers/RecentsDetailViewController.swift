//
//  RecentsDetailViewController.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 3/4/21.
//

import UIKit

class RecentsDetailViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var codeImageView: UIImageView!
    @IBOutlet weak var codeText: UITextView!
    @IBOutlet weak var typeText: UITextView!
    
    // MARK: - Properties
    var code: Code!
    let service = Service()
    
    // MARK: - Override properties
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            // Fallback on earlier versions
            return .default
        }
    }
    
    // MARK: - View LyfeCicle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    // MARK: - Functions
    private func configureView() {
        nameTextField.addDoneClearButtonOnKeyboard(clearButtonColor: .mainRed, doneButtonColor: .mainBlue)
        nameTextField.cornerRadius(to: 3)
        nameTextField.addBorder(width: 0.5, color: .mainGrayAverage)
        nameTextField.addAttributedPlaceHolder(placeholder: "Edit name of the code...", font: UIFont.sfProText(ofSize: 16, style: .regular))
        
        self.nameLabel.text = code.title
        self.codeImageView.image = imageNamed(code.imageName)
        self.codeText.text = "Code/Link - \(code.code)"
        self.typeText.text = "Type - \(code.type)"
    }
    
    // MARK: - IBActions
    @IBAction func doneTapped(_ sender: Any) {
        if let name = nameTextField.text, name != "" {
            self.displayAnimatedActivityIndicatorView()
            self.code.title = name
            service.updateValue(at: self.code.tab, code: self.code, userID: self.code.userID) { (error) in
                if let error = error {
                    ErrorHandling.showError(message: error.localizedDescription, controller: self)
                    return
                }
                DispatchQueue.main.async {
                    self.hideAnimatedActivityIndicatorView()
                    self.dismiss(animated: true, completion: nil)
                }
            }
        } else {
            alert(title: nil, message: "Name field must not be empty.", preferredStyle: .alert, actionTitle: "OK", actionHandler: nil)
        }
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
