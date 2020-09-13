// https://github.com/twostraws/CodeScanner/blob/main/Sources/CodeScanner/CodeScanner.swift
// Due to the modifications needed for this particular usage,
// it's just much easier to do a copy-over.

//
//  CodeScannerView.swift
//
//  Created by Paul Hudson on 10/12/2019.
//  Copyright © 2019 Paul Hudson. All rights reserved.
//
import AVFoundation
import SwiftUI

/// A SwiftUI view that is able to scan barcodes, QR codes, and more, and send back what was found.
/// To use, set `codeTypes` to be an array of things to scan for, e.g. `[.qr]`, and set `completion` to
/// a closure that will be called when scanning has finished. This will be sent the string that was detected or a `ScanError`.
/// For testing inside the simulator, set the `simulatedData` property to some test data you want to send back.
public struct CodeScannerView: UIViewControllerRepresentable {
  public enum ScanError: Error {
    case badInput, badOutput
  }

  public class ScannerCoordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    var parent: CodeScannerView
    var codeFound = ""
    var timer: Timer? = nil

    init(parent: CodeScannerView) {
      self.parent = parent
    }

    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
      if let metadataObject = metadataObjects.first {
        guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
        guard let stringValue = readableObject.stringValue else { return }
        guard codeFound != stringValue else { return }

        if timer != nil { timer?.invalidate() }
        
        found(code: stringValue)

        // make sure we only trigger scans once per use
        codeFound = stringValue
        timer = Timer.scheduledTimer(withTimeInterval: 7, repeats: false) { [self] _ in
          self.codeFound = ""
          self.timer?.invalidate()
          self.timer = nil
        }
      }
    }

    func found(code: String) {
      parent.completion(.success(code))
    }

    func didFail(reason: ScanError) {
      parent.completion(.failure(reason))
    }
  }

  #if targetEnvironment(simulator)
  public class ScannerViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    var delegate: ScannerCoordinator?
    override public func loadView() {
      view = UIView()
      view.isUserInteractionEnabled = true
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      label.numberOfLines = 0

      label.text = "You're running in the simulator, which means the camera isn't available. Tap anywhere to send back some simulated data."
      label.textAlignment = .center

      let stackView = UIStackView()
      stackView.translatesAutoresizingMaskIntoConstraints = false
      stackView.axis = .vertical
      stackView.spacing = 50
      stackView.addArrangedSubview(label)
      stackView.addArrangedSubview(button)

      view.addSubview(stackView)

      NSLayoutConstraint.activate([
        button.heightAnchor.constraint(equalToConstant: 50),
        stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
        stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
        stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
      ])
    }

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
      guard let simulatedData = delegate?.parent.simulatedData else {
        print("Simulated Data Not Provided!")
        return
      }

      delegate?.found(code: simulatedData)
    }
  }
  #else
  public class ScannerViewController: UIViewController {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var delegate: ScannerCoordinator?

    override public func viewDidLoad() {
      super.viewDidLoad()


      NotificationCenter.default.addObserver(self,
                                             selector: #selector(updateOrientation),
                                             name: Notification.Name("UIDeviceOrientationDidChangeNotification"),
                                             object: nil)

      view.backgroundColor = UIColor.black
      captureSession = AVCaptureSession()
      captureSession.sessionPreset = .photo

      guard let videoCaptureDevice = AVCaptureDevice.default(
        .builtInWideAngleCamera,
        for: .video,
        position: .front
      ) else { return }
      let videoInput: AVCaptureDeviceInput

      do {
        videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
      } catch {
        return
      }

      if (captureSession.canAddInput(videoInput)) {
        captureSession.addInput(videoInput)
      } else {
        delegate?.didFail(reason: .badInput)
        return
      }

      let metadataOutput = AVCaptureMetadataOutput()

      if (captureSession.canAddOutput(metadataOutput)) {
        captureSession.addOutput(metadataOutput)

        metadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = delegate?.parent.objectTypes
      } else {
        delegate?.didFail(reason: .badOutput)
        return
      }
    }

    override public func viewWillLayoutSubviews() {
      previewLayer?.frame = view.layer.bounds
    }

    @objc func updateOrientation() {
      guard let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation else { return }
      guard let connection = captureSession.connections.last, connection.isVideoOrientationSupported else { return }
      connection.videoOrientation = AVCaptureVideoOrientation(rawValue: orientation.rawValue) ?? .portrait
    }

    override public func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(animated)
      previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
      previewLayer.frame = view.layer.bounds
      previewLayer.videoGravity = .resizeAspectFill
      view.layer.addSublayer(previewLayer)
      updateOrientation()
      captureSession.startRunning()
    }

    override public func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)

      if (captureSession?.isRunning == false) {
        captureSession.startRunning()
      }
    }

    override public func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)

      if (captureSession?.isRunning == true) {
        captureSession.stopRunning()
      }

      NotificationCenter.default.removeObserver(self)
    }

    override public var prefersStatusBarHidden: Bool {
      return true
    }

    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
      return .all
    }
  }
  #endif

  public let objectTypes: [AVMetadataObject.ObjectType]
  public var simulatedData = ""
  public var completion: (Result<String, ScanError>) -> Void

  public init(objectTypes: [AVMetadataObject.ObjectType], simulatedData: String = "", completion: @escaping (Result<String, ScanError>) -> Void) {
    self.objectTypes = objectTypes
    self.simulatedData = simulatedData
    self.completion = completion
  }

  public func makeCoordinator() -> ScannerCoordinator {
    return ScannerCoordinator(parent: self)
  }

  public func makeUIViewController(context: Context) -> ScannerViewController {
    let viewController = ScannerViewController()
    viewController.delegate = context.coordinator
    return viewController
  }

  public func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {

  }
}

struct CodeScannerView_Previews: PreviewProvider {
  static var previews: some View {
    CodeScannerView(objectTypes: [.qr]) { result in
      // do nothing
    }
  }
}
