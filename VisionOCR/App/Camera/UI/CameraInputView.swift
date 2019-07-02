//
//  CameraInputView.swift
//  VisionOCR
//
//  Created by Christian Elfreich on 6/27/19.
//  Copyright © 2019 Christian. All rights reserved.
//

import UIKit
import AVKit

class CameraInputView: UIView {

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
        }
        
        return layer
    }
    
    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }

}
