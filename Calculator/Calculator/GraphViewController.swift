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
        
        updateUI()
        }
    }
    
    func updateUI() {
        graphView?.yForX = yForX
    }
    
/*    override func viewDidLoad() {
        super.viewDidLoad ()
        yForX = {cos (1 / ($0  + 2)) * $0}
    //  yForX = { sin($0) / cos($0)}
    //  yForX = { 1.0 / $0}
    }*/
}
