//
//  CameraViewController.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 3/1/21.
//

import UIKit
import AVFoundation
import Vision
import ImageDetect

/// Delegate to handle camera setup and video capturing.
protocol CameraViewControllerDelegate: class {
    func cameraViewControllerDidSetupCaptureSession(_ controller: CameraViewController)
    func cameraViewControllerDidFailToSetupCaptureSession(_ controller: CameraViewController)
    func cameraViewController(_ controller: CameraViewController, didReceiveError error: Error)
    func cameraViewControllerDidTapSettingsButton(_ controller: CameraViewController)
    func cameraViewControllerDidTapGalleryButton(_ controller: CameraViewController)
    func cameraViewController(_ controller: CameraViewController, didOutput metadataObjects: [AVMetadataObject])
}

/// View controller responsible for camera controls and video capturing.
public final class CameraViewController: UIViewController {
    weak var delegate: CameraViewControllerDelegate?
    
    /// Focus view type.
    public var barCodeFocusViewType: FocusViewType = .animated
    public var showsCameraButton: Bool = false {
        didSet {
            cameraButton.isHidden = showsCameraButton
        }
    }
    /// `AVCaptureMetadataOutput` metadata object types.
    var metadata = [AVMetadataObject.ObjectType]()
    
    // MARK: - UI proterties
    /// Animated focus view.
    public private(set) lazy var focusView: UIView = self.makeFocusView()
    /// Button to change torch mode.
    public private(set) lazy var flashButton: UIButton = .init(type: .custom)
    /// From gallery button
    public private(set) lazy var fromGalleryButton: UIButton = self.makeGalleryButton()
    /// From gallery image
    public private(set) lazy var fromGalleryImage: UIImageView = .init(image: imageNamed("fromGalleryImage"))
    /// Button to turn on camera.
    public private(set) lazy var turnOnButton: UIButton = self.makeTurnOnButton()
    /// Title of turn on the camera and settings title.
    public private(set) lazy var turnOnTitle: UILabel = self.makeTitle()
    /// Button that opens settings to allow camera usage.
    public private(set) lazy var settingsButton: UIButton = self.makeSettingsButton()
    /// Button to switch between front and back camera.
    public private(set) lazy var cameraButton: UIButton = self.makeCameraButton()
    
    /// Flash blur effect view
    private lazy var flashBlurView: UIVisualEffectView = .init(effect: UIBlurEffect(style: .light))
    /// From Gallery blur effect view
    private lazy var fromGalleryBlurView: UIVisualEffectView = .init(effect: UIBlurEffect(style: .light))
    
    // Constraints for the focus view when it gets smaller in size.
    private var regularFocusViewConstraints = [NSLayoutConstraint]()
    // Constraints for the focus view when it gets bigger in size.
    private var animatedFocusViewConstraints = [NSLayoutConstraint]()
    
    // MARK: - Video
    
    /// Video preview layer.
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    /// Video capture device. This may be nil when running in Simulator.
    private var captureDevice: AVCaptureDevice?
    /// Capture session.
    private lazy var captureSession: AVCaptureSession = AVCaptureSession()
    // Service used to check authorization status of the capture device
    private let permissionService = VideoPermissionService()
    
    /// The current torch mode on the capture device.
    private var torchMode: TorchMode = .off {
        didSet {
            guard let captureDevice = captureDevice, captureDevice.hasFlash else { return }
            guard captureDevice.isTorchModeSupported(torchMode.captureTorchMode) else { return }
            
            do {
                try captureDevice.lockForConfiguration()
                captureDevice.torchMode = torchMode.captureTorchMode
                captureDevice.unlockForConfiguration()
            } catch {}
            
            flashButton.setImage(torchMode.image, for: UIControl.State())
        }
    }
    
    private var frontCameraDevice: AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
    }
    
    private var backCameraDevice: AVCaptureDevice? {
        return AVCaptureDevice.default(for: .video)
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
    
    // MARK: - Initialization
    deinit {
        stopCapturing()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - View lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        videoPreviewLayer?.videoGravity = .resizeAspectFill
        
        guard let videoPreviewLayer = videoPreviewLayer else {
            return
        }
        
        view.layer.addSublayer(videoPreviewLayer)
        view.addSubviews(turnOnButton, settingsButton, flashButton, focusView, cameraButton, turnOnTitle, flashBlurView, fromGalleryBlurView)
        
        flashBlurView.contentView.addSubview(flashButton)
        flashBlurView.bringSubviewToFront(flashButton)
        
        fromGalleryBlurView.contentView.addSubviews(fromGalleryButton, fromGalleryImage)
        fromGalleryBlurView.bringSubviewToFront(fromGalleryButton)
        
        flashBlurView.backgroundColor = .clear
        flashBlurView.contentView.backgroundColor = UIColor.mainBlack.withAlphaComponent(0.3)
        flashBlurView.cornerRadius(to: 16)
        flashBlurView.subviews.forEach { (view) in
            view.cornerRadius(to: 16)
        }
        
        fromGalleryBlurView.backgroundColor = .clear
        fromGalleryBlurView.contentView.backgroundColor = UIColor.mainBlack.withAlphaComponent(0.3)
        fromGalleryBlurView.cornerRadius(to: 16)
        fromGalleryBlurView.subviews.forEach { (view) in
            view.cornerRadius(to: 16)
        }
        
        settingsButton.isHidden = true
        settingsButton.isEnabled = false
        
        flashBlurView.isHidden = true
        fromGalleryBlurView.isHidden = true
        
        turnOnButton.isHidden = false
        turnOnButton.isEnabled = true
        
        torchMode = .off
        focusView.isHidden = true
//        setupCamera()
        setupConstraints()
        setupActions()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupVideoPreviewLayerOrientation()
        animateFocusView()
    }
    
    public override func viewWillTransition(to size: CGSize,
                                            with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(
            alongsideTransition: { [weak self] _ in
                self?.setupVideoPreviewLayerOrientation()
            },
            completion: ({ [weak self] _ in
                self?.animateFocusView()
            }))
    }
    
    // MARK: - Video capturing
    
    func startCapturing() {
        guard !isSimulatorRunning else {
            return
        }
        
        torchMode = .off
        captureSession.startRunning()
        focusView.isHidden = false
        flashButton.isHidden = captureDevice?.position == .front
        cameraButton.isHidden = !showsCameraButton
    }
    
    func stopCapturing() {
        guard !isSimulatorRunning else {
            return
        }
        
        torchMode = .off
        captureSession.stopRunning()
        focusView.isHidden = true
        flashButton.isHidden = true
        cameraButton.isHidden = true
    }
    
    // MARK: - Actions
    private func setupActions() {
        flashButton.addTarget(
            self,
            action: #selector(handleFlashButtonTap),
            for: .touchUpInside
        )
        fromGalleryButton.addTarget(
            self,
            action: #selector(handleGalleryTap),
            for: .touchUpInside
        )
        fromGalleryImage.addGestureRecognizer(UITapGestureRecognizer(
            target: self,
            action: #selector(handleGalleryTap))
        )
        settingsButton.addTarget(
            self,
            action: #selector(handleSettingsButtonTap),
            for: .touchUpInside
        )
        cameraButton.addTarget(
            self,
            action: #selector(handleCameraButtonTap),
            for: .touchUpInside
        )
        turnOnButton.addTarget(
            self,
            action: #selector(handleTurnOnTapped),
            for: .touchUpInside)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    /// `UIApplicationWillEnterForegroundNotification` action.
    @objc private func appWillEnterForeground() {
        torchMode = .off
        animateFocusView()
    }
    
    /// Turn on the camera
    @objc private func handleTurnOnTapped() {
        turnOnButton.isHidden = true
        turnOnButton.isEnabled = false
        settingsButton.isEnabled = true
        setupCamera()
    }
    
    /// Opens setting to allow camera usage.
    @objc private func handleSettingsButtonTap() {
        delegate?.cameraViewControllerDidTapSettingsButton(self)
    }
    
    /// Opens gallery image.
    @objc private func handleGalleryTap() {
        delegate?.cameraViewControllerDidTapGalleryButton(self)
    }
    
    /// Swaps camera position.
    @objc private func handleCameraButtonTap() {
        swapCamera()
    }
    
    /// Sets the next torch mode.
    @objc private func handleFlashButtonTap() {
        torchMode = torchMode.next
    }
    
    // MARK: - Camera setup
    
    /// Sets up camera and checks for camera permissions.
    private func setupCamera() {
        if !turnOnButton.isEnabled {
            flashBlurView.isHidden = false
            fromGalleryBlurView.isHidden = false
            permissionService.checkPersmission { [weak self] error in
                guard let strongSelf = self else {
                    return
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.settingsButton.isHidden = error == nil
                    self?.turnOnTitle.isHidden = error == nil
                    self?.turnOnTitle.text = "To be able to scan, turn on the camera from settings"
                }
                
                if error == nil {
                    strongSelf.setupSessionInput(for: .back)
                    strongSelf.setupSessionOutput()
                    strongSelf.delegate?.cameraViewControllerDidSetupCaptureSession(strongSelf)
                } else {
                    strongSelf.flashBlurView.isHidden = true
                    strongSelf.fromGalleryBlurView.isHidden = true
                    strongSelf.delegate?.cameraViewControllerDidFailToSetupCaptureSession(strongSelf)
                }
            }
        } else {
            // TODO
        }
    }
    
    /// Sets up capture input, output and session.
    private func setupSessionInput(for position: AVCaptureDevice.Position) {
        guard !isSimulatorRunning else {
            return
        }
        
        guard let device = position == .front ? frontCameraDevice : backCameraDevice else {
            return
        }
        
        do {
            let newInput = try AVCaptureDeviceInput(device: device)
            captureDevice = device
            // Swap capture device inputs
            captureSession.beginConfiguration()
            if let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput {
                captureSession.removeInput(currentInput)
            }
            captureSession.addInput(newInput)
            captureSession.commitConfiguration()
            flashButton.isHidden = position == .front
        } catch {
            delegate?.cameraViewController(self, didReceiveError: error)
            return
        }
    }
    
    private func setupSessionOutput() {
        guard !isSimulatorRunning else {
            return
        }
        
        let output = AVCaptureMetadataOutput()
        captureSession.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes = metadata
        
        videoPreviewLayer?.session = captureSession
        
        view.setNeedsLayout()
    }
    
    /// Switch front/back camera.
    private func swapCamera() {
        guard let input = captureSession.inputs.first as? AVCaptureDeviceInput else {
            return
        }
        setupSessionInput(for: input.device.position == .back ? .front : .back)
    }
    
    // MARK: - Animations
    
    /// Performs focus view animation.
    private func animateFocusView() {
        // Restore to initial state
        focusView.layer.removeAllAnimations()
        animatedFocusViewConstraints.deactivate()
        regularFocusViewConstraints.activate()
        view.layoutIfNeeded()
        
        guard barCodeFocusViewType == .animated else {
            return
        }
        
        regularFocusViewConstraints.deactivate()
        animatedFocusViewConstraints.activate()
        
        UIView.animate(
            withDuration: 1.0,
            delay: 0,
            options: [.repeat, .autoreverse, .beginFromCurrentState],
            animations: ({ [weak self] in
                self?.view.layoutIfNeeded()
            }),
            completion: nil
        )
    }
}

// MARK: - Layout

private extension CameraViewController {
    func setupConstraints() {
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate(
                cameraButton.bottomAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                    constant: -30
                )
            )
        } else {
            NSLayoutConstraint.activate(
                cameraButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30)
            )
        }
        
        let imageButtonSize: CGSize = CGSize(width: 18, height: 24)
        
        NSLayoutConstraint.activate(
            flashBlurView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            flashBlurView.topAnchor.constraint(equalTo: view.topAnchor, constant: 48),
            flashBlurView.widthAnchor.constraint(equalToConstant: 40),
            flashBlurView.heightAnchor.constraint(equalToConstant: 40),
            
            flashButton.centerYAnchor.constraint(equalTo: flashBlurView.centerYAnchor),
            flashButton.centerXAnchor.constraint(equalTo: flashBlurView.centerXAnchor),
            flashButton.widthAnchor.constraint(equalToConstant: imageButtonSize.width),
            flashButton.heightAnchor.constraint(equalToConstant: imageButtonSize.height),
            
            fromGalleryBlurView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            fromGalleryBlurView.topAnchor.constraint(equalTo: view.topAnchor, constant: 48),
            fromGalleryBlurView.widthAnchor.constraint(equalToConstant: 121),
            fromGalleryBlurView.heightAnchor.constraint(equalToConstant: 40),
            
            fromGalleryButton.leadingAnchor.constraint(equalTo: fromGalleryBlurView.leadingAnchor, constant: 12),
            fromGalleryButton.centerYAnchor.constraint(equalTo: fromGalleryBlurView.centerYAnchor),
            fromGalleryButton.trailingAnchor.constraint(equalTo: fromGalleryBlurView.trailingAnchor, constant: -30),
            
            fromGalleryImage.centerYAnchor.constraint(equalTo: fromGalleryBlurView.centerYAnchor),
            fromGalleryImage.trailingAnchor.constraint(equalTo: fromGalleryBlurView.trailingAnchor, constant: -13.5),
            fromGalleryImage.widthAnchor.constraint(equalToConstant: 21),
            fromGalleryImage.heightAnchor.constraint(equalToConstant: 21),
            
            turnOnTitle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            turnOnTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            turnOnTitle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            turnOnTitle.bottomAnchor.constraint(equalTo: settingsButton.topAnchor, constant: -15),
            
            turnOnButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            turnOnButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            turnOnButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 120),
            turnOnButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -120),
            turnOnButton.heightAnchor.constraint(equalToConstant: 48),
            
            settingsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            settingsButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            settingsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 120),
            settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -120),
            settingsButton.heightAnchor.constraint(equalToConstant: 48),
            
            cameraButton.widthAnchor.constraint(equalToConstant: 48),
            cameraButton.heightAnchor.constraint(equalToConstant: 48),
            cameraButton.trailingAnchor.constraint(equalTo: flashButton.trailingAnchor)
        )
        
        setupFocusViewConstraints()
    }
    
    func setupFocusViewConstraints() {
        NSLayoutConstraint.activate(
            focusView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            focusView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        )
        
        let focusViewSize = barCodeFocusViewType == .oneDimension
            ? CGSize(width: 280, height: 80)
            : CGSize(width: 218, height: 150)
        
        regularFocusViewConstraints = [
            focusView.widthAnchor.constraint(equalToConstant: focusViewSize.width),
            focusView.heightAnchor.constraint(equalToConstant: focusViewSize.height)
        ]
        
        animatedFocusViewConstraints = [
            focusView.widthAnchor.constraint(equalToConstant: 280),
            focusView.heightAnchor.constraint(equalToConstant: 80)
        ]
        
        NSLayoutConstraint.activate(regularFocusViewConstraints)
    }
    
    func setupVideoPreviewLayerOrientation() {
        guard let videoPreviewLayer = videoPreviewLayer else {
            return
        }
        
        videoPreviewLayer.frame = view.layer.bounds
        
        if let connection = videoPreviewLayer.connection, connection.isVideoOrientationSupported {
            switch UIApplication.shared.statusBarOrientation {
            case .portrait:
                connection.videoOrientation = .portrait
            case .landscapeRight:
                connection.videoOrientation = .landscapeRight
            case .landscapeLeft:
                connection.videoOrientation = .landscapeLeft
            case .portraitUpsideDown:
                connection.videoOrientation = .portraitUpsideDown
            default:
                connection.videoOrientation = .portrait
            }
        }
    }
}

// MARK: - Subviews factory

private extension CameraViewController {
    func makeFocusView() -> UIView {
        let view = UIView()
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 2
        view.layer.cornerRadius = 5
        view.layer.shadowColor = UIColor.white.cgColor
        view.layer.shadowRadius = 10.0
        view.layer.shadowOpacity = 0.9
        view.layer.shadowOffset = CGSize.zero
        view.layer.masksToBounds = false
        return view
    }
    
    func makeSettingsButton() -> UIButton {
        let button = UIButton(type: .system)
        let title = NSAttributedString(
            string: localizedString("Settings"),
            attributes: [.font: UIFont.sfProDisplay(ofSize: 17, style: .semibold), .foregroundColor: UIColor.mainBlack])
        button.addBorder(width: 2, color: .mainBlack)
        button.cornerRadius(to: 16)
        button.setAttributedTitle(title, for: UIControl.State())
        button.sizeToFit()
        return button
    }
    
    func makeTurnOnButton() -> UIButton {
        let button = UIButton(type: .custom)
        let title = NSAttributedString(string: localizedString("Turn on"), attributes: [.font: UIFont.sfProDisplay(ofSize: 17, style: .semibold), .foregroundColor: UIColor.mainBlack])
        button.addBorder(width: 2, color: .mainBlack)
        button.cornerRadius(to: 16)
        button.setAttributedTitle(title, for: UIControl.State())
        button.sizeToFit()
        return button
    }
    
    func makeTitle() -> UILabel {
        let label = UILabel(frame: .zero)
        label.attributedText = NSAttributedString(string: localizedString("Turn on the camera to scan"), attributes: [.font: UIFont.sfProDisplay(ofSize: 20, style: .medium), .foregroundColor: UIColor.mainBlack])
        label.numberOfLines = 2
        label.textAlignment = .center
        label.sizeToFit()
        return label
    }
    
    func makeGalleryButton() -> UIButton {
        let button = UIButton(type: .custom)
        let title = NSAttributedString(string: localizedString("From gallery"), attributes: [.font: UIFont.sfProDisplay(ofSize: 12, style: .bold), .foregroundColor: UIColor.mainWhite])
        button.contentHorizontalAlignment = .left
        button.setAttributedTitle(title, for: UIControl.State())
        button.sizeToFit()
        return button
    }
    
    func makeCameraButton() -> UIButton {
        let button = UIButton(type: .custom)
        button.setImage(imageNamed("cameraRotate"), for: UIControl.State())
        button.isHidden = !showsCameraButton
        return button
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension CameraViewController: AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        print(metadataObjects)
        print("HeReeee")
        delegate?.cameraViewController(self, didOutput: metadataObjects)
    }
}
