//
//  File 2.swift
//  
//
//  Created by Roberto Arista on 06/10/21.
//

import Foundation

enum PenError: Error, Equatable {
    case notImplementedError
    case missingCurrentPoint
    case curveToMistake
    case noPoints
    case lastOrFirstOffcurveIsNIL
    case missingComponent
    case missingPrevPoint
    case notEnoughPoints
    case openContour
}
