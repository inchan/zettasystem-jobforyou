//
//  Log.swift
//  JobForYou
//
//  Created by inchan on 2021/09/27.
//

import Foundation

func prettyLog(title: String, value: String) {
    let gubun = "-"
    let shortGubun = "###"
    
    let message = "\(shortGubun) \(title) \(shortGubun)"
    var longGubun = ""
    for _ in 0..<message.count {
        longGubun.append(gubun)
    }
    var messages = [String]()
    messages.append(longGubun)
    messages.append(message)
    messages.append("  : \(value)")
    messages.append(longGubun)
    
    print("\n\(messages.joined(separator: "\n"))\n")
}
