import UIKit
import AVFoundation

class AddItemViewController: UIViewController {
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "session queue")
    private var isSessionRunning = false
    private var setupResult: SessionSetupResult = .success { didSet { print("setupResult: \(setupResult)") }}
    private var videoDeviceInput: AVCaptureDeviceInput!
    private let photoOutput = AVCapturePhotoOutput()
    private var inProgressPhotoCaptureDelegates = [Int64: PhotoCaptureProcessor]()
    private let previewView = PreviewView().autolayout()
    private let textView = UITextView().autolayout()

    var doneHandler: () -> () = { }
    var capturedImage: UIImage? {
        didSet {
            navigationItem.leftBarButtonItem?.isEnabled = capturedImage != nil
        }
    }
    var caption: String {
        return textView.text ?? ""
    }
    
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .lightGray
        setupPreviewView()
        view.addSubview(previewView)
        
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.heightAnchor.constraint(equalTo: view.widthAnchor) ])
        
        requestAuthorizarion()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(donePressed))
        navigationItem.leftBarButtonItem?.isEnabled = false
        
        navigationController?.navigationBar.standardAppearance.backgroundColor = .clear
        navigationController?.navigationBar.standardAppearance.backgroundEffect = .none
        navigationController?.navigationBar.standardAppearance.shadowColor = .clear
        
        view.addSubview(textView)
        textView.text = "test"
        textView.font = UIFont.preferredFont(forTextStyle: .headline)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: previewView.bottomAnchor, constant: 8),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        sessionQueue.async {
            self.configureSession()
        }
    }
    
    @objc private func donePressed() {
        doneHandler()
    }
    
    private func setupPreviewView() {
        previewView.session = session
        previewView.backgroundColor = .black
        previewView.captureButton.addTarget(self, action: #selector(captureButtonPress), for: .touchUpInside)
    }
    
    private func requestAuthorizarion() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
            
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
            
        default:
            setupResult = .notAuthorized
        }
    }
    
    private func configureSession() {
        if setupResult != .success {
            return
        }
        
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        guard let videoDevice = setupDefaultDevice() else {
            print("Default video device is unavailable.")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                DispatchQueue.main.async {
                    var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                    if self.windowOrientation != .unknown {
                        if let videoOrientation = AVCaptureVideoOrientation.init(rawValue: self.windowOrientation.rawValue) {
                            initialVideoOrientation = videoOrientation
                        }
                    }
                    self.previewView.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
                }
            } else {
                print("Couldn't add video device input to the session.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
        } catch {
            print("Couldn't create video device input: \(error)")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
            photoOutput.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliverySupported
            photoOutput.isPortraitEffectsMatteDeliveryEnabled = photoOutput.isPortraitEffectsMatteDeliverySupported
            photoOutput.enabledSemanticSegmentationMatteTypes = photoOutput.availableSemanticSegmentationMatteTypes
            photoOutput.maxPhotoQualityPrioritization = .quality
        } else {
            print("Could not add photo output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        session.commitConfiguration()
        print("Session has been configured")
    }
    
    private func setupDefaultDevice() -> AVCaptureDevice? {
        if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
            return dualCameraDevice
        } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            return backCameraDevice
        } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            return frontCameraDevice
        } else { return nil }
    }
    
    var windowOrientation: UIInterfaceOrientation {
        return view.window?.windowScene?.interfaceOrientation ?? .unknown
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sessionQueue.async {
            switch self.setupResult {
            case .success:
                // Only setup observers and start the session if setup succeeded.
                self.addObservers()
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
                
            case .notAuthorized:
                DispatchQueue.main.async {
                    let changePrivacySetting = "AVCam doesn't have permission to use the camera, please change privacy settings"
                    let message = NSLocalizedString(changePrivacySetting, comment: "Alert message when the user has denied access to the camera")
                    let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                            style: .cancel,
                                                            handler: nil))
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"),
                                                            style: .`default`,
                                                            handler: { _ in
                                                                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                                                          options: [:],
                                                                                          completionHandler: nil)
                    }))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
                
            case .configurationFailed:
                DispatchQueue.main.async {
                    let alertMsg = "Alert message when something goes wrong during capture session configuration"
                    let message = NSLocalizedString("Unable to capture media", comment: alertMsg)
                    let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                            style: .cancel,
                                                            handler: nil))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    private var keyValueObservations = [NSKeyValueObservation]()
    
    private func addObservers() {
        let keyValueObservation = session.observe(\.isRunning, options: .new) { _, change in
            guard let isSessionRunning = change.newValue else { return }
            DispatchQueue.main.async {
                self.previewView.captureButton.isEnabled = isSessionRunning
                print("isSessionRunning: \(isSessionRunning)")
            }
        }
        keyValueObservations.append(keyValueObservation)
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
        
        for keyValueObservation in keyValueObservations {
            keyValueObservation.invalidate()
        }
        keyValueObservations.removeAll()
    }

    override func viewWillDisappear(_ animated: Bool) {
        sessionQueue.async {
            if self.setupResult == .success {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
                self.removeObservers()
            }
        }
        
        super.viewWillDisappear(animated)
    }
 
    @objc private func captureButtonPress() {
        let videoPreviewLayerOrientation = previewView.videoPreviewLayer.connection?.videoOrientation
        sessionQueue.async {
            if let photoOutputConnection = self.photoOutput.connection(with: .video) {
                photoOutputConnection.videoOrientation = videoPreviewLayerOrientation!
            }
            var photoSettings = AVCapturePhotoSettings()
                        
            if self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            }
            
            if self.videoDeviceInput.device.isFlashAvailable {
                photoSettings.flashMode = .auto
            }
            
            photoSettings.isHighResolutionPhotoEnabled = true
            if !photoSettings.__availablePreviewPhotoPixelFormatTypes.isEmpty {
                photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.__availablePreviewPhotoPixelFormatTypes.first!]
            }
            
            let photoCaptureProcessor = PhotoCaptureProcessor(with: photoSettings, completionHandler: { processor, data in
                self.inProgressPhotoCaptureDelegates[processor.requestedPhotoSettings.uniqueID] = nil
                if let data = data {
                    self.capturedImage = UIImage(data: data)
                }
                
                // Flash the screen to signal that AVCam took a photo.
                DispatchQueue.main.async {
                    self.previewView.videoPreviewLayer.opacity = 0
                    UIView.animate(withDuration: 0.25) {
                        self.previewView.videoPreviewLayer.opacity = 1
                    }
                }
            })
                    
            self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = photoCaptureProcessor
            self.photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureProcessor)
        }
    }
}


class PreviewView: UIView {
    
    let captureButton: UIButton
    
    init() {
        captureButton = UIButton(type: .custom).autolayout()
        super.init(frame: .zero)
        
        captureButton.setImage(UIImage(named: "CapturePhoto"), for: .normal)
        
        addSubview(captureButton)
        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            captureButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            captureButton.widthAnchor.constraint(equalToConstant: 50),
            captureButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer")
        }
        layer.videoGravity = .resizeAspectFill
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
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}
