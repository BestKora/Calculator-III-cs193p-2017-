//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Tatiana Kornilova on 3/8/17.
//  All rights reserved.
//

import Foundation

struct CalculatorBrain {
    
    private enum OpStack {
        case operand(Double)        // операнд
        case operation(String)      // операция
        case variable(String)       // переменная
        
    }
    
    private var internalProgram = [OpStack]()
    
    mutating func setOperand (_ operand: Double){
        internalProgram.append(OpStack.operand(operand))
    }
    
    mutating func setOperand(variable named: String) {
        internalProgram.append(OpStack.variable(named))
    }
    
    mutating func performOperation(_ symbol: String) {
        internalProgram.append(OpStack.operation(symbol))
    }
    
    mutating func clear() {
        internalProgram.removeAll()
    }
    
    mutating func undo() {
        if !internalProgram.isEmpty {
            internalProgram = Array(internalProgram.dropLast())
        }
    }
    
    private enum Operation {
        case nullaryOperation(() -> Double,String)
        case constant (Double)
        case unaryOperation ((Double) -> Double,((String) -> String)?, ((Double) -> String?)?)
        case binaryOperation ((Double, Double) -> Double, ((String, String) -> String)?,
                                                          ((Double, Double) -> String?)?, Int)
        case equals
        
    }
    
    private var operations : Dictionary <String,Operation> = [
        "Ran": Operation.nullaryOperation(
                          { Double(arc4random()) / Double(UInt32.max)}, "rand()"),
        "π": Operation.constant(Double.pi),
        "e": Operation.constant(M_E),
        "±": Operation.unaryOperation({ -$0 },nil, nil),
        "√": Operation.unaryOperation(sqrt,nil, { $0 < 0 ? "√ отриц. числа" : nil }),
        "cos": Operation.unaryOperation(cos,nil, nil),
        "sin": Operation.unaryOperation(sin,nil, nil),
        "tan": Operation.unaryOperation(tan,nil, nil),
        "sin⁻¹" : Operation.unaryOperation(asin,nil,
                { $0 < -1.0 || $0 > 1.0 ? "не в диапазоне [-1,1]" : nil }),
        "cos⁻¹" : Operation.unaryOperation(acos,nil,
                { $0 < -1.0 || $0 > 1.0 ? "не в диапазоне [-1,1]" : nil }),
        "tan⁻¹" : Operation.unaryOperation(atan, nil, nil),
        "ln" : Operation.unaryOperation(log,nil,{ $0 <= 0 ? "ln отриц. числа" : nil }),
        "x⁻¹" : Operation.unaryOperation({1.0/$0},
                {"(" + $0 + ")⁻¹"},{ $0 == 0.0 ? "Деление на нуль" : nil }),
        "х²" : Operation.unaryOperation({$0 * $0}, { "(" + $0 + ")²"}, nil),
        
        "×": Operation.binaryOperation(*, nil, nil, 1),
        "÷": Operation.binaryOperation(/, nil,
                { $1 == 0.0 ? "Деление на нуль" : nil }, 1),
        "+": Operation.binaryOperation(+, nil, nil, 0),
        "−": Operation.binaryOperation(-, nil, nil, 0),
        "xʸ" : Operation.binaryOperation(pow, { $0 + " ^ " + $1 }, nil, 2),
        "=": Operation.equals
    ]
    
    struct PendingBinaryOperation {
        let function: (Double,Double) -> Double
        let firstOperand: Double
        var descriptionFunction: (String, String) -> String
        var descriptionOperand: String
        var validator: ((Double, Double) -> String?)?
        var prevPrecedence: Int
        var precedence: Int


        func perform (with secondOperand: Double) -> Double {
            return function (firstOperand, secondOperand)
        }
        
       func performDescription (with secondOperand: String) -> String {
            var descriptionOperandNew = descriptionOperand
            if prevPrecedence < precedence {
                descriptionOperandNew = "(" +  descriptionOperandNew + ")"
            }
            return descriptionFunction (  descriptionOperandNew, secondOperand)
        }
        
        func validate (with secondOperand: Double) -> String? {
            guard let validator = validator  else {return nil}
            return validator (firstOperand, secondOperand)
        }
    }
     //--------- PropertyList --------
    typealias PropertyList = AnyObject
    
    var program: PropertyList {
        get {
            var propertyListProgram = [AnyObject]()
            for op in internalProgram {
                switch op {
                case .operand(let operand):
                    propertyListProgram.append(operand as AnyObject)
                case .operation(let symbol):
                    propertyListProgram.append(symbol as AnyObject)
                case .variable (let named):
                    propertyListProgram.append(named as AnyObject)
                }
            }
            return propertyListProgram as CalculatorBrain.PropertyList
        }
        set {
            clear()
            if let arrayOfOps = newValue as? [AnyObject] {
                for op in arrayOfOps {
                    if let operand = op as? Double {
                        internalProgram.append(OpStack.operand(operand))
                    } else if let symbol = op as? String {
                        if operations[symbol] != nil {
                            // symbol - это операция
                            internalProgram.append(OpStack.operation(symbol))
                        } else {
                            // symbol - это переменная
                            internalProgram.append(OpStack.variable(symbol))
                        }
                    }
                }
            }
        }
    }

    //-------------------------------------------------------------------------
    // MARK: - evaluate
    
    func evaluate(using variables: Dictionary<String,Double>? = nil) ->
        (result: Double?, isPending: Bool, description: String, error: String?){
            
            // MARK: - Local variables evaluate
            
            var cache: (accumulator: Double?, descriptionAccumulator: String?) // tuple
            var error: String?
            
            var prevPrecedence = Int.max             // preference
            
            var pendingBinaryOperation: PendingBinaryOperation?
            
            var description: String? {
                get {
                    if pendingBinaryOperation == nil {
                        return cache.descriptionAccumulator
                    } else {
                        return  pendingBinaryOperation!.descriptionFunction(
                            pendingBinaryOperation!.descriptionOperand,
                            cache.descriptionAccumulator ?? "")
                    }
                }
            }
            
            var result: Double? {
                get {
                    return cache.accumulator
                }
            }
            
            var resultIsPending: Bool {
                get {
                    return pendingBinaryOperation != nil
                }
            }
            
            // MARK: - Nested function evaluate
            
            func setOperand (_ operand: Double){
                cache.accumulator = operand
                if let value = cache.accumulator {
                    cache.descriptionAccumulator =
                        formatter.string(from: NSNumber(value:value)) ?? ""
                    prevPrecedence = Int.max
                }
            }
            
            func setOperand (variable named: String) {
                cache.accumulator = variables?[named] ?? 0
                cache.descriptionAccumulator = named
                prevPrecedence = Int.max
            }
            
            func performOperation(_ symbol: String) {
                if let operation = operations[symbol]{
                     error = nil
                    switch operation {
                        
                    case .nullaryOperation(let function, let descriptionValue):
                        cache = (function(), descriptionValue)
                        
                    case .constant(let value):
                        cache = (value,symbol)
                        
                    case .unaryOperation (let function, var descriptionFunction, let validator):
                        if cache.accumulator != nil {
                            error = validator?(cache.accumulator!)
                            cache.accumulator = function (cache.accumulator!)
                            if  descriptionFunction == nil{
                                descriptionFunction = {symbol + "(" + $0 + ")"}   //standard
                            }
                            cache.descriptionAccumulator =
                                descriptionFunction!(cache.descriptionAccumulator!)
                        }
                        
                    case .binaryOperation (let function, var descriptionFunction,
                                           let validator, let precedence):
                        performPendingBinaryOperation()
                        if cache.accumulator != nil {
                            
                            if  descriptionFunction == nil{
                                descriptionFunction = {$0 + " " + symbol + " " + $1}   //standard
                            }
                            
                            pendingBinaryOperation = PendingBinaryOperation (function: function,
                                                     firstOperand: cache.accumulator!,
                                                     descriptionFunction: descriptionFunction!,
                                                     descriptionOperand: cache.descriptionAccumulator!,
                                                     validator: validator,
                                                     prevPrecedence: prevPrecedence,
                                                     precedence:precedence )
                            cache = (nil, nil)
                            
                        }
                        
                    case .equals:
                        performPendingBinaryOperation()
                    }
                }
            }
            
            func  performPendingBinaryOperation() {
                if pendingBinaryOperation != nil && cache.accumulator != nil {
                    
                    error = pendingBinaryOperation!.validate(with: cache.accumulator!)
                    
                    cache.accumulator =  pendingBinaryOperation!.perform(with: cache.accumulator!)
                    cache.descriptionAccumulator =
                        pendingBinaryOperation!.performDescription(with: cache.descriptionAccumulator!)
                    
                    prevPrecedence = pendingBinaryOperation!.precedence
                    
                    pendingBinaryOperation = nil
                    
                }
            }
            
            
            // MARK: - Body evaluate
            
            //------ body of  evaluate-----------------------------
            guard !internalProgram.isEmpty else {return (nil,false," ", nil)}
            prevPrecedence = Int.max
            pendingBinaryOperation = nil
            for op in internalProgram {
                switch op{
                case .operand(let operand):
                    setOperand(operand)
                case .operation(let operation):
                    performOperation(operation)
                case .variable(let symbol):
                    setOperand (variable:symbol)
                    
                }
            }
            return (result, resultIsPending, description ?? " ", error)
    }
    //---------------------------------------------------------
    
    @available(iOS, deprecated, message: "No longer needed")
    var description: String {
        get {
            return evaluate().description
        }
    }
    @available(iOS, deprecated, message: "No longer needed")
    var result: Double? {
        get {
            return evaluate().result
        }
    }
    
    @available(iOS, deprecated, message: "No longer needed")
    var resultIsPending: Bool {
        get {
            return evaluate().isPending
        }
    }
}

let formatter:NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 6
  //  formatter.notANumberSymbol = "Error"
    formatter.groupingSeparator = " "
    formatter.locale = Locale.current
    return formatter
    
} ()
