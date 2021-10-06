//
//  File.swift
//  
//
//  Created by Roberto Arista on 06/10/21.
//

import CoreGraphics

class AreaPen: BasePen {

    var value: CGFloat = 0
    var prevPt: CGPoint? = nil
    var startPoint: CGPoint? = nil

    override func _moveTo(pt: CGPoint) throws {
        prevPt = pt
        startPoint = pt
    }
    
    override func _lineTo(pt: CGPoint) throws {
        guard prevPt != nil else {
            throw PenError.missingPrevPoint
        }
        self.value -= (pt.x - prevPt!.x) * (pt.y + prevPt!.y) * 0.5
        prevPt = pt
    }
    
    override func _qCurveToOne(pt1: CGPoint, pt2: CGPoint) throws {
        // https://github.com/Pomax/bezierinfo/issues/44
        guard prevPt != nil else {
            throw PenError.missingPrevPoint
        }
        let x1 = pt1.x - prevPt!.x
        let y1 = pt1.y - prevPt!.y
        let x2 = pt2.x - prevPt!.x
        let y2 = pt2.y - prevPt!.y
        self.value -= (x2 * y1 - x1 * y2) / 3
        try self._lineTo(pt: pt2)
        prevPt = pt2
    }
    
    override func _curveToOne(pt1: CGPoint, pt2: CGPoint, pt3: CGPoint) throws {
        // https://github.com/Pomax/bezierinfo/issues/44
        guard prevPt != nil else {
            throw PenError.missingPrevPoint
        }
        let x1 = pt1.x - prevPt!.x
        let y1 = pt1.y - prevPt!.y
        let x2 = pt2.x - prevPt!.x
        let y2 = pt2.y - prevPt!.y
        let x3 = pt3.x - prevPt!.x
        let y3 = pt3.y - prevPt!.y

        self.value -= ( x1 * (-y2-y3) + x2 * (y1 - 2*y3) + x3 * (y1 + 2*y2) ) * 0.15
        try self._lineTo(pt: pt3)
        prevPt = pt3
    }
    
    override func _closePath() throws {
        guard prevPt != nil else {
            throw PenError.missingPrevPoint
        }
        try self._lineTo(pt: self.startPoint!)
        prevPt = nil
        startPoint = nil
    }
    
    override func _endPath() throws {
        if prevPt != startPoint {
            throw PenError.openContour
        }
        prevPt = nil
        startPoint = nil
    }

}
