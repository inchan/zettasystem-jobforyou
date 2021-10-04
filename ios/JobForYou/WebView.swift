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

protocol Downlaoadable {
    var documentsDirectoryURL: URL { get }
    func destinationURL(remote url: URL) -> URL
    
    func downloadfile(url: URL, completion: @escaping (_ success: Bool,_ fileLocation: URL?) -> ())
}

extension WKWebView: Downlaoadable {
 
    var documentsDirectoryURL: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func destinationURL(remote url: URL) -> URL {
        let fileName = url.lastPathComponent
        return documentsDirectoryURL.appendingPathComponent(fileName)
    }
    
    func downloadfile(remote url: URL, completion: @escaping (_ success: Bool,_ fileLocation: URL?) -> Void){
        
        let destinationURL = self.destinationURL(remote: url)
        
        // to check if it exists before downloading it
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            debugPrint("The file already exists at path")
            completion(true, destinationURL)
            // if the file doesn't exist
        } else {
            // you can use NSURLSession.sharedSession to download the data asynchronously
            URLSession.shared.downloadTask(with: url, completionHandler: { (location, response, error) -> Void in
                guard let tempLocation = location, error == nil else { return }
                do {
                    // after downloading your file you need to move it to your destination url
                    try FileManager.default.moveItem(at: tempLocation, to: destinationURL)
                    print("File moved to documents folder")
                    completion(true, destinationURL)
                } catch let error as NSError {
                    print(error.localizedDescription)
                    completion(false, nil)
                }
            }).resume()
        }
    }

}
