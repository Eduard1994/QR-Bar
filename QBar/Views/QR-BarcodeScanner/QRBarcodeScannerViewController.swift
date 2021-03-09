//
//  QRBarcodeScannerViewController.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 3/1/21.
//

import UIKit
import AVFoundation

// MARK: - Delegates
/// Delegate to handle the captured code.
public protocol QRBarcodeScannerCodeDelegate: class {
    func scanner(_ controller: QRBarcodeScannerViewController, didCaptureCode code: String, type: String)
    func scanner(_ controller: QRBarcodeScannerViewController, didNotFind result: String)
}

/// Delegate to report errors.
public protocol QRBarcodeScannerErrorDelegate: class {
    func scanner(_ controller: QRBarcodeScannerViewController, didReceiveError error: Error)
}

/// Delegate to dismiss barcode scanner when the close button has been pressed.
public protocol QRBarcodeScannerDismissalDelegate: class {
    func scannerDidDismiss(_ controller: QRBarcodeScannerViewController)
}

// MARK: - Controller

/**
 Barcode scanner controller with 4 sates:
 - Scanning mode
 - Processing animation
 - Unauthorized mode
 - Not found error message
 */
open class QRBarcodeScannerViewController: UIViewController {
    private static let footerHeight: CGFloat = 40
    
    // MARK: - Public properties
    /// Delegate to handle the captured code.
    public weak var codeDelegate: QRBarcodeScannerCodeDelegate?
    /// Delegate to report errors.
    public weak var errorDelegate: QRBarcodeScannerErrorDelegate?
    /// Delegate to dismiss barcode scanner when the close button has been pressed.
    public weak var dismissalDelegate: QRBarcodeScannerDismissalDelegate?
    
    /// When the flag is set to `true` controller returns a captured code
    /// and waits for the next reset action.
    public var isOneTimeSearch = true
    
    /// `AVCaptureMetadataOutput` metadata object types.
    public var metadata = AVMetadataObject.ObjectType.barcodeScannerMetadata {
        didSet {
            cameraViewController.metadata = metadata
        }
    }
    
    // MARK: - Private properties
    /// Flag to lock session from capturing.
    private var locked = false
    /// Flag to check if layout constraints has been activated.
    private var constraintsActivated = false
    /// Flag to check if view controller is currently on screen
    private var isVisible = false
    
    // MARK: - UI
    /// Information view with description label.
    public private(set) lazy var messageViewController: MessageViewController = .init()
    /// Camera view with custom buttons.
    public private(set) lazy var cameraViewController: CameraViewController = .init()
    
    // Constraints that are activated when the view is used as a footer.
    private lazy var collapsedConstraints: [NSLayoutConstraint] = self.makeCollapsedConstraints()
    // Constraints that are activated when the view is used for loading animation and error messages.
    private lazy var expandedConstraints: [NSLayoutConstraint] = self.makeExpandedConstraints()
    
    private var messageView: UIView {
        return messageViewController.view
    }
    
    /// The current controller's status mode.
    private var status: Status = Status(state: .scanning) {
        didSet {
            changeStatus(from: oldValue, to: status)
        }
    }
    
    /// Image Picker controller
    private var imagePicker: ImagePicker!
    
    /// QRCode Link
    private var link: String!
    
    // MARK: - Override properties
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            // Fallback on earlier versions
            return .default
        }
    }
    
    // MARK: - View lifecycle
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        add(childViewController: messageViewController)
        messageView.translatesAutoresizingMaskIntoConstraints = false
        collapsedConstraints.activate()
        
        cameraViewController.metadata = metadata
        cameraViewController.delegate = self
        add(childViewController: cameraViewController)
        
        messageViewController.delegate = self
        
        messageView.isHidden = true
        
        view.bringSubviewToFront(messageView)
        
        imagePicker = ImagePicker(presentationController: self, delegate: self)
        imagePicker.setMediaType(for: [.image])
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupCameraConstraints()
        isVisible = true
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isVisible = false
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.messageView.subviews.forEach { (view) in
            if let view = view as? UIVisualEffectView {
                view.backgroundColor = .clear
                view.contentView.backgroundColor = UIColor.mainBlack.withAlphaComponent(0.3)
                view.cornerRadius(to: 8)
                view.subviews.forEach { (view) in
                    view.cornerRadius(to: 8)
                }
            }
        }
    }
    
    // MARK: - State handling
    
    /**
     Shows error message and goes back to the scanning mode.
     - Parameter errorMessage: Error message that overrides the message from the config.
     */
    public func resetWithError(message: String? = nil) {
        status = Status(state: .notFound, text: message)
    }
    
    /**
     Resets the controller to the scanning mode.
     - Parameter animated: Flag to show scanner with or without animation.
     */
    public func reset(animated: Bool = true) {
        status = Status(state: .scanning, animated: animated)
    }
    
    private func changeStatus(from oldValue: Status, to newValue: Status) {
        guard newValue.state != .notFound else {
            messageViewController.status = newValue
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0) {
                self.status = Status(state: .scanning)
            }
            return
        }
        
        let animatedTransition = newValue.state == .processing
            || oldValue.state == .processing
            || oldValue.state == .notFound
        let duration = newValue.animated && animatedTransition ? 0.5 : 0.0
        let delayReset = oldValue.state == .processing || oldValue.state == .notFound
        
        if !delayReset {
            resetState()
        }
        
        if newValue.state != .processing {
            expandedConstraints.deactivate()
            collapsedConstraints.activate()
        } else {
            collapsedConstraints.deactivate()
            expandedConstraints.activate()
        }
        
        messageViewController.status = newValue
        
        UIView.animate(
            withDuration: duration,
            animations: ({
                self.view.layoutIfNeeded()
            }),
            completion: ({ [weak self] _ in
                if delayReset {
                    self?.resetState()
                }
                
                self?.messageView.layer.removeAllAnimations()
                if self?.status.state == .processing {
                    self?.messageViewController.animateLoading()
                }
            }))
    }
    
    /// Resets the current state.
    private func resetState() {
        locked = status.state == .processing && isOneTimeSearch
        if status.state == .scanning {
            cameraViewController.startCapturing()
        } else {
            cameraViewController.stopCapturing()
        }
    }
    
    // MARK: - Animations
    /**
     Simulates flash animation.
     - Parameter processing: Flag to set the current state to `.processing`.
     */
    private func animateFlash(text: String, type: String?, image: UIImage, whenProcessing: Bool = false) {
        let flashView = UIView(frame: view.bounds)
        flashView.backgroundColor = UIColor.white
        flashView.alpha = 1
        
        messageViewController.imageView.image = image
        messageViewController.codeText = text
        
        view.addSubview(flashView)
        view.bringSubviewToFront(flashView)
        
        UIView.animate(withDuration: 0.2, animations: ({
            flashView.alpha = 0.0
        }), completion: ({ [weak self] _ in
            flashView.removeFromSuperview()
            
            if whenProcessing {
                self?.status = Status(state: .processing)
            }
            
            if let type = type {
                if type.contains("QR") {
                    self?.messageViewController.openLinkButton.isHidden = false
                } else {
                    self?.messageViewController.openLinkButton.isHidden = true
                }
            }
        }))
    }
}

// MARK: - Layout
private extension QRBarcodeScannerViewController {
    private func setupCameraConstraints() {
        guard !constraintsActivated else {
            return
        }
        
        constraintsActivated = true
        let cameraView = cameraViewController.view!
        
        NSLayoutConstraint.activate(
            cameraView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cameraView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor)
        )
        
        if navigationController != nil {
            cameraView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        } else {
            NSLayoutConstraint.activate(
                cameraView.topAnchor.constraint(equalTo: view.topAnchor)
            )
        }
    }
    
    private func makeExpandedConstraints() -> [NSLayoutConstraint] {
        return [
            messageView.topAnchor.constraint(equalTo: view.topAnchor),
            messageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
    }
    
    private func makeCollapsedConstraints() -> [NSLayoutConstraint] {
        return [
            messageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -123),
            messageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            messageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            messageView.heightAnchor.constraint(
                equalToConstant: QRBarcodeScannerViewController.footerHeight
            )
        ]
    }
}

// MARK: - CameraViewControllerDelegate
extension QRBarcodeScannerViewController: CameraViewControllerDelegate {
    func cameraViewControllerDidTapGalleryButton(_ controller: CameraViewController) {
        print(controller)
        self.cameraViewController.stopCapturing()
        self.imagePicker.present(from: self.view, type: .choosePhoto)
    }
    
    func cameraViewControllerDidSetupCaptureSession(_ controller: CameraViewController) {
        messageView.isHidden = false
        status = Status(state: .scanning)
    }
    
    func cameraViewControllerDidFailToSetupCaptureSession(_ controller: CameraViewController) {
        messageView.isHidden = true
        status = Status(state: .unauthorized)
    }
    
    func cameraViewController(_ controller: CameraViewController, didReceiveError error: Error) {
        messageView.isHidden = false
        errorDelegate?.scanner(self, didReceiveError: error)
    }
    
    func cameraViewControllerDidTapSettingsButton(_ controller: CameraViewController) {
        DispatchQueue.main.async {
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
            }
        }
    }
    
    func cameraViewController(_ controller: CameraViewController, didOutput metadataObjects: [AVMetadataObject]) {
        guard !locked && isVisible else { return }
        guard !metadataObjects.isEmpty else { return }
        
        guard
            let metadataObj = metadataObjects[0] as? AVMetadataMachineReadableCodeObject,
            var code = metadataObj.stringValue,
            metadata.contains(metadataObj.type)
        else { return }
        
        if isOneTimeSearch {
            locked = true
        }
        
        var rawType = metadataObj.type.rawValue
        var image: UIImage!
        // UPC-A is an EAN-13 barcode with a zero prefix.
        // See: https://stackoverflow.com/questions/22767584/ios7-barcode-scanner-api-adds-a-zero-to-upca-barcode-format
        if metadataObj.type == AVMetadataObject.ObjectType.ean13 && code.hasPrefix("0") {
            code = String(code.dropFirst())
            rawType = AVMetadataObject.ObjectType.upca.rawValue
        }
        
        if rawType.contains("QR") {
            print("Raw type on qrcontroller = \(rawType)")
            image = generateQRCode(from: code)
            self.link = code
        } else {
            image = generateBarcode(from: code)
            self.link = code
        }
        
        codeDelegate?.scanner(self, didCaptureCode: code, type: rawType)
        animateFlash(text: code, type: rawType, image: image, whenProcessing: isOneTimeSearch)
    }
}

// MARK: - MessageViewControllerDelegate
extension QRBarcodeScannerViewController: MessageViewControllerDelegate {
    func messageViewControllerDidTapOpenLinkButton(_ controller: MessageViewController) {
        if self.link.contains("http") {
            openURL(path: self.link)
        } else {
            self.alert(title: nil, message: "This QR Code does not have a URL. Please try another one.", preferredStyle: .alert, actionTitle: "OK", actionHandler: nil)
        }
    }
    
    func messageViewControllerDidTapCancelButton(_ controller: MessageViewController) {
        print("Tapped Cancel")
        dismissalDelegate?.scannerDidDismiss(self)
    }
}

// MARK: - ImagePicker Delegate
extension QRBarcodeScannerViewController: ImagePickerDelegate {
    func didFind(qrImage: UIImage, type: String, code: String) {
        guard !locked && isVisible else { return }
        
        if isOneTimeSearch {
            locked = true
        }
        
        self.link = code
        
        codeDelegate?.scanner(self, didCaptureCode: code, type: type)
        animateFlash(text: code, type: type, image: qrImage, whenProcessing: isOneTimeSearch)
    }
    
    func didFind(barcodeImage: UIImage, type: String, code: String) {
        guard !locked && isVisible else { return }
        
        if isOneTimeSearch {
            locked = true
        }
        
        self.link = code
        
        codeDelegate?.scanner(self, didCaptureCode: code, type: type)
        animateFlash(text: code, type: type, image: barcodeImage, whenProcessing: isOneTimeSearch)
    }
    
    func didNotFind(error: String) {
        guard !locked && isVisible else { return }

        if isOneTimeSearch {
            locked = true
        }
        
        codeDelegate?.scanner(self, didNotFind: error)
        animateFlash(text: error, type: "", image: imageNamed("qrBarIcon"), whenProcessing: isOneTimeSearch)
    }
    
    func didCancelled(_ picker: UIImagePickerController) {
        self.cameraViewController.startCapturing()
    }
    
    func didSelect(image: UIImage?) {
        if let image = image, let cgImage = image.cgImage {
            if let cvImageBuffer = image.pixelBuffer(forImage: cgImage) {
                imagePicker.imageRequestHandler(pixelBuffer: cvImageBuffer)
            }
        }
    }
}
