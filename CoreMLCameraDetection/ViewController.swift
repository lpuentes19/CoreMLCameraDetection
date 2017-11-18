//
//  ViewController.swift
//  CoreMLCameraDetection
//
//  Created by Luis Puentes on 11/17/17.
//  Copyright © 2017 LuisPuentes. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let labelIdentifier: UILabel = {
        let label = UILabel()
        label.backgroundColor = .black
        label.textColor = .white
        label.textAlignment = .center
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(labelIdentifier)

        // Where we start the camera
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        
        captureSession.addInput(input)
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
        setupLabelConstraints()
    }
    
    func setupLabelConstraints() {
        labelIdentifier.topAnchor.constraint(equalTo: view.topAnchor, constant: 600).isActive = true
        labelIdentifier.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10).isActive = true
        labelIdentifier.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        labelIdentifier.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        labelIdentifier.widthAnchor.constraint(equalToConstant: 350).isActive = true
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else { return }
        let request = VNCoreMLRequest(model: model) { (finRequest, error) in
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            guard let results = finRequest.results as? [VNClassificationObservation] else { return }
            guard let firstObservation = results.first else { return }
            
            DispatchQueue.main.async {
                self.labelIdentifier.text = "\(firstObservation.identifier, (firstObservation.confidence * 100).rounded())"
            }
        }
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
}

