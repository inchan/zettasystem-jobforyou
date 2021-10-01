//
//  ViewController.swift
//  JobForYou
//
//  Created by inchan on 2021/08/20.
//

import UIKit
import WebKit



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
}

extension ViewController: UIGestureRecognizerDelegate {

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if webview.canGoBack {
            webview.goBack()
        }
        
        return true
    }
}
