//
//  File.swift
//  
//
//  Created by Roberto Arista on 04/10/21.
//

import CoreGraphics

class FilterPen: AbstractPen {

    var outPen: AbstractPen

    init(outPen: AbstractPen) {
        self.outPen = outPen
    }

    func moveTo(pt: CGPoint) {
        outPen.moveTo(pt: pt)
    }
    
    func lineTo(pt: CGPoint) {
        outPen.lineTo(pt: pt)
    }
    
    func curveTo(points: [CGPoint]) throws {
        try outPen.curveTo(points: points)
    }
    
    func qCurveTo(points: [CGPoint?]) throws {
        try outPen.qCurveTo(points: points)
    }
    
    func closePath() {
        outPen.closePath()
    }
    
    func endPath() {
        outPen.endPath()
    }

    func addComponent(glyphName: String, transformation: CGAffineTransform) throws {
        do {
            try outPen.addComponent(glyphName: glyphName, transformation: transformation)
        } catch {
            print("\(error)")
        }
    }
}
