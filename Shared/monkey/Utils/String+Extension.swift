//
//  String+Extension.swift
//  monkey-swift
//
//  Created by zhejun chen on 2023/04/15.
//

import Foundation

extension String {
    func removeNewLine() -> String {
        return String(filter { !"\r\n\n\t\r".contains($0) })
    }
}
