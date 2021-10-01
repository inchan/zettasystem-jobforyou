//
//  WebView.swift
//  JobForYou
//
//  Created by inchan on 2021/09/27.
//

import Foundation
import WebKit

extension WKWebView {
    
    func defaultUserAgent(completion: @escaping (String) -> Void) {
        evaluateJavaScript("navigator.userAgent", completionHandler: { (userAgent, error) in
            guard let userAgent = userAgent as? String else { completion(""); return }
            completion(userAgent)
        })
    }
    
}
