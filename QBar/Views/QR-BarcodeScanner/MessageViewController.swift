//
//  MessageViewController.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 3/1/21.
//

import UIKit
import AVFoundation

/// Delegate to handle messageViewController.
protocol MessageViewControllerDelegate: class {
    func messageViewControllerDidTapOpenLinkButton(_ controller: MessageViewController)
    func messageViewControllerDidTapCancelButton(_ controller: MessageViewController)
}

/// View controller used for showing info text and loading animation.
public final class MessageViewController: UIViewController {
    weak var delegate: MessageViewControllerDelegate?
    
    // Image tint color for all the states, except for `.notFound`.
    public var regularTintColor: UIColor = .black
    // Image tint color for `.notFound` state.
    public var errorTintColor: UIColor = .red
    // Customizable state messages.
    public var messages = StateMessageProvider()
    
    // MARK: - UI properties
    public var codeText: String = ""
    /// Text label.
    public private(set) lazy var textLabel: UILabel = self.makeTextLabel()
    /// Info image view.
    public private(set) lazy var imageView: UIImageView = self.makeImageView()
    /// Border view.
    public private(set) lazy var borderView: UIView = self.makeBorderView()
    /// Button that opens the provided QR link.
    public private(set) lazy var openLinkButton: UIButton = self.makeOpenLinkButton()
    /// Button that cancels the opening provided Link.
    public private(set) lazy var cancelButton: UIButton = self.makeCancelButton()
    
    /// Blur effect view.
    private lazy var blurView: UIVisualEffectView = .init(effect: UIBlurEffect(style: .light))
    // Constraints that are activated when the view is used as a footer.
    private lazy var collapsedConstraints: [NSLayoutConstraint] = self.makeCollapsedConstraints()
    // Constraints that are activated when the view is used for loading animation and error messages.
    private lazy var expandedConstraints: [NSLayoutConstraint] = self.makeExpandedConstraints()
    
    var status = Status(state: .scanning) {
        didSet {
            handleStatusUpdate()
        }
    }
    
    // MARK: - Override properties
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            // Fallback on earlier versions
            return .default
        }
    }
    
    // MARK: - View lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(blurView)
        blurView.contentView.addSubviews(textLabel, imageView, openLinkButton, cancelButton, borderView)
        
        blurView.bringSubviewToFront(textLabel)
        handleStatusUpdate()
        setupActions()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        blurView.frame = view.bounds
        blurView.backgroundColor = .clear
        blurView.contentView.backgroundColor = UIColor.mainBlack.withAlphaComponent(0.3)
        blurView.cornerRadius(to: 8)
        blurView.subviews.forEach { (view) in
            view.cornerRadius(to: 8)
        }
    }
    
    // MARK: - Actions
    private func setupActions() {
        openLinkButton.addTarget(
            self,
            action: #selector(handleOpenLinkButtonTap),
            for: .touchUpInside
        )
        cancelButton.addTarget(
            self,
            action: #selector(handleCancelButtonTap),
            for: .touchUpInside
        )
    }
    
    /// Opens link of QR Code.
    @objc private func handleOpenLinkButtonTap() {
        delegate?.messageViewControllerDidTapOpenLinkButton(self)
    }
    
    /// Cancels the opening provided Link.
    @objc private func handleCancelButtonTap() {
        delegate?.messageViewControllerDidTapCancelButton(self)
    }
    
    // MARK: - Animations
    /// Animates blur and border view.
    func animateLoading() {
        animate(blurStyle: .light)
        animate(borderViewAngle: CGFloat(Double.pi/2))
    }
    
    /**
     Animates blur to make pulsating effect.
     
     - Parameter style: The current blur style.
     */
    private func animate(blurStyle: UIBlurEffect.Style) {
        guard status.state == .processing else { return }
        
        UIView.animate(
            withDuration: 2.0,
            delay: 0.5,
            options: [.beginFromCurrentState],
            animations: ({ [weak self] in
                self?.blurView.effect = UIBlurEffect(style: blurStyle)
            }),
            completion: ({ [weak self] _ in
                self?.animate(blurStyle: blurStyle == .light ? .extraLight : .light)
            }))
    }
    
    /**
     Animates border view with a given angle.
     
     - Parameter angle: Rotation angle.
     */
    private func animate(borderViewAngle: CGFloat) {
        guard status.state == .processing else {
            borderView.transform = .identity
            return
        }
        
        UIView.animate(
            withDuration: 0.8,
            delay: 0.5,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 1.0,
            options: [.beginFromCurrentState],
            animations: ({ [weak self] in
                self?.borderView.transform = CGAffineTransform(rotationAngle: borderViewAngle)
            }),
            completion: ({ [weak self] _ in
                self?.animate(borderViewAngle: borderViewAngle + CGFloat(Double.pi / 2))
            }))
    }
    
    // MARK: - State handling
    
    private func handleStatusUpdate() {
        borderView.isHidden = true
        borderView.layer.removeAllAnimations()
        imageView.isHidden = true
        cancelButton.isHidden = true
        openLinkButton.isHidden = true
        textLabel.text = "Point camera at QR Code or Barcode"
        
        switch status.state {
        case .scanning, .unauthorized:
            textLabel.numberOfLines = 3
            textLabel.textAlignment = .center
            openLinkButton.isHidden = true
            imageView.tintColor = regularTintColor
        case .processing:
            textLabel.numberOfLines = 10
            textLabel.textAlignment = .center
            textLabel.text = codeText
            textLabel.numberOfLines = 2
            borderView.isHidden = false
            cancelButton.isHidden = false
            openLinkButton.isHidden = false
            imageView.isHidden = false
            imageView.tintColor = regularTintColor
        case .notFound:
            textLabel.numberOfLines = 10
            textLabel.textAlignment = .center
            textLabel.text = status.text ?? messages.makeText(for: status.state)
            textLabel.text = codeText
            imageView.tintColor = errorTintColor
            openLinkButton.isHidden = true
        }
        
        if status.state == .scanning || status.state == .unauthorized {
            expandedConstraints.deactivate()
            collapsedConstraints.activate()
        } else {
            collapsedConstraints.deactivate()
            expandedConstraints.activate()
        }
    }
}

// MARK: - Subviews factory
private extension MessageViewController {
    func makeTextLabel() -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .mainWhite
        label.numberOfLines = 1
        label.font = UIFont.sfProDisplay(ofSize: 12, style: .medium)
        return label
    }
    
    func makeCodeTextView() -> UITextView {
        let text = UITextView()
        text.translatesAutoresizingMaskIntoConstraints = false
        text.textColor = .mainWhite
        return text
    }
    
    func makeOpenLinkButton() -> UIButton {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        let title = NSAttributedString(
            string: localizedString("Open Link"),
            attributes: [.font: UIFont.sfProDisplay(ofSize: 17, style: .semibold), .foregroundColor: UIColor.mainWhite])
        button.addBorder(width: 2, color: .mainWhite)
        button.cornerRadius(to: 16)
        button.setAttributedTitle(title, for: UIControl.State())
        button.sizeToFit()
        return button
    }
    
    func makeCancelButton() -> UIButton {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        let title = NSAttributedString(
            string: localizedString("Cancel"),
            attributes: [.font: UIFont.sfProDisplay(ofSize: 17, style: .semibold), .foregroundColor: UIColor.mainWhite])
        button.addBorder(width: 2, color: .mainWhite)
        button.cornerRadius(to: 16)
        button.setAttributedTitle(title, for: UIControl.State())
        button.sizeToFit()
        return button
    }
    
    func makeImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = imageNamed("qrBarIcon").withRenderingMode(.alwaysOriginal)
        imageView.tintColor = .black
        return imageView
    }
    
    func makeQROrBarcodeView() -> UIImageView {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }
    
    func makeBorderView() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.layer.borderWidth = 2
        view.layer.cornerRadius = 10
        view.layer.borderColor = UIColor.black.cgColor
        return view
    }
    
    func convertRectOfInterest(rect: CGRect) -> CGRect {
        let screenRect = self.view.frame
        let screenWidth = screenRect.width
        let screenHeight = screenRect.height
        let newX = 1 / (screenWidth / rect.minX)
        let newY = 1 / (screenHeight / rect.minY)
        let newWidth = 1 / (screenWidth / rect.width)
        let newHeight = 1 / (screenHeight / rect.height)
        return CGRect(x: newY, y: newX, width: newHeight, height: newWidth) 
    }
    
    func bringView() {
        let captureMetadataOutput = AVCaptureMetadataOutput()
        
        // calculate a centered square rectangle with red border
        let size = 300
        let screenWidth = self.view.frame.size.width
        let xPos = (CGFloat(screenWidth) / CGFloat(2)) - (CGFloat(size) / CGFloat(2))
        let scanRect = CGRect(x: Int(xPos), y: 150, width: size, height: size)
        
        // create UIView that will server as a red square to indicate where to place QRCode for scanning
        let scanAreaView = UIView()
        scanAreaView.layer.borderColor = UIColor.mainRed.cgColor
        scanAreaView.layer.borderWidth = 4
        scanAreaView.frame = scanRect
        
        // Set delegate and use the default dispatch queue to execute the call back
//        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
        captureMetadataOutput.rectOfInterest = convertRectOfInterest(rect: scanRect)
    
        // Initialize QR Code Frame to highlight the QR code
        let qrCodeFrameView = UIView()
        qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
        qrCodeFrameView.layer.borderWidth = 2
        view.addSubview(qrCodeFrameView)
        view.bringSubviewToFront(qrCodeFrameView)
        
        // Add a button that will be used to close out of the scan view
//        videoBtn.setTitle("Close", forState: .Normal)
//        videoBtn.setTitleColor(UIColor.blackColor(), forState: .Normal)
//        videoBtn.backgroundColor = UIColor.grayColor()
//        videoBtn.layer.cornerRadius = 5.0;
//        videoBtn.frame = CGRectMake(10, 30, 70, 45)
//        videoBtn.addTarget(self, action: "pressClose:", forControlEvents: .TouchUpInside)
//        view.addSubview(videoBtn)
        
        view.addSubview(scanAreaView)
    }
}

// MARK: - Layout

extension MessageViewController {
    private func makeExpandedConstraints() -> [NSLayoutConstraint] {
        let padding: CGFloat = 10
        
        return [
            imageView.centerYAnchor.constraint(equalTo: blurView.centerYAnchor, constant: -60),
            imageView.centerXAnchor.constraint(equalTo: blurView.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 100),
            imageView.heightAnchor.constraint(equalToConstant: 100),
            
            textLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 18),
            textLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            textLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
        
            openLinkButton.topAnchor.constraint(equalTo: textLabel.bottomAnchor, constant: 18),
            openLinkButton.centerXAnchor.constraint(equalTo: blurView.centerXAnchor),
            openLinkButton.widthAnchor.constraint(equalToConstant: 136),
            openLinkButton.heightAnchor.constraint(equalToConstant: 48),

            cancelButton.topAnchor.constraint(equalTo: openLinkButton.bottomAnchor, constant: 50),
            cancelButton.centerXAnchor.constraint(equalTo: blurView.centerXAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: 48),
            cancelButton.widthAnchor.constraint(equalToConstant: 136),
            
            borderView.topAnchor.constraint(equalTo: imageView.topAnchor, constant: -12),
            borderView.centerXAnchor.constraint(equalTo: blurView.centerXAnchor),
            borderView.widthAnchor.constraint(equalToConstant: 120),
            borderView.heightAnchor.constraint(equalToConstant: 120)
        ]
    }
    
    private func makeCollapsedConstraints() -> [NSLayoutConstraint] {
        let padding: CGFloat = 10
        var constraints = [
            imageView.topAnchor.constraint(equalTo: blurView.topAnchor, constant: 18),
            imageView.widthAnchor.constraint(equalToConstant: 30),
            imageView.heightAnchor.constraint(equalToConstant: 27),
            
            textLabel.centerYAnchor.constraint(equalTo: blurView.centerYAnchor),
            textLabel.leadingAnchor.constraint(equalTo: blurView.leadingAnchor, constant: padding),
            textLabel.trailingAnchor.constraint(equalTo: blurView.trailingAnchor, constant: -padding),
            
            openLinkButton.topAnchor.constraint(equalTo: blurView.topAnchor, constant: 200),
            openLinkButton.widthAnchor.constraint(equalToConstant: 136),
            openLinkButton.heightAnchor.constraint(equalToConstant: 48),

            cancelButton.topAnchor.constraint(equalTo: blurView.bottomAnchor, constant: 300),
            cancelButton.heightAnchor.constraint(equalToConstant: 48),
            cancelButton.widthAnchor.constraint(equalToConstant: 136)
        ]
        
        if #available(iOS 11.0, *) {
            constraints += [
                imageView.leadingAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                    constant: padding
                ),
                textLabel.trailingAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                    constant: -padding
                ),
                openLinkButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -padding),
                cancelButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -padding)
            ]
        } else {
            constraints += [
                imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
                textLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
                openLinkButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
                cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding)
            ]
        }
        
        return constraints
    }
}

