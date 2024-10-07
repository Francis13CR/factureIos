import UIKit
//
//  ViewController.swift
//
// Copyright 2023 (c) WebIntoApp.com
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in the
// Software without restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
// Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// Facture.cr
//
// Created by Facture.cr on 09/08/2023.
//
import WebKit

class FileDownloader {
    /**
            funcion para descargar y guardar un archivo desde la url dada
    */

    static func loadFileSync(
        url: URL, completion: @escaping (String?, Error?) -> Void
    ) {
        let documentsUrl = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask
        ).first!
        let destinationUrl = documentsUrl.appendingPathComponent(
            url.lastPathComponent)
        if FileManager().fileExists(atPath: destinationUrl.path) {
            print("EL archivo ya existe [\(destinationUrl.path)]")  //ya existre
            completion(destinationUrl.path, nil)
        } else if let dataFromURL = NSData(contentsOf: url) {
            if dataFromURL.write(to: destinationUrl, atomically: true) {
                print("Archivo guardado [\(destinationUrl.path)]")
                completion(destinationUrl.path, nil)
            } else {
                print("error al guardar archivo")
                let error = NSError(
                    domain: "Error al guardar archivo", code: 1001,
                    userInfo: nil)
                completion(destinationUrl.path, error)
            }
        } else {
            let error = NSError(
                domain: "Error al descargar archivo", code: 1002, userInfo: nil)
            completion(destinationUrl.path, error)
        }
    }
    static func loadFileAsync(
        url: URL, completion: @escaping (String?, Error?) -> Void
    ) {
        let documentsUrl = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask
        ).first!
        let destinationUrl = documentsUrl.appendingPathComponent(
            url.lastPathComponent)
        if FileManager().fileExists(atPath: destinationUrl.path) {
            print("el archivo ya existe [\(destinationUrl.path)]")
            completion(destinationUrl.path, nil)
        } else {
            let session = URLSession(
                configuration: URLSessionConfiguration.default, delegate: nil,
                delegateQueue: nil)
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            let task = session.dataTask(
                with: request,
                completionHandler: {
                    data, response, error in
                    if error == nil {
                        if let response = response as? HTTPURLResponse {
                            if response.statusCode == 200 {
                                if let data = data {
                                    if (try? data.write(
                                        to: destinationUrl,
                                        options: Data.WritingOptions.atomic))
                                        != nil
                                    {
                                        completion(destinationUrl.path, error)
                                    } else {
                                        completion(destinationUrl.path, error)
                                    }
                                } else {
                                    completion(destinationUrl.path, error)
                                }
                            }
                        }
                    } else {
                        completion(destinationUrl.path, error)
                    }
                })
            task.resume()
        }
    }
}
//convertir los pares clave-valor en el diccionario a una cadena de consulta URL-encodificada. Cada par clave-valor se convierte en una cadena "clave=valor" y se escapan los caracteres especiales que no son seguros en una URL.
extension Dictionary {
    func percentEscaped() -> String {
        return map { (key, value) in
            let escapedKey =
                "\(key)".addingPercentEncoding(
                    withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue =
                "\(value)".addingPercentEncoding(
                    withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
    }
}
extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@"  // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(
            charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)"
        )
        return allowed
    }()
}
//Esta función formatea el número Double eliminando los ceros redundantes al final de la parte fraccional.
extension Double {
    func removeZerosFromEnd() -> String {
        let formatter = NumberFormatter()
        let number = NSNumber(value: self)
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 16  //maximum digits in Double after dot (maximum precision)
        return String(formatter.string(from: number) ?? "")
    }
}
extension UIApplication {
    var statusBarView: UIView? {
        return value(forKey: "statusBar") as? UIView
    }
}
extension UINavigationBar {
    func customNavigationBar() {
        self.tintColor = UIColor(rgb: 0xffffff)
        self.barTintColor = UIColor(rgb: 0x79a5ed)
        self.isTranslucent = false
        self.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor(rgb: 0xffffff)
        ]
        self.setBackgroundImage(UIImage(), for: .default)
        self.shadowImage = UIImage()
    }
}
extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        self.init(
            red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}
class ViewController: UIViewController, WKNavigationDelegate, WKUIDelegate,
    UIDocumentInteractionControllerDelegate, UIGestureRecognizerDelegate,
    WKScriptMessageHandler
{
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        // recibir llmadas del js
        if message.name == "openScanner" {
            // Abrir el escáner cuando se presione el botón
            openBarcodeScanner()
        }
    }

    var window: UIApplication!
    var statusBar: UIView!
    var documentInteractionController: UIDocumentInteractionController?
    override func viewWillTransition(
        to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator
    ) {
        super.viewWillTransition(to: size, with: coordinator)
        if UIDevice.current.orientation.isLandscape {
            print("Landscape")
            self.statusBar.isHidden = true
        } else {
            print("Portrait")
            self.statusBar.isHidden = false
        }
    }
    var webView: WKWebView!
    var webViewSplashScreen: WKWebView!
    var useSplashScreen: Bool! = true
    var loadingError: Bool! = false
    let refreshControl = UIRefreshControl()
    @objc func reloadWebView(_ sender: UIRefreshControl) {  //recargar en caso de que exista error
        if loadingError == true {
            loadingError = false
            self.LoadWebView()
        } else {
            webView.reload()
        }
        refreshControl.endRefreshing()
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    override func loadView() {
        print("-loadView")
        super.loadView()
        navigationController?.navigationBar.barStyle = .black
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.filter { $0.isKeyWindow }
                .first
            statusBar = UIView(
                frame: window?.windowScene?.statusBarManager?.statusBarFrame
                    ?? CGRect.zero)
            statusBar.backgroundColor = UIColor(rgb: 0x303030)
            window?.addSubview(statusBar)
        } else {
            UIApplication.shared.statusBarView?.backgroundColor = UIColor(
                rgb: 0x303030)
            UIApplication.shared.statusBarStyle = .lightContent
        }
        let refresh = UIBarButtonItem(
            barButtonSystemItem: .refresh, target: webView,
            action: #selector(reloadWebView))
        let back = UIBarButtonItem(
            title: "Back", style: .plain, target: webView,
            action: #selector(self.webView!.goBack))
        self.navigationItem.rightBarButtonItem = refresh
        self.navigationItem.leftBarButtonItem = back
        self.navigationItem.title = "Facture.cr"
        self.navigationController?.isNavigationBarHidden = true
        /*
        print("webView didFinish")
        let add = UIAction(title: "Add", image: UIImage(systemName: "plus")) { (action) in
            print("Add")
        }
        let edit = UIAction(title: "Edit", image: UIImage(systemName: "pencil")) { (action) in
            print("Edit")
        }
        let delete = UIAction(title: "Delete", image: UIImage(systemName: "minus"), attributes: .destructive) { (action) in
            print("Delete")
        }
        let menu = UIMenu(title: "Menu", children: [add, edit, delete])
        let refresh = UIBarButtonItem(title: "Delete", image: UIImage(systemName: "minus"))
        refresh.menu = menu
        let back = UIBarButtonItem(title: "Back", style: .plain, target: webView, action: #selector(self.webView!.goBack))
        let customImageBarBtn1 = UIBarButtonItem(
            image: UIImage(named: "AppIcon"),
            style: .plain, target: self, action: #selector(self.webView!.goBack))
        self.navigationItem.title = "Facture.cr"
        self.navigationItem.rightBarButtonItem = refresh
        self.navigationItem.leftBarButtonItem = customImageBarBtn1
        self.navigationController?.isNavigationBarHidden = true
        */
        self.webView = WKWebView(frame: self.view.frame)
        self.webViewSplashScreen = WKWebView(frame: self.view.frame)
    }
    @objc func backNavigationFunction(
        _ sender: UIScreenEdgePanGestureRecognizer
    ) {
        let dX = sender.translation(in: view).x
        if sender.state == .ended {
            let fraction = abs(dX / view.bounds.width)
            if fraction >= 0.35 {
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let swipeGesture = UIScreenEdgePanGestureRecognizer(
            target: self, action: #selector(backNavigationFunction(_:)))
        swipeGesture.edges = .left
        swipeGesture.delegate = self
        view.addGestureRecognizer(swipeGesture)
        print("-viewDidLoad")
        let webConfiguration = WKWebViewConfiguration()

        // Configurar el manejador de mensajes de JavaScript
        webConfiguration.userContentController.add(self, name: "openScanner")

        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self

        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false

        if useSplashScreen == true {
            print("Load with splash screen")
            view = webViewSplashScreen
            let localFilePath = Bundle.main.url(
                forResource: "loading", withExtension: "html",
                subdirectory: "htmlapp/helpers")
            let request = NSURLRequest(url: localFilePath!)
            webViewSplashScreen.navigationDelegate = self
            webViewSplashScreen.uiDelegate = self
            webViewSplashScreen.load(request as URLRequest)
        } else {
            self.LoadWebView()
        }
        NotificationCenter.default.addObserver(
            self, selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    // Método para abrir el escáner de códigos de barras
    func openBarcodeScanner() {
        let scannerVC = BarcodeScannerViewController()
        scannerVC.webView = webView  // Pasar la WebView para que el escáner pueda comunicarse con el JS
        present(scannerVC, animated: true, completion: nil)
    }
    @objc func applicationDidBecomeActive(notification: NSNotification) {
        print("active")
        if let run_first_exists = UserDefaults.standard.object(
            forKey: "first_run")
        {
            print("first_run is: \(run_first_exists)")
        } else {
        }
    }
    //funcion para cargar la vista de la web
    @objc func LoadWebView() {
        print("-LoadWebView")
        // Configuración de UIRefreshControl para permitir el usuario recargar la página tirando hacia abajo
        refreshControl.addTarget(
            self, action: #selector(reloadWebView(_:)), for: .valueChanged)
        webView.scrollView.addSubview(refreshControl)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        let source: String =
            "var meta = document.createElement('meta');"
            + "meta.name = 'viewport';"
            + "meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';"
            + "var head = document.getElementsByTagName('head')[0];"
            + "head.appendChild(meta);"
        let script: WKUserScript = WKUserScript(
            source: source, injectionTime: .atDocumentEnd,
            forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(script)
        //francis.oficina.facture.cr/app/
        //staging.facture.cr/app/
        //facture.cr/app/
        let url = URL(string: "https://francis.oficina.facture.cr/app/")!
        webView.load(URLRequest(url: url))
        webView.allowsBackForwardNavigationGestures = true
    }
    func webView(
        _ webView: WKWebView,
        didStartProvisionalNavigation navigation: WKNavigation!
    ) {
        print(
            "didStartProvisionalNavigation - webView.url: \(String(describing: webView.url?.description))"
        )
    }
    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        let nserror = error as NSError
        // No cargar la página de error si la navegación fue cancelada
        if nserror.code == NSURLErrorCancelled {
            return
        }
        // Manejar otros errores
        let localFilePath = Bundle.main.url(
            forResource: "error", withExtension: "html",
            subdirectory: "htmlapp/helpers")
        let request = NSURLRequest(url: localFilePath!)
        webView.load(request as URLRequest)
        loadingError = true
    }
    func showFileWithPath(path: String) {
        let isFileFound = FileManager.default.fileExists(atPath: path)
        if isFileFound {
            let viewer = UIDocumentInteractionController(
                url: URL(fileURLWithPath: path))
            viewer.delegate = self
            viewer.presentPreview(animated: true)
        } else {
            print("No se encontró el archivo en la ruta especificada.")
        }

    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if let frame = navigationAction.targetFrame,
            frame.isMainFrame
        {
            return nil
        }
        webView.load(navigationAction.request)
        return nil
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView == self.webViewSplashScreen {
            print("webViewSplashScreen didFinish")
            self.LoadWebView()
        }
        if webView == self.webView {
            print("webView didFinish")
            view = webView
        }
    }
    func documentInteractionControllerViewControllerForPreview(
        _ controller: UIDocumentInteractionController
    ) -> UIViewController {
        UINavigationBar.appearance().barTintColor = UIColor(rgb: 0x79a5ed)
        UINavigationBar.appearance().tintColor = UIColor(rgb: 0x79a5ed)
        UINavigationBar.appearance().titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor(rgb: 0x79a5ed),
            NSAttributedString.Key.font: UIFont.systemFont(
                ofSize: 14, weight: UIFont.Weight.bold),
        ]
        return self
    }
    func documentInteractionControllerViewForPreview(
        _ controller: UIDocumentInteractionController
    ) -> UIView? {
        return view
    }

    func documentInteractionControllerRectForPreview(
        _ controller: UIDocumentInteractionController
    ) -> CGRect {
        return view.frame
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {

        if let url = navigationAction.request.url,
            url.absoluteString.contains("downloadPDF.php")
        {
            // Si es un enlace de descarga de PDF, cancelamos la navegación
            decisionHandler(.cancel)

            // Llamamos a la función para descargar el archivo
            downloadPDF(from: url)
        } else {
            // Permite la navegación para otras URL
            decisionHandler(.allow)
        }
    }

    // Función para descargar el archivo PDF
    func downloadPDF(from url: URL) {
        // Crear una alerta de "Descargando..."
        let alert = UIAlertController(
            title: nil, message: "El archivo se encuentra descargando...",
            preferredStyle: .alert)

        let loadingIndicator = UIActivityIndicatorView(
            frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()

        alert.view.addSubview(loadingIndicator)

        // Mostrar la alerta de "Descargando..."
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }

        // Inicia la descarga del PDF con URLSession
        let task = URLSession.shared.downloadTask(with: url) {
            tempLocation, response, error in
            DispatchQueue.main.async {
                // Cerrar la alerta de "Descargando..." una vez que la descarga se complete
                alert.dismiss(animated: true, completion: nil)
            }

            if let tempLocation = tempLocation, error == nil {
                let documentsUrl = FileManager.default.urls(
                    for: .documentDirectory, in: .userDomainMask
                ).first!

                // Obtener el nombre de archivo desde la cabecera Content-Disposition, si está disponible
                var destinationFilename = url.lastPathComponent
                if let httpResponse = response as? HTTPURLResponse,
                    let contentDisposition = httpResponse.allHeaderFields[
                        "Content-Disposition"] as? String
                {
                    destinationFilename =
                        self.extractFilenameFrom(
                            contentDisposition: contentDisposition)
                        ?? destinationFilename
                }

                let destinationUrl = documentsUrl.appendingPathComponent(
                    destinationFilename)

                do {
                    // Verificar si el archivo ya existe y eliminarlo si es necesario
                    if FileManager.default.fileExists(
                        atPath: destinationUrl.path)
                    {
                        try FileManager.default.removeItem(at: destinationUrl)
                    }

                    // Mover el archivo descargado a la ruta de destino
                    try FileManager.default.moveItem(
                        at: tempLocation, to: destinationUrl)

                    // Notificar al usuario que la descarga se ha completado
                    DispatchQueue.main.async {
                        let alertController = UIAlertController(
                            title: "Descarga completada",
                            message:
                                "El archivo se ha descargado correctamente.",
                            preferredStyle: .alert)
                        alertController.addAction(
                            UIAlertAction(
                                title: "OK", style: .default,
                                handler: { (_) in
                                    // Abrir el archivo descargado si es necesario
                                    self.showFileWithPath(
                                        path: destinationUrl.path)
                                }))
                        self.present(
                            alertController, animated: true, completion: nil)
                    }
                } catch {
                    print(
                        "Error al mover el archivo descargado: \(error.localizedDescription)"
                    )
                }
            } else {
                print(
                    "Error al descargar el archivo: \(error?.localizedDescription ?? "Error desconocido")"
                )
            }
        }

        task.resume()
    }

    // Función para mostrar el PDF
    func showPDF(at url: URL) {
        documentInteractionController = UIDocumentInteractionController(
            url: url)
        documentInteractionController?.delegate = self
        documentInteractionController?.presentPreview(animated: true)
    }

    func extractFilenameFrom(contentDisposition: String) -> String? {
        // La cabecera Content-Disposition puede tener este formato:
        // attachment; filename="nombre.pdf"
        let components = contentDisposition.components(separatedBy: ";")
        for component in components {
            let trimmedComponent = component.trimmingCharacters(
                in: .whitespacesAndNewlines)
            if trimmedComponent.starts(with: "filename=") {
                var filename = trimmedComponent.replacingOccurrences(
                    of: "filename=", with: "")
                // Remover comillas si es necesario
                filename = filename.trimmingCharacters(
                    in: CharacterSet(charactersIn: "\""))
                return filename
            }
        }
        return nil
    }

}
