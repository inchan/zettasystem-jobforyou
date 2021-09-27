//
//  ViewController.swift
//  JobForYou
//
//  Created by inchan on 2021/08/20.
//

import UIKit
import WebKit

struct URLs {
    static let home = "http://ulsan14u.co.kr/mobile"
}

extension WKWebView {
    
    func defaultUserAgent(completion: @escaping (String) -> Void) {
        evaluateJavaScript("navigator.userAgent", completionHandler: { (userAgent, error) in
            guard let userAgent = userAgent as? String else { completion(""); return }
            completion(userAgent)
        })
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var webview: WKWebView! {
        willSet {
            if webview == nil {
                newValue.uiDelegate = self
                newValue.navigationDelegate = self
                newValue.defaultUserAgent { [weak self] userAgent in
                    guard let strongSelf = self else { return }
                    let customUserAgent = userAgent + " ;JFYiOS"
                    strongSelf.webview.customUserAgent = customUserAgent
                    if let customUserAgent = strongSelf.webview.customUserAgent {
                        print("customUserAgent: \(customUserAgent)")
                    }
                }
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

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.goHome()
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
        print("url: \(url)")

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
}

extension ViewController: UIGestureRecognizerDelegate {

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if webview.canGoBack {
            webview.goBack()
        }
        
        return true
    }
}
