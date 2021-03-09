//
//  CodeCellModel.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 2/27/21.
//

import Foundation

class CodeCellModel {
    let codeImageName: String
    let codeTitle: String
    let dateTitle: String
    
    init(_ code: Code) {
        codeImageName = code.imageName
        codeTitle = code.title
        dateTitle = code.date
    }
}
