//
//  ViewController.swift
//  VisionOCR
//
//  Created by Christian on 6/27/19.
//  Copyright © 2019 Christian. All rights reserved.
//

import Foundation
import UIKit
import AVKit

internal class CameraViewController: UIViewController {
    
    @IBOutlet weak var cameraInputView: CameraInputView!
    
    private let captureSession: AVCaptureSession = AVCaptureSession()
    private let cameraQueue: DispatchQueue = DispatchQueue(label: "CameraQueue")
    private var currentCameraPosition: CameraPosition = .Unknown
    private var frontCamera: AVCaptureDevice?
    private var frontCameraInput: AVCaptureDeviceInput?
    private var rearCamera: AVCaptureDevice?
    private var rearCameraInput: AVCaptureDeviceInput?
    private var torchOn: Bool = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if authorizeCamera() {
            configureCamera()
        } else {
            //Replace this for code to be app store compliant
            exit(0)
        }
    }
    
    
    private func authorizeCamera() -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            
            var canAccessCamera: Bool = false
            
            let cameraAuthGroup = DispatchGroup()
            cameraAuthGroup.enter()
            
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                canAccessCamera = granted
                cameraAuthGroup.leave()
            }
            
            cameraAuthGroup.wait()
            
            return canAccessCamera
            
        case .restricted:
            return false
        case .denied:
            return false
        case .authorized:
            return true
        @unknown default:
            return false
        }
    }
    
    private func configureCamera() {
        
        DispatchQueue.main.async {
            self.cameraInputView.videoPreviewLayer.videoGravity = .resizeAspectFill
            self.cameraInputView.videoPreviewLayer.frame = self.view.layer.bounds
            self.cameraInputView.session = self.captureSession
        }
        
        cameraQueue.sync {
            
            captureSession.beginConfiguration()
            
            let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
            
            let cameras = discoverySession.devices.compactMap({$0})
            
            if !cameras.isEmpty {
                
                for camera in cameras {
                    if camera.position == .front {
                        frontCamera = camera
                    }
                    else if camera.position == .back {
                        rearCamera = camera
                    }
                }
                
                if let rearCamera = rearCamera {
                    do {
                        rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
                        
                        if let safeInput = rearCameraInput {
                            if captureSession.canAddInput(safeInput) {
                                captureSession.addInput(safeInput)
                                currentCameraPosition = .Rear
                            }
                            else {
                                print("Unable to add Rear Camera Input to session!")
                            }
                        } else {
                            print("Rear Camera Input was unsafe!")
                        }
                    }
                    catch let error {
                        print("Error Adding Rear Camera Input: \(error)")
                    }
                }
                
                if let frontCamera = frontCamera, currentCameraPosition == .Unknown {
                    do {
                        frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
                        
                        if let safeInput = frontCameraInput {
                            if captureSession.canAddInput(safeInput) {
                                captureSession.addInput(safeInput)
                                currentCameraPosition = .Front
                            }
                            else {
                                print("Unable to add Front Camera Input to session!")
                            }
                        }
                        else {
                            print("Front Camera Input was unsafe!")
                        }
                    }
                    catch let error {
                        print("Error Adding Front Camera Input: \(error)")
                    }
                }
                
                if currentCameraPosition == .Unknown {
                    //Replace this for code to be app store compiant
                    exit(2)
                }
                
                captureSession.commitConfiguration()
                
                self.startCamera()
                
            }
            else {
                //Replace this for code to be app store compliant
                exit(1)
            }
            
        }
    }
    
    private func startCamera() {
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }
    
    private func stopCamera() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    private func deconfigureCamera() {
        cameraQueue.sync {
            //Remove inputs
            for input in captureSession.inputs {
                captureSession.removeInput(input)
            }
            //Remove outputs
            for output in captureSession.outputs {
                captureSession.removeOutput(output)
            }
        }
    }
    
    @IBAction func tappedSwitchCamera(_ button: UIButton) {
        cameraQueue.sync {
            if currentCameraPosition == .Rear {
                
                guard let rearCameraInput = rearCameraInput, let frontCamera = frontCamera else {
                    return
                }
                
                if captureSession.inputs.contains(rearCameraInput) {
                    do {
                        frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
                        
                        if let safeInput = frontCameraInput {
                            captureSession.removeInput(rearCameraInput)
                            if captureSession.canAddInput(safeInput) {
                                captureSession.addInput(safeInput)
                                currentCameraPosition = .Front
                            }
                            else {
                                print("Unable to add front camera input to capture session.")
                                DispatchQueue.global().async {
                                    self.stopCamera()
                                    self.deconfigureCamera()
                                    self.configureCamera()
                                }
                                return
                            }
                        }
                        else {
                            print("Unable to find front camera input.")
                            return
                        }
                    }
                    catch let error {
                        print("Error initializing front camera device input: \(error.localizedDescription)")
                        return
                    }
                }
            }
            else if currentCameraPosition == .Front {
                guard let frontCameraInput = frontCameraInput, let rearCamera = rearCamera else {
                    return
                }
                
                if captureSession.inputs.contains(frontCameraInput) {
                    do {
                        rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
                        
                        if let safeInput = rearCameraInput {
                            captureSession.removeInput(frontCameraInput)
                            if captureSession.canAddInput(safeInput) {
                                captureSession.addInput(safeInput)
                                currentCameraPosition = .Rear
                            }
                            else {
                                print("Unable to add rear camera input to capture session.")
                                DispatchQueue.global().async {
                                    self.stopCamera()
                                    self.deconfigureCamera()
                                    self.configureCamera()
                                }
                                return
                            }
                        }
                        else {
                            print("Unable to find rear camera input.")
                            return
                        }
                    }
                    catch let error {
                        print("Error initializing rear camera device input: \(error.localizedDescription)")
                        return
                    }
                }
            }
        }
    }
    
    @IBAction func tappedToggleFlashlight(_ button: UIButton) {
        if currentCameraPosition == .Rear {
            if rearCamera?.hasTorch == true {
                do {
                    
                    try rearCamera?.lockForConfiguration()
                    
                    if torchOn {
                        rearCamera?.torchMode = .off
                        button.setImage(UIImage(systemName: "light.min"), for: .normal)
                        torchOn = false
                    }
                    else {
                        rearCamera?.torchMode = .on
                        button.setImage(UIImage(systemName: "light.max"), for: .normal)
                        torchOn = true
                    }
                    
                    rearCamera?.unlockForConfiguration()
                }
                catch let error {
                    print("Error toggling flashlight: \(error)")
                }
            }
        }
        else if currentCameraPosition == .Front {
            if frontCamera?.hasTorch == true {
                do {
                    try frontCamera?.lockForConfiguration()
                    
                    if torchOn {
                        frontCamera?.torchMode = .off
                        button.setImage(UIImage(systemName: "light.min"), for: .normal)
                        torchOn = false
                    }
                    else {
                        frontCamera?.torchMode = .on
                        button.setImage(UIImage(systemName: "light.max"), for: .normal)
                        torchOn = true
                    }
                    
                    frontCamera?.unlockForConfiguration()
                }
                catch let error {
                    print("Error toggling flashlight: \(error)")
                }
            }
        }
    }

}

