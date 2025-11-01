import Foundation

// Boolean operations
enum BooleanOp: String, CaseIterable {
    case and = "∧"          // AND
    case or = "∨"           // OR
    case xor = "⊕"          // XOR
    case nor = "↓"          // NOR (Pierce arrow)
    case nand = "↑"         // NAND (Sheffer stroke)
    case implies = "→"      // Implication
    case reverseImplies = "←" // Reverse implication
    case xnor = "↔"         // XNOR (equivalence)
    
    var precedence: Int {
        switch self {
        case .and: return 2
        case .or: return 1
        case .xor, .nor, .nand, .implies, .reverseImplies, .xnor: return 0
        }
    }
    
    func apply(_ a: Bool, _ b: Bool) -> Bool {
        switch self {
        case .and: return a && b
        case .or: return a || b
        case .xor: return a != b
        case .nor: return !(a || b)
        case .nand: return !(a && b)
        case .implies: return !a || b
        case .reverseImplies: return a || !b
        case .xnor: return a == b
        }
    }
}

// Expression token
enum ExprToken: Equatable {
    case variable(String, negated: Bool)  // x, y, z with optional negation
    case operation(BooleanOp)
    case leftParen
    case rightParen
    
    var display: String {
        switch self {
        case .variable(let name, let negated):
            return negated ? "\(name)̄" : name
        case .operation(let op):
            return op.rawValue
        case .leftParen:
            return "("
        case .rightParen:
            return ")"
        }
    }
}

// Truth table row
struct TruthTableRow: Identifiable {
    let id = UUID()
    let x: Bool
    let y: Bool
    let z: Bool
    let result: Bool
    
    var binary: String {
        "\(x ? 1 : 0)\(y ? 1 : 0)\(z ? 1 : 0)"
    }
    
    var minterm: Int {
        (x ? 4 : 0) + (y ? 2 : 0) + (z ? 1 : 0)
    }
}

class BooleanFunction: ObservableObject {
    @Published var expression: [ExprToken] = []
    @Published var truthVector: [Bool] = Array(repeating: false, count: 8)
    @Published var intermediateSteps: [[Bool]] = []  // For truth table intermediate columns
    @Published var stepLabels: [String] = []  // Labels for intermediate columns
    
    var expressionString: String {
        expression.map { $0.display }.joined()
    }
    
    // Add token to expression
    func addToken(_ token: ExprToken) {
        expression.append(token)
        evaluateExpression()
    }
    
    // Toggle negation on last variable
    func toggleLastNegation() {
        guard !expression.isEmpty else { return }
        let lastIndex = expression.count - 1
        if case .variable(let name, let negated) = expression[lastIndex] {
            expression[lastIndex] = .variable(name, negated: !negated)
            evaluateExpression()
        }
    }
    
    // Remove last token
    func removeLastToken() {
        guard !expression.isEmpty else { return }
        expression.removeLast()
        evaluateExpression()
    }
    
    // Clear expression
    func clearExpression() {
        expression = []
        truthVector = Array(repeating: false, count: 8)
        intermediateSteps = []
        stepLabels = []
    }
    
    // Evaluate expression and compute truth vector
    func evaluateExpression() {
        guard !expression.isEmpty else {
            truthVector = Array(repeating: false, count: 8)
            intermediateSteps = []
            stepLabels = []
            return
        }
        
        var newTruthVector: [Bool] = []
        var allSteps: [[Bool]] = []
        var labels: [String] = []
        
        // Evaluate for all 8 combinations
        for i in 0..<8 {
            let x = (i & 4) != 0
            let y = (i & 2) != 0
            let z = (i & 1) != 0
            
            let (result, steps, stepNames) = evaluateWithSteps(x: x, y: y, z: z)
            newTruthVector.append(result)
            
            if i == 0 {
                // First iteration - save step labels
                labels = stepNames
                allSteps = Array(repeating: [], count: steps.count)
            }
            
            for (stepIndex, stepValue) in steps.enumerated() {
                if stepIndex < allSteps.count {
                    allSteps[stepIndex].append(stepValue)
                }
            }
        }
        
        truthVector = newTruthVector
        intermediateSteps = allSteps
        stepLabels = labels
    }
    
    // Evaluate expression with intermediate steps following precedence
    private func evaluateWithSteps(x: Bool, y: Bool, z: Bool) -> (Bool, [Bool], [String]) {
        let values: [String: Bool] = ["x": x, "y": y, "z": z]
        var steps: [Bool] = []
        var stepLabels: [String] = []
        
        // Step 1: Add negated variables (NOT has highest precedence)
        var hasNegX = false, hasNegY = false, hasNegZ = false
        for token in expression {
            if case .variable(let name, let negated) = token, negated {
                if name == "x" && !hasNegX { hasNegX = true }
                if name == "y" && !hasNegY { hasNegY = true }
                if name == "z" && !hasNegZ { hasNegZ = true }
            }
        }
        
        if hasNegX {
            steps.append(!x)
            stepLabels.append("x̄")
        }
        if hasNegY {
            steps.append(!y)
            stepLabels.append("ȳ")
        }
        if hasNegZ {
            steps.append(!z)
            stepLabels.append("z̄")
        }
        
        // Step 2: Evaluate subexpressions by precedence
        let (subSteps, subLabels) = evaluateSubexpressionsByPrecedence(x: x, y: y, z: z)
        steps.append(contentsOf: subSteps)
        stepLabels.append(contentsOf: subLabels)
        
        // Final evaluation
        let finalResult = evaluateSimple(tokens: expression, values: values)
        
        return (finalResult, steps, stepLabels)
    }
    
    // Evaluate subexpressions by precedence and return intermediate results
    private func evaluateSubexpressionsByPrecedence(x: Bool, y: Bool, z: Bool) -> ([Bool], [String]) {
        var steps: [Bool] = []
        var labels: [String] = []
        
        // Build a map of variable values including negations
        func getValue(_ name: String, _ negated: Bool) -> Bool {
            let base = name == "x" ? x : (name == "y" ? y : z)
            return negated ? !base : base
        }
        
        // Step 1: Find all AND operations (precedence 2)
        var i = 0
        while i + 2 < expression.count {
            if case .variable(let left, let negLeft) = expression[i],
               case .operation(let op) = expression[i + 1],
               case .variable(let right, let negRight) = expression[i + 2],
               op.precedence == 2 {
                
                let leftVal = getValue(left, negLeft)
                let rightVal = getValue(right, negRight)
                let result = op.apply(leftVal, rightVal)
                
                let leftStr = negLeft ? "\(left)̄" : left
                let rightStr = negRight ? "\(right)̄" : right
                let label = "\(leftStr)\(op.rawValue)\(rightStr)"
                
                steps.append(result)
                labels.append(label)
            }
            i += 1
        }
        
        // Step 2: Find all OR operations (precedence 1)
        i = 0
        while i + 2 < expression.count {
            if case .variable(let left, let negLeft) = expression[i],
               case .operation(let op) = expression[i + 1],
               case .variable(let right, let negRight) = expression[i + 2],
               op.precedence == 1 {
                
                let leftVal = getValue(left, negLeft)
                let rightVal = getValue(right, negRight)
                let result = op.apply(leftVal, rightVal)
                
                let leftStr = negLeft ? "\(left)̄" : left
                let rightStr = negRight ? "\(right)̄" : right
                let label = "\(leftStr)\(op.rawValue)\(rightStr)"
                
                steps.append(result)
                labels.append(label)
            }
            i += 1
        }
        
        // Step 3: Evaluate left-to-right for remaining operations (precedence 0)
        i = 0
        while i + 2 < expression.count {
            if case .variable(let left, let negLeft) = expression[i],
               case .operation(let op) = expression[i + 1],
               case .variable(let right, let negRight) = expression[i + 2],
               op.precedence == 0 {
                
                let leftVal = getValue(left, negLeft)
                let rightVal = getValue(right, negRight)
                let result = op.apply(leftVal, rightVal)
                
                let leftStr = negLeft ? "\(left)̄" : left
                let rightStr = negRight ? "\(right)̄" : right
                let label = "\(leftStr)\(op.rawValue)\(rightStr)"
                
                steps.append(result)
                labels.append(label)
            }
            i += 1
        }
        
        // Step 4: Build up complex expressions left-to-right if expression is longer
        if expression.count > 3 {
            // Evaluate progressively from left
            var accumulated: [ExprToken] = []
            for (idx, token) in expression.enumerated() {
                accumulated.append(token)
                
                // Evaluate when we have at least 3 tokens and just added an operation or variable
                if accumulated.count >= 3 && idx < expression.count - 1 {
                    let tempValues = ["x": x, "y": y, "z": z]
                    let partialResult = evaluateSimple(tokens: accumulated, values: tempValues)
                    let label = accumulated.map { $0.display }.joined()
                    
                    // Only add if not already in steps
                    if !labels.contains(label) && label.count > 3 {
                        steps.append(partialResult)
                        labels.append(label)
                    }
                }
            }
        }
        
        return (steps, labels)
    }
    
    // Simple expression evaluator
    private func evaluateSimple(tokens: [ExprToken], values: [String: Bool]) -> Bool {
        guard !tokens.isEmpty else { return false }
        
        var operandStack: [Bool] = []
        var operatorStack: [BooleanOp] = []
        
        var i = 0
        while i < tokens.count {
            let token = tokens[i]
            
            switch token {
            case .variable(let name, let negated):
                var value = values[name] ?? false
                if negated {
                    value = !value
                }
                operandStack.append(value)
                
            case .operation(let op):
                // Apply operators by precedence
                while !operatorStack.isEmpty && 
                      operatorStack.last!.precedence >= op.precedence &&
                      operandStack.count >= 2 {
                    let op2 = operatorStack.removeLast()
                    let b = operandStack.removeLast()
                    let a = operandStack.removeLast()
                    operandStack.append(op2.apply(a, b))
                }
                operatorStack.append(op)
                
            case .leftParen, .rightParen:
                break
            }
            
            i += 1
        }
        
        // Apply remaining operators
        while !operatorStack.isEmpty && operandStack.count >= 2 {
            let op = operatorStack.removeLast()
            let b = operandStack.removeLast()
            let a = operandStack.removeLast()
            operandStack.append(op.apply(a, b))
        }
        
        return operandStack.last ?? false
    }
    
    // Generate truth table
    var truthTable: [TruthTableRow] {
        var rows: [TruthTableRow] = []
        for i in 0..<8 {
            let x = (i & 4) != 0
            let y = (i & 2) != 0
            let z = (i & 1) != 0
            rows.append(TruthTableRow(x: x, y: y, z: z, result: truthVector[i]))
        }
        return rows
    }
    
    // Get minterms (where function = 1)
    var minterms: [Int] {
        truthVector.enumerated().filter { $0.element }.map { $0.offset }
    }
    
    // Get maxterms (where function = 0)
    var maxterms: [Int] {
        truthVector.enumerated().filter { !$0.element }.map { $0.offset }
    }
    
    // СДНФ (CDNF) - Canonical Disjunctive Normal Form
    func getCDNF() -> String {
        let mins = minterms
        if mins.isEmpty { return "0" }
        if mins.count == 8 { return "1" }
        
        return mins.map { mintermToString($0) }.joined(separator: " ∨ ")
    }
    
    // Minimal СДНФ using Quine-McCluskey simplification
    func getMinimalCDNF() -> String {
        let mins = minterms
        if mins.isEmpty { return "0" }
        if mins.count == 8 { return "1" }
        
        let simplified = quineMcCluskey(minterms: mins)
        return simplified
    }
    
    // Get CDNF minimization steps
    func getCDNFMinimizationSteps() -> [String] {
        var steps: [String] = []
        let mins = minterms
        
        if mins.isEmpty {
            steps.append("No minterms (function is always 0)")
            return steps
        }
        if mins.count == 8 {
            steps.append("All minterms present (function is always 1)")
            return steps
        }
        
        steps.append("СДНФ Minimization using Quine-McCluskey:")
        steps.append("")
        steps.append("1. Starting minterms: \(mins.map(String.init).joined(separator: ", "))")
        steps.append("")
        
        // Group by number of 1s
        var groups: [[Int]] = Array(repeating: [], count: 4)
        for m in mins {
            let ones = m.nonzeroBitCount
            groups[ones].append(m)
        }
        
        steps.append("2. Group by number of 1s:")
        for (i, group) in groups.enumerated() where !group.isEmpty {
            steps.append("   Group \(i): \(group.map(String.init).joined(separator: ", "))")
        }
        steps.append("")
        
        // Track combinations
        var primeImplicants: Set<Implicant> = []
        var currentLevel = groups.map { group in
            group.map { Implicant(value: $0, mask: 0) }
        }
        
        var iteration = 0
        steps.append("3. Combining terms:")
        
        while true {
            var nextLevel: [[Implicant]] = Array(repeating: [], count: 4)
            var used: Set<Implicant> = []
            var hasCombined = false
            var combinations: [String] = []
            
            for i in 0..<3 {
                for imp1 in currentLevel[i] {
                    for imp2 in currentLevel[i + 1] {
                        if let newImplicant = imp1.combine(with: imp2) {
                            nextLevel[i].append(newImplicant)
                            used.insert(imp1)
                            used.insert(imp2)
                            hasCombined = true
                            combinations.append("   \(imp1.value) + \(imp2.value) → \(newImplicant.value) (mask: \(newImplicant.mask))")
                        }
                    }
                }
            }
            
            if hasCombined {
                iteration += 1
                steps.append("   Iteration \(iteration):")
                steps.append(contentsOf: combinations)
            }
            
            // Add unused as prime implicants
            for group in currentLevel {
                for imp in group {
                    if !used.contains(imp) {
                        primeImplicants.insert(imp)
                    }
                }
            }
            
            if !hasCombined { break }
            currentLevel = nextLevel
        }
        
        steps.append("")
        steps.append("4. Prime Implicants:")
        for imp in primeImplicants.sorted(by: { $0.value < $1.value }) {
            steps.append("   \(imp.toString())")
        }
        
        steps.append("")
        steps.append("5. Minimal СДНФ:")
        steps.append("   \(getMinimalCDNF())")
        
        return steps
    }
    
    // СКНФ (CCNF) - Canonical Conjunctive Normal Form
    func getCCNF() -> String {
        let maxs = maxterms
        if maxs.isEmpty { return "1" }
        if maxs.count == 8 { return "0" }
        
        return maxs.map { maxtermToString($0) }.joined(separator: " ∧ ")
    }
    
    // Minimal СКНФ using Quine-McCluskey for maxterms
    func getMinimalCCNF() -> String {
        let maxs = maxterms
        if maxs.isEmpty { return "1" }
        if maxs.count == 8 { return "0" }
        
        // Apply Quine-McCluskey to maxterms for proper minimization
        let simplified = quineMcCluskeyForCCNF(maxterms: maxs)
        return simplified
    }
    
    // Get CCNF minimization steps
    func getCCNFMinimizationSteps() -> [String] {
        var steps: [String] = []
        let maxs = maxterms
        
        if maxs.isEmpty {
            steps.append("No maxterms (function is always 1)")
            return steps
        }
        if maxs.count == 8 {
            steps.append("All maxterms present (function is always 0)")
            return steps
        }
        
        steps.append("СКНФ Minimization using Quine-McCluskey:")
        steps.append("")
        steps.append("1. Starting maxterms: \(maxs.map(String.init).joined(separator: ", "))")
        steps.append("")
        
        // Group by number of 1s
        var groups: [[Int]] = Array(repeating: [], count: 4)
        for m in maxs {
            let ones = m.nonzeroBitCount
            groups[ones].append(m)
        }
        
        steps.append("2. Group by number of 1s:")
        for (i, group) in groups.enumerated() where !group.isEmpty {
            steps.append("   Group \(i): \(group.map(String.init).joined(separator: ", "))")
        }
        steps.append("")
        
        // Find prime implicants
        var primeImplicants: Set<MaxtermImplicant> = []
        var currentLevel = groups.map { group in
            group.map { MaxtermImplicant(value: $0, mask: 0) }
        }
        
        var iteration = 0
        steps.append("3. Combining terms:")
        
        while true {
            var nextLevel: [[MaxtermImplicant]] = Array(repeating: [], count: 4)
            var used: Set<MaxtermImplicant> = []
            var hasCombined = false
            var combinations: [String] = []
            
            for i in 0..<3 {
                for imp1 in currentLevel[i] {
                    for imp2 in currentLevel[i + 1] {
                        if let newImplicant = imp1.combine(with: imp2) {
                            nextLevel[i].append(newImplicant)
                            used.insert(imp1)
                            used.insert(imp2)
                            hasCombined = true
                            combinations.append("   \(imp1.value) + \(imp2.value) → \(newImplicant.value) (mask: \(newImplicant.mask))")
                        }
                    }
                }
            }
            
            if hasCombined {
                iteration += 1
                steps.append("   Iteration \(iteration):")
                steps.append(contentsOf: combinations)
            }
            
            // Add unused as prime implicants
            for group in currentLevel {
                for imp in group {
                    if !used.contains(imp) {
                        primeImplicants.insert(imp)
                    }
                }
            }
            
            if !hasCombined { break }
            currentLevel = nextLevel
        }
        
        steps.append("")
        steps.append("4. Prime Implicants:")
        for imp in primeImplicants.sorted(by: { $0.value < $1.value }) {
            steps.append("   \(imp.toMaxtermString())")
        }
        
        steps.append("")
        steps.append("5. Minimal СКНФ:")
        steps.append("   \(getMinimalCCNF())")
        
        return steps
    }
    
    // Shannon decomposition: f(x,y,z) = var∧f(1,...) ∨ var̄∧f(0,...)
    func getShannonDecomposition(by variable: String) -> String {
        var result = "f(x,y,z) = "
        
        switch variable {
        case "x":
            let f1yz = getFunctionWithX(true)
            let f0yz = getFunctionWithX(false)
            result += "x∧(\(f1yz)) ∨ x̄∧(\(f0yz))"
            
        case "y":
            let f1xz = getFunctionWithY(true)
            let f0xz = getFunctionWithY(false)
            result += "y∧(\(f1xz)) ∨ ȳ∧(\(f0xz))"
            
        case "z":
            let f1xy = getFunctionWithZ(true)
            let f0xy = getFunctionWithZ(false)
            result += "z∧(\(f1xy)) ∨ z̄∧(\(f0xy))"
            
        default:
            result += "Invalid variable"
        }
        
        return result
    }
    
    func getShannonDecompositionDetailed(by variable: String) -> [String] {
        var steps: [String] = []
        
        switch variable {
        case "x":
            steps.append("Shannon decomposition by x:")
            steps.append("f(x,y,z) = x∧f(1,y,z) ∨ x̄∧f(0,y,z)")
            steps.append("")
            steps.append("When x = 1:")
            steps.append("f(1,y,z) = \(getFunctionWithX(true))")
            steps.append("")
            steps.append("When x = 0:")
            steps.append("f(0,y,z) = \(getFunctionWithX(false))")
            
        case "y":
            steps.append("Shannon decomposition by y:")
            steps.append("f(x,y,z) = y∧f(x,1,z) ∨ ȳ∧f(x,0,z)")
            steps.append("")
            steps.append("When y = 1:")
            steps.append("f(x,1,z) = \(getFunctionWithY(true))")
            steps.append("")
            steps.append("When y = 0:")
            steps.append("f(x,0,z) = \(getFunctionWithY(false))")
            
        case "z":
            steps.append("Shannon decomposition by z:")
            steps.append("f(x,y,z) = z∧f(x,y,1) ∨ z̄∧f(x,y,0)")
            steps.append("")
            steps.append("When z = 1:")
            steps.append("f(x,y,1) = \(getFunctionWithZ(true))")
            steps.append("")
            steps.append("When z = 0:")
            steps.append("f(x,y,0) = \(getFunctionWithZ(false))")
            
        default:
            steps.append("Invalid variable")
        }
        
        return steps
    }
    
    // Helper for Y variable
    private func getFunctionWithY(_ yValue: Bool) -> String {
        var terms: [String] = []
        for x in [false, true] {
            for z in [false, true] {
                let index = (x ? 4 : 0) + (yValue ? 2 : 0) + (z ? 1 : 0)
                if truthVector[index] {
                    var term = ""
                    term += x ? "x" : "x̄"
                    term += "∧"
                    term += z ? "z" : "z̄"
                    terms.append(term)
                }
            }
        }
        return terms.isEmpty ? "0" : terms.joined(separator: " ∨ ")
    }
    
    // Helper for Z variable
    private func getFunctionWithZ(_ zValue: Bool) -> String {
        var terms: [String] = []
        for x in [false, true] {
            for y in [false, true] {
                let index = (x ? 4 : 0) + (y ? 2 : 0) + (zValue ? 1 : 0)
                if truthVector[index] {
                    var term = ""
                    term += x ? "x" : "x̄"
                    term += "∧"
                    term += y ? "y" : "ȳ"
                    terms.append(term)
                }
            }
        }
        return terms.isEmpty ? "0" : terms.joined(separator: " ∨ ")
    }
    
    // Helper: get function f(value, y, z)
    private func getFunctionWithX(_ xValue: Bool) -> String {
        var terms: [String] = []
        for y in [false, true] {
            for z in [false, true] {
                let index = (xValue ? 4 : 0) + (y ? 2 : 0) + (z ? 1 : 0)
                if truthVector[index] {
                    var term = ""
                    term += y ? "y" : "ȳ"
                    term += "∧"
                    term += z ? "z" : "z̄"
                    terms.append(term)
                }
            }
        }
        return terms.isEmpty ? "0" : terms.joined(separator: " ∨ ")
    }
    
    // Convert minterm number to string (e.g., 5 -> x∧ȳ∧z)
    private func mintermToString(_ minterm: Int) -> String {
        let x = (minterm & 4) != 0
        let y = (minterm & 2) != 0
        let z = (minterm & 1) != 0
        
        var result = ""
        result += x ? "x" : "x̄"
        result += "∧"
        result += y ? "y" : "ȳ"
        result += "∧"
        result += z ? "z" : "z̄"
        return result
    }
    
    // Convert maxterm number to string (e.g., 5 -> x̄∨y∨z̄)
    private func maxtermToString(_ maxterm: Int) -> String {
        let x = (maxterm & 4) != 0
        let y = (maxterm & 2) != 0
        let z = (maxterm & 1) != 0
        
        var result = "("
        result += x ? "x̄" : "x"
        result += "∨"
        result += y ? "ȳ" : "y"
        result += "∨"
        result += z ? "z̄" : "z"
        result += ")"
        return result
    }
    
    // Simplified Quine-McCluskey for minterms
    private func quineMcCluskey(minterms: [Int]) -> String {
        if minterms.isEmpty { return "0" }
        if minterms.count == 8 { return "1" }
        
        // Group by number of 1s
        var groups: [[Int]] = Array(repeating: [], count: 4)
        for m in minterms {
            let ones = m.nonzeroBitCount
            groups[ones].append(m)
        }
        
        // Find prime implicants
        var primeImplicants: Set<Implicant> = []
        var currentLevel = groups.map { group in
            group.map { Implicant(value: $0, mask: 0) }
        }
        
        while true {
            var nextLevel: [[Implicant]] = Array(repeating: [], count: 4)
            var used: Set<Implicant> = []
            
            var hasCombined = false
            for i in 0..<3 {
                for imp1 in currentLevel[i] {
                    for imp2 in currentLevel[i + 1] {
                        if let newImplicant = imp1.combine(with: imp2) {
                            nextLevel[i].append(newImplicant)
                            used.insert(imp1)
                            used.insert(imp2)
                            hasCombined = true
                        }
                    }
                }
            }
            
            // Add unused as prime implicants
            for group in currentLevel {
                for imp in group {
                    if !used.contains(imp) {
                        primeImplicants.insert(imp)
                    }
                }
            }
            
            if !hasCombined { break }
            currentLevel = nextLevel
        }
        
        // Convert to string (simplified - just use all prime implicants)
        let terms = primeImplicants.map { $0.toString() }.sorted()
        return terms.joined(separator: " ∨ ")
    }
    
    // Quine-McCluskey for CCNF (Product of Sums)
    private func quineMcCluskeyForCCNF(maxterms: [Int]) -> String {
        if maxterms.isEmpty { return "1" }
        if maxterms.count == 8 { return "0" }
        
        // Group maxterms by number of 1s (for POS)
        var groups: [[Int]] = Array(repeating: [], count: 4)
        for m in maxterms {
            let ones = m.nonzeroBitCount
            groups[ones].append(m)
        }
        
        // Find prime implicants for maxterms
        var primeImplicants: Set<MaxtermImplicant> = []
        var currentLevel = groups.map { group in
            group.map { MaxtermImplicant(value: $0, mask: 0) }
        }
        
        while true {
            var nextLevel: [[MaxtermImplicant]] = Array(repeating: [], count: 4)
            var used: Set<MaxtermImplicant> = []
            
            var hasCombined = false
            for i in 0..<3 {
                for imp1 in currentLevel[i] {
                    for imp2 in currentLevel[i + 1] {
                        if let newImplicant = imp1.combine(with: imp2) {
                            nextLevel[i].append(newImplicant)
                            used.insert(imp1)
                            used.insert(imp2)
                            hasCombined = true
                        }
                    }
                }
            }
            
            // Add unused as prime implicants
            for group in currentLevel {
                for imp in group {
                    if !used.contains(imp) {
                        primeImplicants.insert(imp)
                    }
                }
            }
            
            if !hasCombined { break }
            currentLevel = nextLevel
        }
        
        // Convert to POS string
        let terms = primeImplicants.map { $0.toMaxtermString() }.sorted()
        return terms.joined(separator: " ∧ ")
    }
}

// Helper struct for maxterm Quine-McCluskey
struct MaxtermImplicant: Hashable {
    let value: Int
    let mask: Int  // bits that are "don't care"
    
    func combine(with other: MaxtermImplicant) -> MaxtermImplicant? {
        guard self.mask == other.mask else { return nil }
        
        let diff = self.value ^ other.value
        guard diff.nonzeroBitCount == 1 else { return nil }
        
        return MaxtermImplicant(value: self.value & other.value, mask: self.mask | diff)
    }
    
    func toMaxtermString() -> String {
        var result = "("
        let bits = [(4, "x"), (2, "y"), (1, "z")]
        var first = true
        
        for (bit, name) in bits {
            if (mask & bit) == 0 {  // not a don't care
                if !first { result += "∨" }
                // In POS: 0 -> literal, 1 -> negated literal
                result += (value & bit) != 0 ? "\(name)̄" : name
                first = false
            }
        }
        
        result += ")"
        return result.isEmpty || result == "()" ? "1" : result
    }
}

// Helper struct for Quine-McCluskey
struct Implicant: Hashable {
    let value: Int
    let mask: Int  // bits that are "don't care"
    
    func combine(with other: Implicant) -> Implicant? {
        // Must have same mask and differ by exactly one bit
        guard self.mask == other.mask else { return nil }
        
        let diff = self.value ^ other.value
        guard diff.nonzeroBitCount == 1 else { return nil }
        
        return Implicant(value: self.value & other.value, mask: self.mask | diff)
    }
    
    func toString() -> String {
        var result = ""
        let bits = [(4, "x"), (2, "y"), (1, "z")]
        var first = true
        
        for (bit, name) in bits {
            if (mask & bit) == 0 {  // not a don't care
                if !first { result += "∧" }
                result += (value & bit) != 0 ? name : "\(name)̄"
                first = false
            }
        }
        
        return result.isEmpty ? "1" : result
    }
}
