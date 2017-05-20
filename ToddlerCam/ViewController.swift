//
//  ViewController.swift
//  ToddlerCam
//
//  Created by Pit Garbe on 20.05.17.
//  Copyright © 2017 leberwurstsaft.de. All rights reserved.
//

import UIKit

import Photos.PHPhotoLibrary

import AVFoundation

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate {

    let captureSession = AVCaptureSession()
    var device: AVCaptureDevice?
    var cameraOutput: AVCapturePhotoOutput?

    var lastCapture: Date?

    override func viewDidLoad() {
        super.viewDidLoad()

        captureSession.sessionPreset = AVCaptureSessionPresetPhoto

        device = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back)

        beginSession()
    }

    func beginSession() {
        guard let device = device else { return}

        do {
            let deviceInput = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(deviceInput) {
                captureSession.addInput(deviceInput)
            }

            cameraOutput = AVCapturePhotoOutput()

            if captureSession.canAddOutput(cameraOutput) {
                captureSession.addOutput(cameraOutput)
            }

        } catch {
            print(error)
            return
        }

        if let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession) {
            view.layer.addSublayer(previewLayer)
            previewLayer.frame = view.layer.frame
        }
        captureSession.startRunning()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        let now = Date()

        if let lastCapture = lastCapture {
            if now.timeIntervalSince(lastCapture) < 0.5 {
                return
            }
        }

        lastCapture = now

        let settings = AVCapturePhotoSettings()
        if let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first {
            let previewFormat = [
                    kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                    kCVPixelBufferWidthKey as String: 160,
                    kCVPixelBufferHeightKey as String: 160
            ]
            settings.previewPhotoFormat = previewFormat
            cameraOutput?.capturePhoto(with: settings, delegate: self)
        }

    }

    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if let error = error {
            print("error occurred : \(error.localizedDescription)")
        }

        if let sampleBuffer = photoSampleBuffer,
           let previewBuffer = previewPhotoSampleBuffer,
           let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {

            let dataProvider = CGDataProvider(data: dataImage as CFData)
            let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
            let image = UIImage(cgImage: cgImageRef, scale: 1.0, orientation: UIImageOrientation.right)

            saveToCameraRoll(image: image)

            animateWhiteOverlay()
        }
        else {
            print("some error here")
        }
    }

    func animateWhiteOverlay {
        let whiteView = UIView(frame: view.frame)
        whiteView.backgroundColor = .white
        view.addSubview(whiteView)

        let animator = UIViewPropertyAnimator(duration: 0.2, curve: .easeOut) {
            whiteView.alpha = 0
        }

        animator.addCompletion { position in
            whiteView.removeFromSuperview()
        }

        animator.startAnimation(afterDelay: 0.2)
    }

    func saveToCameraRoll(image: UIImage) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }, completionHandler: { success, error in
            if success {
                // Saved successfully!
            }
            else if let error = error {
                // Save photo failed with error
            }
            else {
                // Save photo failed with no error
            }
        })
    }
}

