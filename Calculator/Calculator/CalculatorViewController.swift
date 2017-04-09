//
//  ViewController.swift
//  Calculator
//
//  Created by Tatiana Kornilova on 3/8/17.
//  All rights reserved.
//

import UIKit

class CalculatorViewController: UIViewController {
    
    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var history: UILabel!
    @IBOutlet weak var tochka: UIButton!{
        didSet {
            tochka.setTitle(decimalSeparator, for: UIControlState())
        }
    }
    
    @IBOutlet weak var displayM: UILabel!
    
    let decimalSeparator = formatter.decimalSeparator ?? "."
    var userInTheMiddleOfTyping = false
    
    @IBAction func touchDigit(_ sender: UIButton) {
        let digit = sender.currentTitle!
        if userInTheMiddleOfTyping {
            let textCurrentlyInDisplay = display.text!
            if (digit != decimalSeparator) || !(textCurrentlyInDisplay.contains(decimalSeparator)) {
                display.text = textCurrentlyInDisplay + digit
            }
        } else {
            display.text = digit
            userInTheMiddleOfTyping = true
        }
    }
    
    var displayValue: Double? {
        get {
            if let text = display.text, let value = Double(text){
                return value
            }
            return nil
        }
        set {
            if let value = newValue {
                display.text = formatter.string(from: NSNumber(value:value))
            }
        }
    }
    
    var displayResult: (result: Double?, isPending: Bool,
                       description: String, error: String?) = (nil, false," ", nil){
        
        // Наблюдатель Свойства модифицирует три IBOutlet метки
        didSet {
            switch displayResult {
                case (nil, _, " ", nil) : displayValue = 0
                case (let result, _,_,nil): displayValue = result
                case (_, _,_,let error): display.text = error!
            }
            
            history.text = displayResult.description != " " ?
                    displayResult.description + (displayResult.isPending ? " …" : " =") : " "
            displayM.text = formatter.string(from: NSNumber(value:variableValues["M"] ?? 0))
        }
    }
    
    // MARK: - Model
    
    private var brain = CalculatorBrain ()
    private var variableValues = [String: Double]()
    
    @IBAction func performOPeration(_ sender: UIButton) {
        if userInTheMiddleOfTyping {
            if let value = displayValue{
                brain.setOperand(value)
            }
            userInTheMiddleOfTyping = false
        }
        if  let mathematicalSymbol = sender.currentTitle {
            brain.performOperation(mathematicalSymbol)
        }
        displayResult = brain.evaluate(using: variableValues)
    }
    
    @IBAction func setM(_ sender: UIButton) {
        userInTheMiddleOfTyping = false
        let symbol = String((sender.currentTitle!).characters.dropFirst())
        
        variableValues[symbol] = displayValue
        displayResult = brain.evaluate(using: variableValues)
    }
    
    @IBAction func pushM(_ sender: UIButton) {
        brain.setOperand(variable: sender.currentTitle!)
        displayResult = brain.evaluate(using: variableValues)
    }
    
    @IBAction func clearAll(_ sender: UIButton) {
        brain.clear()
        variableValues = [:]
        displayResult = brain.evaluate()
    }
    
    @IBAction func backspace(_ sender: UIButton) {
        if userInTheMiddleOfTyping {
            guard !display.text!.isEmpty else { return }
            display.text = String (display.text!.characters.dropLast())
            if display.text!.isEmpty{
                userInTheMiddleOfTyping = false
                displayResult = brain.evaluate(using: variableValues)
            }
        } else {
            brain.undo()
            displayResult = brain.evaluate(using: variableValues)
            
        }
    }
    
    private struct Storyboard{
        static let ShowGraph = "Show Graph"
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var destination = segue.destination
        if let navigationController = destination as? UINavigationController {
            destination = navigationController.visibleViewController ?? destination
        }
        if let identifier = segue.identifier,
            identifier == Storyboard.ShowGraph,
            let vc = destination as? GraphViewController {
            vc.yForX = { [weak weakSelf = self] x in
                 weakSelf?.variableValues["M"] = x
                return weakSelf?.brain.evaluate(using: weakSelf?.variableValues).result 
            }
            vc.navigationItem.title = "y = " +
                                      brain.evaluate(using: variableValues).description
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String,
                                                        sender: Any?) -> Bool {
        if identifier == Storyboard.ShowGraph{
            let result = brain.evaluate()
            return !result.isPending
        }
        return false
    }

}
