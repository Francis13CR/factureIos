//
//  BarcodeScanner.swift
//  Facture.cr
//
//  Created by Francis Melendez on 7/10/24.
//  Copyright © 2024 Facture.cr. All rights reserved.
//import UIKit
import UIKit
import AVFoundation
import WebKit

class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var webView: WKWebView!
    
    // Título o etiqueta que aparecerá mientras se escanea
    var scanTitleLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Inicializar la sesión de captura
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            print("No se pudo añadir la entrada de video.")
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417, .code128] // Tipos de códigos de barras
        } else {
            print("No se pudo añadir la salida de metadatos.")
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        // Iniciar la sesión de captura
        captureSession.startRunning()

        // Configurar el título o etiqueta
        setupScanTitleLabel()
    }

    // Configuración de la etiqueta para el título
    func setupScanTitleLabel() {
        scanTitleLabel = UILabel()
        scanTitleLabel.text = "Escaneando Código de Barras"
        scanTitleLabel.textColor = .white
        scanTitleLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        scanTitleLabel.textAlignment = .center
        scanTitleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        
        // Configurar el tamaño y posición de la etiqueta
        scanTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scanTitleLabel)
        
        // Agregar restricciones para centrar la etiqueta horizontalmente y colocarla en la parte superior
        NSLayoutConstraint.activate([
            scanTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scanTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scanTitleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            scanTitleLabel.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // Método delegado llamado cuando se escanea un código
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }

            captureSession.stopRunning()

            // Llamar al método para enviar el resultado a la página web en JavaScript
            sendToJavaScript(code: stringValue)
        }
    }

    // Método para enviar el resultado al JS en la WebView
    func sendToJavaScript(code: String) {
        let jsCode = "handleBarcodeScanned('\(code)');"
        webView.evaluateJavaScript(jsCode, completionHandler: nil)

        // Opcional: cerrar el escáner o navegar de regreso a la WebView
        dismiss(animated: true, completion: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }
}
