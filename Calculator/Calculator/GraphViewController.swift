//
//  GraphViewController.swift
//  Calculator
//

import UIKit

class GraphViewController: UIViewController {
    
    var yForX: ((Double) -> Double?)?{ didSet { updateUI() } }
    
    @IBOutlet weak var graphView: GraphView!{ didSet {
        graphView.addGestureRecognizer(UIPinchGestureRecognizer(
            target: graphView, action: #selector(GraphView.scale(_:))))
        
        graphView.addGestureRecognizer(UIPanGestureRecognizer(
            target: graphView, action: #selector(GraphView.originMove(_:))))
        
        let doubleTapRecognizer = UITapGestureRecognizer(
            target: graphView, action: #selector(GraphView.origin(_:)))
        
        doubleTapRecognizer.numberOfTapsRequired = 2
        graphView.addGestureRecognizer(doubleTapRecognizer)
        graphView.scale = scale
        graphView.originRelativeToCenter = originRelativeToCenter
        
        updateUI()
        }
    }
    
    func updateUI() {
        graphView?.yForX = yForX
    }
   
    private struct Keys {
        static let Scale = "GraphViewController.Scale"
        static let Origin = "GraphViewController.Origin"
    }
    
    private let defaults = UserDefaults.standard
    
    private var scale: CGFloat {
        get { return defaults.object(forKey: Keys.Scale) as? CGFloat ?? 50.0 }
        set { defaults.set(newValue, forKey: Keys.Scale) }
    }
    
    private var factor:[CGFloat] {
        get{ return (defaults.object(forKey: Keys.Origin) as? [CGFloat]) ?? [0.0,0.0] }
        set { defaults.set(newValue, forKey: Keys.Origin)}
    }

    
    private var originRelativeToCenter: CGPoint {
        get {
            return CGPoint (x: factor[0] * graphView.bounds.size.width,
                            y: factor[1] * graphView.bounds.size.height)
        }
        set {
            factor = [newValue.x / graphView.bounds.size.width,
                      newValue.y / graphView.bounds.size.height]
        }
    }
    
    private var widthOld: CGFloat?
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
   //     if graphView.bounds.size.width != widthOld {
            originRelativeToCenter = graphView.originRelativeToCenter
            widthOld = graphView.bounds.size.width
  //      }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if graphView.bounds.size.width != widthOld {
            graphView.originRelativeToCenter =  originRelativeToCenter
        }
    }
 /*
    override func viewWillTransition(to size: CGSize,
                        with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        originRelativeToCenter = graphView.originRelativeToCenter
        
        coordinator.animate(alongsideTransition: nil,
                                     completion: { [weak self] _ in
            
            self?.graphView.originRelativeToCenter =  (self?.originRelativeToCenter)!
        })
    }
 */
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        scale = graphView.scale
        originRelativeToCenter = graphView.originRelativeToCenter
    }
}
