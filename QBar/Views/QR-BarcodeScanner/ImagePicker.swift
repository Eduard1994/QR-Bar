//
//  ImagePicker.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 3/2/21.
//

import UIKit
import Vision
import AVFoundation

typealias Action = () -> ()
var action: Action? = {}

enum CameraType: String {
    case choosePhoto = "Choose QR Code or Barcode"
}

enum MediaType: String {
    case image = "public.image"
}

protocol ImagePickerDelegate: class {
    func didCancelled(_ picker: UIImagePickerController)
    func didSelect(image: UIImage?)
    func didFind(qrImage: UIImage, type: String, code: String)
    func didFind(barcodeImage: UIImage, type: String, code: String)
    func didNotFind(error: String)
}

class ImagePicker: NSObject {
    // MARK: - Private properties
    private let pickerController: UIImagePickerController
    private weak var presentationController: UIViewController?
    private weak var delegate: ImagePickerDelegate?
    
    
    // MARK: - Public init
    public init(presentationController: UIViewController, delegate: ImagePickerDelegate) {
        self.pickerController = UIImagePickerController()
        super.init()
        
        self.presentationController = presentationController
        self.delegate = delegate
        
        self.pickerController.delegate = self
        self.pickerController.allowsEditing = true
    }
    
    // MARK: - BarcodeDetection Request
    lazy var detectBarcodeRequest = VNDetectBarcodesRequest { request, error in
        guard error == nil else {
            print(error?.localizedDescription as Any)
            self.delegate?.didNotFind(error: "The QR or Barcode was not clear. Try another one.")
            return
        }
        self.processClassification(request)
    }
    
    // MARK: - Private Functions
    private func action(for type: UIImagePickerController.SourceType, title: String) -> UIAlertAction? {
        guard UIImagePickerController.isSourceTypeAvailable(type) else {
            return nil
        }
        
        return UIAlertAction(title: title, style: .default) { [unowned self] _ in
            self.pickerController.sourceType = type
            self.presentationController?.present(self.pickerController, animated: true)
        }
    }
    
    private func pickerController(_ controller: UIImagePickerController, didSelect image: UIImage?, didSelect url: URL?) {
        controller.dismiss(animated: true, completion: nil)
        
        delegate?.didCancelled(controller)
        if let image = image {
            self.delegate?.didSelect(image: image)
        }
    }
    
    // MARK: - Public Functions
    public func setMediaType(for mediaTypes: [MediaType]) {
        for mediaType in mediaTypes {
            self.pickerController.mediaTypes.append(mediaType.rawValue)
        }
    }
    
    public func present(from sourceView: UIView, type: CameraType) {
        self.pickerController.sourceType = .photoLibrary
        self.presentationController?.present(self.pickerController, animated: true)
    }
    
    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)

            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }

        return nil
    }
    
    func generateBarcode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)

        if let filter = CIFilter(name: "CICode128BarcodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)

            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }

        return nil
    }
}

// MARK: - UIImagePicker Controller Delegate
extension ImagePicker: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.pickerController(picker, didSelect: nil, didSelect: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            self.pickerController(picker, didSelect: image, didSelect: nil)
        } else if let media = info[.mediaURL] as? URL {
            self.pickerController(picker, didSelect: nil, didSelect: media)
        }
    }
}

// MARK: - Image Vision Request
extension ImagePicker {
    func imageRequestHandler(pixelBuffer: CVImageBuffer) {
        let imageRequest = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        
        do {
            try imageRequest.perform([detectBarcodeRequest])
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func processClassification(_ request: VNRequest) {
        // TODO: Main logic
        guard let barcodes = request.results else {
            return
        }
        if barcodes.count == 0 {
            self.delegate?.didNotFind(error: "The QR or Barcode was not clear. Try another one.")
        }
        DispatchQueue.main.async { [self] in
            for barcode in barcodes {
                guard let potentialQRCode = barcode as? VNBarcodeObservation else { return }
                observationHandler(payload: potentialQRCode.payloadStringValue, symbology: potentialQRCode.symbology.rawValue)
            }
        }
    }
    
    // MARK: - Handler
    func observationHandler(payload: String?, symbology: String?) {
        guard let payloadString = payload, let symbology = symbology else {
            return
        }
        print("String: Url = \(payloadString)")
        if symbology.contains("QR") {
            if let qrImage = generateQRCode(from: payloadString) {
                delegate?.didFind(qrImage: qrImage, type: symbology, code: payloadString)
            }
        } else {
            if let barcodeImage = generateBarcode(from: payloadString) {
                delegate?.didFind(barcodeImage: barcodeImage, type: symbology, code: payloadString)
            }
        }
    }
}
