//
//  SettingsHeaderView.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 2/28/21.
//

import UIKit

// MARK: - Links and email for settings
let kAppURL = "https://qr-bar-app.com"
let kPolicyURL = "https://qr-bar-app.com/policy.html"
let kTermsURL = "https://qr-bar-app.com/terms.html"
let kEmail = "support@qr-bar-app.com"
let kCCRecipentEmail = "fixed.development@gmail.com"

let hideSettingsUpgradeNotification: Notification.Name = Notification.Name(rawValue: "HideSettingsUpgrade")
let upgradeFromSettings: Notification.Name = Notification.Name(rawValue: "UpgradeFromSettings")
let showErrorForSettings: Notification.Name = Notification.Name("ShowErrorForSettings")

class SettingsHeaderView: UIView {
    
    // Constraints that are activated when the view is used as a footer.
    private lazy var collapsedConstraints: [NSLayoutConstraint] = self.makeCollapsedConstraints()
    // Constraints that are activated when the view is used for loading animation and error messages.
    private lazy var expandedConstraints: [NSLayoutConstraint] = self.makeExpandedConstraints()
    
    lazy var headerTitle: UILabel = {
        let title = UILabel(frame: .zero)
        title.translatesAutoresizingMaskIntoConstraints = false
        
        title.textAlignment = .center
        title.textColor = .mainBlack
        title.font = .sfProDisplay(ofSize: 30, style: .bold)
        return title
    }()
    
    lazy var upgradeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.textColor = .mainWhite
        label.font = .sfProDisplay(ofSize: 30, style: .bold)
        return label
    }()
    
    lazy var enjoyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.textColor = .mainWhite
        label.font = .sfProDisplay(ofSize: 16, style: .regular)
        return label
    }()
    
    lazy var upgradeButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(upgradeTapped(_:)), for: .touchUpInside)
        button.backgroundColor = .mainWhite
        let title = NSAttributedString(string: "Upgrade", attributes: [.font: UIFont.sfProText(ofSize: 16, style: .semibold), .foregroundColor: UIColor.mainBlack])
        button.setAttributedTitle(title, for: UIControl.State())
        button.cornerRadius(to: 20)
        return button
    }()
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.backgroundColor = .clear
        imageView.image = UIImage(named: "upgradeHeader")
        return imageView
    }()
    
    lazy var upgradeView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        
        view.backgroundColor = .clear
        return view
    }()
    
    let service = Service()
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .mainWhite
        
        addSubview(headerTitle)
        addSubview(upgradeLabel)
        addSubview(enjoyLabel)
        addSubview(upgradeButton)
        addSubview(imageView)
        addSubview(upgradeView)
        
        bringSubviewToFront(upgradeLabel)
        bringSubviewToFront(enjoyLabel)
        bringSubviewToFront(upgradeButton)
        
        NotificationCenter.default.addObserver(self, selector: #selector(notifiedForUpgradeView), name: hideSettingsUpgradeNotification, object: nil)
        
        expandedConstraints.activate()
        
        service.getSettingsTitles(for: PremiumTab.Settings.rawValue) { (settingsTitle, error) in
            if let _ = error {
                NotificationCenter.default.post(name: showErrorForSettings, object: nil)
                self.configureTitles(settings: SettingsTitle())
                return
            }
            if let settingsTitle = settingsTitle {
                DispatchQueue.main.async {
                    self.configureTitles(settings: settingsTitle)
                }
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Functions
    func configureHeader(text: String?) {
        headerTitle.text = text
    }
    
    func updateView() {
        print("Upgrade tapped")
        NotificationCenter.default.post(name: upgradeFromSettings, object: nil)
    }
    
    // MARK: = Private Functions
    private func configureTitles(settings: SettingsTitle) {
        self.upgradeLabel.text = settings.firstTitle
        self.enjoyLabel.text = settings.secondTitle
    }
    
    private func makeExpandedConstraints() -> [NSLayoutConstraint] {
        return [
            headerTitle.topAnchor.constraint(equalTo: topAnchor, constant: 48),
            headerTitle.centerXAnchor.constraint(equalTo: centerXAnchor),
            headerTitle.bottomAnchor.constraint(equalTo: upgradeView.topAnchor, constant: -24),

            upgradeLabel.centerXAnchor.constraint(equalTo: upgradeView.centerXAnchor),
            upgradeLabel.topAnchor.constraint(equalTo: upgradeView.topAnchor, constant: 44),
            
            enjoyLabel.centerXAnchor.constraint(equalTo: upgradeView.centerXAnchor),
            enjoyLabel.topAnchor.constraint(equalTo: upgradeLabel.bottomAnchor, constant: 12),
            
            upgradeButton.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 136),
            upgradeButton.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 95),
            upgradeButton.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -95),
            upgradeButton.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -40),
            
            imageView.topAnchor.constraint(equalTo: upgradeView.topAnchor, constant: 0),
            imageView.bottomAnchor.constraint(equalTo: upgradeView.bottomAnchor, constant: 0),
            imageView.leadingAnchor.constraint(equalTo: upgradeView.leadingAnchor, constant: 0),
            imageView.trailingAnchor.constraint(equalTo: upgradeView.trailingAnchor, constant: 0),
            
            upgradeView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            upgradeView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            upgradeView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24)
        ]
    }
    
    private func makeCollapsedConstraints() -> [NSLayoutConstraint] {
        return [
            headerTitle.topAnchor.constraint(equalTo: topAnchor, constant: 48),
            headerTitle.centerXAnchor.constraint(equalTo: centerXAnchor),
            headerTitle.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
        ]
    }
    
    // MARK: - OBJC Functions
    @objc private func upgradeTapped(_ sender: UIButton) {
        print("Something")
        updateView()
    }
    
    @objc private func notifiedForUpgradeView() {
        self.upgradeView.removeFromSuperview()
        self.imageView.removeFromSuperview()
        self.upgradeButton.removeFromSuperview()
        self.upgradeLabel.removeFromSuperview()
        self.enjoyLabel.removeFromSuperview()
        expandedConstraints.deactivate()
        collapsedConstraints.activate()
    }
}

