//
//  File.swift
//  
//
//  Created by Roberto Arista on 04/10/21.
//

import CoreGraphics

class TransformPen: FilterPen {

    var transformation: CGAffineTransform

    init(outPen: AbstractPen, transformation: CGAffineTransform) {
        self.transformation = transformation
        super.init(outPen: outPen)
        self.outPen = outPen
    }

    override func moveTo(pt: CGPoint) {
        outPen.moveTo(pt: pt.applying(transformation))
    }

    override func lineTo(pt: CGPoint) {
        outPen.lineTo(pt: pt.applying(transformation))
    }


    override func curveTo(points: [CGPoint]) {
        do {
            try outPen.curveTo(points: points.map { $0.applying(transformation) })
        } catch {
            print(error)
        }
    }

    override func qCurveTo(points: [CGPoint?]) {
        var transPoints = [CGPoint?]()

        if points[points.count-1] == nil {
            transPoints = points.dropLast().map { $0!.applying(transformation) }
            transPoints.append(nil)
        } else {
            transPoints = points.map { $0!.applying(transformation) }
        }

        do {
            try outPen.qCurveTo(points: points)
        } catch {
            print(error)
        }
    }

    override func closePath() {
        outPen.closePath()
    }

    override func endPath() {
        outPen.endPath()
    }

//    override func addComponent(glyphName, transformation):
//        transformation = self._transformation.transform(transformation)
//        outPen.addComponent(glyphName, transformation)

}
