// The Pen Protocol - ported from https://github.com/fonttools/fonttools/blob/main/Lib/fontTools/pens/basePen.py
// A Pen is a kind of object that standardizes the way how to "draw" outlines:
// it is a middle man between an outline and a drawing. In other words:
// it is an abstraction for drawing outlines, making sure that outline objects
// don't need to know the details about how and where they're being drawn, and
// that drawings don't need to know the details of how outlines are stored.
// The most basic pattern is this:

//     outline.draw(pen)  # 'outline' draws itself onto 'pen'

// Pens can be used to render outlines to the screen, but also to construct
// new outlines. Eg. an outline object can be both a drawable object (it has a
// draw() method) as well as a pen itself: you *build* an outline using pen
// methods.

import CoreGraphics

protocol AbstractPen {
    // Begin a new sub path, set the current point to 'pt'. You must
    // end each sub path with a call to pen.closePath() or pen.endPath().
    func moveTo(pt: CGPoint)
    
    // Draw a straight line from the current point to 'pt'.
    func lineTo(pt: CGPoint)
    
    // Draw a cubic bezier with an arbitrary number of control points.
    // The last point specified is on-curve, all others are off-curve
    // (control) points. If the number of control points is > 2, the
    // segment is split into multiple bezier segments. This works
    // like this:
    // Let n be the number of control points (which is the number of
    // arguments to this call minus 1). If n==2, a plain vanilla cubic
    // bezier is drawn. If n==1, we fall back to a quadratic segment and
    // if n==0 we draw a straight line. It gets interesting when n>2:
    // n-1 PostScript-style cubic segments will be drawn as if it were
    // one curve. See decomposeSuperBezierSegment().
    // The conversion algorithm used for n>2 is inspired by NURB
    // splines, and is conceptually equivalent to the TrueType "implied
    // points" principle. See also decomposeQuadraticSegment().
    func curveTo(points: [CGPoint]) throws
    
    // Draw a whole string of quadratic curve segments.
    // The last point specified is on-curve, all others are off-curve
    // points.
    // This method implements TrueType-style curves, breaking up curves
    // using 'implied points': between each two consequtive off-curve points,
    // there is one implied point exactly in the middle between them. See
    // also decomposeQuadraticSegment().
    // The last argument (normally the on-curve point) may be None.
    // This is to support contours that have NO on-curve points (a rarely
    // seen feature of TrueType outlines).
    func qCurveTo(points: [CGPoint?]) throws
    
    // Close the current sub path. You must call either pen.closePath()
    // or pen.endPath() after each sub path.
    func closePath()
    
    // End the current sub path, but don't close it. You must call
    // either pen.closePath() or pen.endPath() after each sub path.
    func endPath()
    
    // Add a sub glyph. The 'transformation' argument must be a 6-tuple
    // containing an affine transformation
     func addComponent(glyphName: String, transformation: CGAffineTransform) throws
    
}

struct Glyph {
    func draw(pen: AbstractPen) {
        pen.moveTo(pt: CGPoint(x: 0.0, y: 0.0))
        pen.lineTo(pt: CGPoint(x: 0.0, y: 100.0))
        do {
            try pen.curveTo(points: [CGPoint(x: 50.0, y: 75.0),
                                     CGPoint(x: 60.0, y: 50.0),
                                     CGPoint(x: 50.0, y: 25.0),
                                     CGPoint(x: 0.0, y: 0.0)])
        } catch {
            print("\(error)")
        }
        pen.closePath()
    }
}

class BasePen: AbstractPen {

    enum Error: Swift.Error, Equatable {
        case notImplementedError
        case missingCurrentPoint
        case curveToMistake
        case noPoints
        case lastOrFirstOffcurveIsNIL
        case missingComponent
    }
    
    var glyphSet: [String: Glyph]
    let skipMissingComponents: Bool = true
    private var currentPoint: CGPoint? = nil

    public init(glyphSet: [String: Glyph] = [:]) {
        self.glyphSet = glyphSet
    }

    // must override
    func _moveTo(pt: CGPoint) throws {
        throw Error.notImplementedError
    }
    
    func _lineTo(pt: CGPoint) throws {
        throw Error.notImplementedError
    }
    
    func _curveToOne(pt1: CGPoint, pt2: CGPoint, pt3: CGPoint) throws {
        throw Error.notImplementedError
    }
    
    // may override
    func _closePath() { }
    func _endPath() { }
    
    func _qCurveToOne(pt1: CGPoint, pt2: CGPoint) throws {
        // This method implements the basic quadratic curve type. The
        // default implementation delegates the work to the cubic curve
        // function. Optionally override with a native implementation.
        if let unwrapCurrent = self.currentPoint {
            let mid1x = unwrapCurrent.x + 0.66666666666666667 * (pt1.x - unwrapCurrent.x)
            let mid1y = unwrapCurrent.y + 0.66666666666666667 * (pt1.y - unwrapCurrent.y)
            let mid2x = pt2.x + 0.66666666666666667 * (pt1.x - pt2.x)
            let mid2y = pt2.y + 0.66666666666666667 * (pt1.y - pt2.y)
            try self._curveToOne(pt1: CGPoint(x: mid1x, y: mid1y),
                                 pt2: CGPoint(x: mid2x, y: mid2y),
                                 pt3: pt2)
        } else {
            throw Error.missingCurrentPoint
        }
    }
    
    // don't override
    func _getCurrentPoint() -> CGPoint? {
        // Return the current point. This is not part of the public
        // interface, yet is useful for subclasses.
        return self.currentPoint
    }
    
    func closePath() {
        self._closePath()
        self.currentPoint = nil
    }
    
    func endPath() {
        self._endPath()
        self.currentPoint = nil
    }
    
    func moveTo(pt: CGPoint) {
        do {
            try self._moveTo(pt: pt)
        } catch {
            print(error)
        }
        self.currentPoint = pt
    }
    
    func lineTo(pt: CGPoint) {
        do {
            try self._lineTo(pt: pt)
        } catch {
            print(error)
        }
        self.currentPoint = pt
    }
    
    func curveTo(points: [CGPoint]) throws {

        let n = points.count - 1  // 'n' is the number of control points
        guard n >= 0 else {
            throw Error.noPoints
        }

        if n == 2 {
            // The common case, we have exactly two BCP's, so this is a standard
            // cubic bezier. Even though decomposeSuperBezierSegment() handles
            // this case just fine, we special-case it anyway since it's so
            // common.
            try self._curveToOne(pt1: points[0], pt2: points[1], pt3: points[2])
            self.currentPoint = points[points.count-1]
        } else if n > 2 {
            // n is the number of control points; split curve into n-1 cubic
            // bezier segments. The algorithm used here is inspired by NURB
            // splines and the TrueType "implied point" principle, and ensures
            // the smoothest possible connection between two curve segments,
            // with no disruption in the curvature. It is practical since it
            // allows one to construct multiple bezier segments with a much
            // smaller amount of points.
            print(points)
            for (pt1, pt2, pt3) in try decomposeSuperBezierSegment(points: points) {
                print(pt1, pt2, pt3)
                try self._curveToOne(pt1: pt1, pt2: pt2, pt3: pt3)
                self.currentPoint = pt3
            }
        } else if n == 1 {
            try self.qCurveTo(points: points)
        } else if n == 0 {
            self.lineTo(pt: points[0])
        } else {
            print("we should not get here")
        }
    }
    
    func qCurveTo(points: [CGPoint?]) throws {
        var explicitPoints: [CGPoint]
        
        let n = points.count - 1  // 'n' is the number of control points
        guard n >= 0 else {
            throw Error.noPoints
        }
        print(n)
        
        if points[points.count-1] == nil {
            // Special case for TrueType quadratics: it is possible to
            // define a contour with NO on-curve points. BasePen supports
            // this by allowing the final argument (the expected on-curve
            // point) to be None. We simulate the feature by making the implied
            // on-curve point between the last and the first off-curve points
            // explicit.
            if let lastOffCurve = points[points.count-2], let firstOffCurve = points[0] {
                let impliedStartPoint = CGPoint(x: 0.5 * (lastOffCurve.x + firstOffCurve.x),
                                                y: 0.5 * (lastOffCurve.y + firstOffCurve.y))
                self.currentPoint = impliedStartPoint
                try self._moveTo(pt: impliedStartPoint)
                explicitPoints = points.dropLast(1).map { $0! }
                explicitPoints.append(impliedStartPoint)
            } else {
                throw Error.lastOrFirstOffcurveIsNIL
            }
        } else {
            explicitPoints = points.map { $0! }
        }
        
        if n > 0 {
            // Split the string of points into discrete quadratic curve
            // segments. Between any two consecutive off-curve points
            // there's an implied on-curve point exactly in the middle.
            // This is where the segment splits.
            for (pt1, pt2) in try decomposeQuadraticSegment(points: explicitPoints) {
                print(pt1, pt2)
                try self._qCurveToOne(pt1: pt1, pt2: pt2)
                self.currentPoint = pt2
            }
        } else {
            self.lineTo(pt: explicitPoints[0])
        }
        
    }

    func addComponent(glyphName: String, transformation: CGAffineTransform) throws {
        // Transform the points of the base glyph and draw it onto self
        
        if let glyph = glyphSet[glyphName] {
            let tPen = TransformPen(outPen: self, transformation: transformation)
            glyph.draw(pen: tPen)
        } else {
            if !skipMissingComponents {
                throw Error.missingComponent
            } else {
                print("missing \(glyphName)")
            }
        }
    }
}

enum DecomposeError: Error, Equatable {
    case notEnoughPoints
}

func decomposeSuperBezierSegment(points: [CGPoint]) throws -> [(CGPoint, CGPoint, CGPoint)] {
    // Split the SuperBezier described by 'points' into a list of regular
    // bezier segments. The 'points' argument must be a sequence with length
    // 3 or greater, containing (x, y) coordinates. The last point is the
    // destination on-curve point, the rest of the points are off-curve points.
    // The start point should not be supplied.
    // This function returns a list of (pt1, pt2, pt3) tuples, which each
    // specify a regular curveto-style bezier segment.
    
    let n = points.count - 1
    guard n > 1 else {
        throw DecomposeError.notEnoughPoints
    }
    var bezierSegments = [(CGPoint, CGPoint, CGPoint)]()
    var pt1: CGPoint = points[0]
    var pt2: CGPoint? = nil
    var pt3: CGPoint? = nil
    
    for i in 2 ..< n+1 {
        // calculate points in between control points.
        let nDivisions = min(min(i, 3), n-i+2)
        for j in 1 ..< nDivisions {
            let factor = Double(j) / Double(nDivisions)
            let temp1 = points[i-1]
            let temp2 = points[i-2]
            let temp = CGPoint(x: temp2.x + factor * (temp1.x - temp2.x),
                               y: temp2.y + factor * (temp1.y - temp2.y))

            if let unwrapPt2 = pt2 {
                pt3 =  CGPoint(x: 0.5 * (unwrapPt2.x + temp.x),
                               y: 0.5 * (unwrapPt2.y + temp.y))
                bezierSegments.append((pt1, unwrapPt2, pt3!))
                pt1 = temp
                pt2 = nil
                pt3 = nil
            } else {
                pt2 = temp
            }
        }
    }
    bezierSegments.append((pt1, points[points.count-2], points[points.count-1]))
    return bezierSegments
}

func decomposeQuadraticSegment(points: [CGPoint]) throws -> [(CGPoint, CGPoint)] {
    // Split the quadratic curve segment described by 'points' into a list
    // of "atomic" quadratic segments. The 'points' argument must be a sequence
    // with length 2 or greater, containing (x, y) coordinates. The last point
    // is the destination on-curve point, the rest of the points are off-curve
    // points. The start point should not be supplied.
    // This function returns a list of (pt1, pt2) tuples, which each specify a
    // plain quadratic bezier segment.
    
    let n = points.count - 1
    guard n > 0 else {
        throw DecomposeError.notEnoughPoints
    }
    
    var quadSegments = [(CGPoint, CGPoint)]()
    for i in 0 ..< n-1 {
        let current = points[i]
        let next = points[i+1]
        let impliedPt = CGPoint(x: 0.5 * (current.x + next.x),
                                y: 0.5 * (current.y + next.y))
        quadSegments.append((points[i], impliedPt))
    }
    
    quadSegments.append((points[points.count-2], points[points.count-1]))
    return quadSegments
}
