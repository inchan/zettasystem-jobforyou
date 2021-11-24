//
//  ViewController.swift
//  JobForYou
//
//  Created by inchan on 2021/08/20.
//

import UIKit
import WebKit
import QuickLook


class ViewController: UIViewController {

    @IBOutlet weak var webview: WKWebView! {
        willSet {
            if webview == nil {
                newValue.uiDelegate = self
                newValue.navigationDelegate = self
            }
        }
    }
    
    @IBOutlet weak var toolBar: UIToolbar! {
        willSet {
            if toolBar == nil {
                newValue.isHidden = true;
            }
        }
    }
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView! {
        willSet {
            if activityIndicatorView == nil {
                newValue.startAnimating()
            }
        }
    }

    var userAgentIdentifier: String {
        return ";JFYIOS"
    }
    
    var documentPreviewController = QLPreviewController()
    lazy var previewItem = NSURL()


    var webViewCookieStore: WKHTTPCookieStore!
    let webViewConfiguration = WKWebViewConfiguration()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        webview.allowsBackForwardNavigationGestures = true
        webview.defaultUserAgent { [weak self] userAgent in
            guard let strongSelf = self else { return }
            let customUserAgent = userAgent + " \(strongSelf.userAgentIdentifier)"
            strongSelf.webview.customUserAgent = customUserAgent
            if let customUserAgent = strongSelf.webview.customUserAgent {
                prettyLog(title: "Custom Useragent", value: customUserAgent)
            }
            strongSelf.goHome()

        }
        
        
        // initial configuration of custom JavaScripts
        //webViewConfiguration.userContentController = userContentController


        // QuickLook document preview
        documentPreviewController.dataSource  = self

        webViewCookieStore = webview.configuration.websiteDataStore.httpCookieStore


    }
    
    func go(_ urlString: String) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webview.load(request)
        }
    }
    
    func goHome() {
        go(URLs.home)
    }

}

extension ViewController: WKUIDelegate, WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        activityIndicatorView.isHidden = false
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        activityIndicatorView.isHidden = true
        if webview.isHidden {
            webview.isHidden = false
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicatorView.isHidden = true
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        var messages = [String]();
        messages.append("  - URL        : \(url.absoluteString)")

        
        if let allHTTPHeaderFields = navigationAction.request.allHTTPHeaderFields {
            messages.append("  - Header     : \n\(allHTTPHeaderFields.map({ "       \($0.key): \($0.value)"}).joined(separator: "\n"))")
            let hasJFYiOS = allHTTPHeaderFields.values.filter({ $0.hasSuffix(userAgentIdentifier)}).count > 0
            messages.append("  - hasJFYIOS  : \(hasJFYiOS)")

        }
        
        let isBlank = url.absoluteString == "about:blank"
        if isBlank == false {
            let message = "\n" + messages.joined(separator: "\n")
            prettyLog(title: "WebView Request", value: message)
        }

        
        enum PublicSchemes: String, CaseIterable {
            case tel, mailto, sms, facetime
        }
        
        if PublicSchemes.allCases
            .map({ $0.rawValue })
            .contains(url.scheme), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
            return;
        }
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        prettyLog(title: "WebView runJavaScriptAlertPanelWithMessage", value: message)
        completionHandler()
    }
    
    /*
     Intercept decision handling to be able to present documents in QuickLook preview
     Needs to be intercepted here, because I need the suggestedFilename for download
     */
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        let url = navigationResponse.response.url
        if (openInDocumentPreview(url!)) {
            webview.downloadfile(remote: url!, completion: {(success, fileLocationURL) in
                DispatchQueue.main.async {
                    if success {
                        // Set the preview item to display======
                        self.previewItem = fileLocationURL! as NSURL
                        // Display file
                        let previewController = QLPreviewController()
                        previewController.dataSource = self
                        self.present(previewController, animated: true, completion: nil)
                    }else{
                        debugPrint("File can't be downloaded")
                    }
                }
                
            })
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
  
    func getPreviewItem(withName name: String) -> NSURL{
        
        //  Code to diplay file from the app bundle
        let file = name.components(separatedBy: ".")
        let path = Bundle.main.path(forResource: file.first!, ofType: file.last!)
        let url = NSURL(fileURLWithPath: path!)
        
        return url
    }
//
//    func downloadfile(url: URL, completion: @escaping (_ success: Bool,_ fileLocation: URL?) -> Void){
//
//        // then lets create your document folder url
//        let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//
//        // lets create your destination file url
//        let destinationUrl = documentsDirectoryURL.appendingPathComponent(url.lastPathComponent)
//
//        // to check if it exists before downloading it
//        if FileManager.default.fileExists(atPath: destinationUrl.path) {
//            debugPrint("The file already exists at path")
//            completion(true, destinationUrl)
//
//            // if the file doesn't exist
//        } else {
//
//            // you can use NSURLSession.sharedSession to download the data asynchronously
//            URLSession.shared.downloadTask(with: url, completionHandler: { (location, response, error) -> Void in
//                guard let tempLocation = location, error == nil else { return }
//                do {
//                    // after downloading your file you need to move it to your destination url
//                    try FileManager.default.moveItem(at: tempLocation, to: destinationUrl)
//                    print("File moved to documents folder")
//                    completion(true, destinationUrl)
//                } catch let error as NSError {
//                    print(error.localizedDescription)
//                    completion(false, nil)
//                }
//            }).resume()
//        }
//    }
  
    /*
     Checks if the given url points to a document provided by Vaadin FileDownloader and returns 'true' if yes
     */
    private func openInDocumentPreview(_ url : URL) -> Bool {
        let allowExtenstions = ["hwp", "pdf", "png", "jpeg", "tiff", "gif", "doc", "docx", "ppt", "pptx", "xls","xlsx"]
        return allowExtenstions.contains(url.pathExtension)
    }

}

extension ViewController: QLPreviewControllerDataSource {
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self.previewItem as QLPreviewItem
    }
  
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
}

extension ViewController: UIGestureRecognizerDelegate {

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if webview.canGoBack {
            webview.goBack()
        }
        
        return true
    }
}

