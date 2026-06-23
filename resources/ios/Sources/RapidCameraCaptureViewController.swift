import UIKit
import AVFoundation

class RapidCameraCaptureViewController: UIViewController {

    // MARK: - Capture Session

    private var captureSession: AVCaptureSession!
    private var photoOutput: AVCapturePhotoOutput!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var captureDevice: AVCaptureDevice!

    // Tracks the zoom factor at the start of a pinch so we can scale relative to it.
    private var zoomFactorAtPinchStart: CGFloat = 1.0

    // MARK: - UI

    private lazy var captureButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .white
        button.layer.cornerRadius = 35
        button.layer.borderWidth = 3
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        return button
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Close", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        button.layer.cornerRadius = 18
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(closeCamera), for: .touchUpInside)
        return button
    }()

    private lazy var flashView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.alpha = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        checkCameraAuthorization()
    }

    private func checkCameraAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCaptureSession()
                    } else {
                        self?.showPermissionDeniedAlert()
                    }
                }
            }
        case .denied, .restricted:
            showPermissionDeniedAlert()
        @unknown default:
            showCameraUnavailableAlert()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true {
            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.captureSession.stopRunning()
            }
        }
    }

    // MARK: - Camera Setup

    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device)
        else {
            showCameraUnavailableAlert()
            return
        }

        captureDevice = device

        captureSession.beginConfiguration()

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }

        // Match the native Camera app: allow the full computational-photography
        // pipeline (Deep Fusion, Smart HDR) and full-sensor resolution.
        photoOutput.maxPhotoQualityPrioritization = .quality

        if #available(iOS 16.0, *) {
            if let dimensions = device.activeFormat.supportedMaxPhotoDimensions.last {
                photoOutput.maxPhotoDimensions = dimensions
            }
        } else {
            photoOutput.isHighResolutionCaptureEnabled = true
        }

        captureSession.commitConfiguration()

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)

        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchToZoom(_:)))
        view.addGestureRecognizer(pinchGesture)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    // MARK: - Zoom

    @objc private func handlePinchToZoom(_ gesture: UIPinchGestureRecognizer) {
        guard let device = captureDevice else { return }

        if gesture.state == .began {
            zoomFactorAtPinchStart = device.videoZoomFactor
        }

        // Clamp between 1x and a sensible ceiling (the native app caps well below
        // the hardware max, which is mostly low-quality digital zoom).
        let maxZoomFactor = min(device.activeFormat.videoMaxZoomFactor, 8.0)
        let desiredZoomFactor = zoomFactorAtPinchStart * gesture.scale
        let clampedZoomFactor = max(1.0, min(desiredZoomFactor, maxZoomFactor))

        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = clampedZoomFactor
            device.unlockForConfiguration()
        } catch {
            // Unable to adjust zoom — ignore and keep the current factor.
        }
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.addSubview(flashView)
        view.addSubview(captureButton)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            flashView.topAnchor.constraint(equalTo: view.topAnchor),
            flashView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            flashView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            flashView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70),

            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 80),
            closeButton.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    // MARK: - Actions

    @objc private func capturePhoto() {
        guard let photoOutput else { return }

        captureButton.isEnabled = false

        // Force JPEG encoding so the saved .jpg file is a genuine JPEG
        // (the default would produce HEVC/HEIC on supported devices).
        let settings: AVCapturePhotoSettings
        if photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        } else {
            settings = AVCapturePhotoSettings()
        }

        // Prioritise quality over speed to match the native camera output.
        settings.photoQualityPrioritization = .quality

        if #available(iOS 16.0, *) {
            settings.maxPhotoDimensions = photoOutput.maxPhotoDimensions
        } else {
            settings.isHighResolutionPhotoEnabled = true
        }

        if photoOutput.supportedFlashModes.contains(.auto) {
            settings.flashMode = .auto
        }
        photoOutput.capturePhoto(with: settings, delegate: self)

        animateShutterFlash()
    }

    @objc private func closeCamera() {
        dismiss(animated: true)
    }

    // MARK: - Helpers

    private func animateShutterFlash() {
        flashView.alpha = 1.0
        UIView.animate(withDuration: 0.25, animations: {
            self.flashView.alpha = 0.0
        })
    }

    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Camera Access Required",
            message: "Please enable camera access in Settings to use this feature.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "Close", style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }

    private func showCameraUnavailableAlert() {
        let alert = UIAlertController(
            title: "Camera Unavailable",
            message: "Unable to access the camera on this device.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Close", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        DispatchQueue.main.async { [weak self] in
            self?.present(alert, animated: true)
        }
    }

    private func mobilePublicStorageURL() -> URL {
        let fileManager = FileManager.default
        // NativePHP's mobile_public disk maps to the persistent Documents/storage directory
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let storageURL = documentsURL.appendingPathComponent("storage", isDirectory: true)
        try? fileManager.createDirectory(at: storageURL, withIntermediateDirectories: true, attributes: nil)
        return storageURL
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension RapidCameraCaptureViewController: AVCapturePhotoCaptureDelegate {

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        defer {
            DispatchQueue.main.async { [weak self] in
                self?.captureButton.isEnabled = true
            }
        }

        guard error == nil, let data = photo.fileDataRepresentation() else { return }

        let uuid = UUID().uuidString
        let filename = "\(uuid).jpg"
        let fileURL = mobilePublicStorageURL().appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)

            let payload: [String: Any] = [
                "filename": filename,
                "path": fileURL.path,
            ]

            DispatchQueue.main.async {
                LaravelBridge.shared.send?(
                    "PTeal79\\RapidCameraCapture\\Events\\ImageCaptured",
                    payload
                )
            }
        } catch {
            // Photo could not be saved — silently ignore
        }
    }
}
