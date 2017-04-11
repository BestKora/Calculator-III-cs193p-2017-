//
//  GraphView.swift
//  Calculator

import UIKit

@IBDesignable
class GraphView: UIView {
    
    var yForX: ((Double) -> Double?)? { didSet { setNeedsDisplay() } }
    
    @IBInspectable
    var scale: CGFloat = 50.0 { didSet { setNeedsDisplay() } }
    @IBInspectable
    var lineWidth: CGFloat = 2.0 { didSet { setNeedsDisplay() } }
    @IBInspectable
    var color: UIColor = UIColor.blue { didSet { setNeedsDisplay() } }
    @IBInspectable
    var colorAxes: UIColor = UIColor.black { didSet { setNeedsDisplay() } }

    var originRelativeToCenter = CGPoint.zero  { didSet { setNeedsDisplay() } }
    
    private var graphCenter: CGPoint {
        return convert(center, from: superview)
    }
    private  var origin: CGPoint  {
        get {
            var origin = originRelativeToCenter
            origin.x += graphCenter.x
            origin.y += graphCenter.y
            return origin
        }
        set {
            var origin = newValue
            origin.x -= graphCenter.x
            origin.y -= graphCenter.y
            originRelativeToCenter = origin
        }
    }
 
   private var axesDrawer = AxesDrawer()
    
    override func draw(_ rect: CGRect) {
        axesDrawer.contentScaleFactor = contentScaleFactor
        axesDrawer.color = colorAxes
        axesDrawer.drawAxes(in: bounds, origin: origin, pointsPerUnit: scale)
        drawCurveInRect(bounds, origin: origin, scale: scale)
    }

    func drawCurveInRect(_ bounds: CGRect, origin: CGPoint, scale: CGFloat){
        
        var xGraph, yGraph :CGFloat
        var x, y: Double
        var isFirstPoint = true
        
        // --- Discontinuity --------------------------------------
        var oldYGraph: CGFloat =  0.0
        var disContinuity:Bool {
            return abs( yGraph - oldYGraph) >
                              max(bounds.width, bounds.height) * 1.5}
        //-------------------------------------------------------------
        
        if yForX != nil {
            color.set()
            let path = UIBezierPath()
            path.lineWidth = lineWidth
            
            for i in 0...Int(bounds.size.width * contentScaleFactor){
                xGraph = CGFloat(i) / contentScaleFactor
                
                x = Double ((xGraph - origin.x) / scale)
                guard let y = (yForX)!(x),
                          y.isFinite else {continue}
                
                yGraph = origin.y - CGFloat(y) * scale
                
                if isFirstPoint{
                    path.move(to: CGPoint(x: xGraph, y: yGraph))
                    isFirstPoint = false
                } else {
                    if disContinuity {
                        isFirstPoint = true
                    } else {
                    path.addLine(to: CGPoint(x: xGraph, y: yGraph))
                    }
                }
            }
            path.stroke()
        }
    }
/*
//     Оригинальный вариант без "замороженного" снимка
    func originMove(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .ended: fallthrough
        case .changed:
            let translation = gesture.translation(in: self)
            if translation != CGPoint.zero {
                origin.x += translation.x
                origin.y += translation.y
                gesture.setTranslation(CGPoint.zero, in: self)
            }
        default: break
        }
    }

//     Оригинальный вариант без "замороженного" снимка
    func scale(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            scale *= gesture.scale
            gesture.scale = 1.0
        }
    }
*/
    
    func origin(_ gesture: UITapGestureRecognizer) {
        if gesture.state == .ended {
            origin = gesture.location(in: self)
        }
    }

    private var snapshot:UIView?

    //     Вариант с "замороженным" снимком
    func scale(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            snapshot = self.snapshotView(afterScreenUpdates: false)
            snapshot!.alpha = 0.8
            self.addSubview(snapshot!)
        case .changed:
            let touch = gesture.location(in: self)
            snapshot!.frame.size.height *= gesture.scale
            snapshot!.frame.size.width *= gesture.scale
            snapshot!.frame.origin.x = snapshot!.frame.origin.x * gesture.scale +
                                            (1 - gesture.scale) * touch.x
            snapshot!.frame.origin.y = snapshot!.frame.origin.y * gesture.scale +
                                            (1 - gesture.scale) * touch.y
            gesture.scale = 1.0
        case .ended:
            let changedScale = snapshot!.frame.height / self.frame.height
            scale *= changedScale
            origin.x = origin.x * changedScale + snapshot!.frame.origin.x
            origin.y = origin.y * changedScale + snapshot!.frame.origin.y
            snapshot!.removeFromSuperview()
            snapshot = nil
            setNeedsDisplay()
        default: break
        }
    }


//     Вариант с "замороженным" снимком
    func originMove(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            
            snapshot = self.snapshotView(afterScreenUpdates: false)
            snapshot!.alpha = 0.6
            
            self.addSubview(snapshot!)
        case .changed:
            let translation = gesture.translation(in: self)
            if translation != CGPoint.zero {
                snapshot!.center.x += translation.x   // можно двигать
                snapshot!.center.y += translation.y   // только снимок
                //  origin.x += translation.x
                //  origin.y += translation.y
                gesture.setTranslation(CGPoint.zero, in: self)
            }
        case .ended:
            origin.x += snapshot!.frame.origin.x
            origin.y += snapshot!.frame.origin.y
            snapshot!.removeFromSuperview()
            snapshot = nil
            
            setNeedsDisplay()
        default: break
        }
    }
 
}
