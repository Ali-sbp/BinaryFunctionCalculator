import SwiftUI

struct ContentView: View {
    @StateObject private var booleanFunc = BooleanFunction()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                Picker("View", selection: $selectedTab) {
                    Text("Input").tag(0)
                    Text("Truth Table").tag(1)
                    Text("Results").tag(2)
                    Text("Graphs").tag(3)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content
                TabView(selection: $selectedTab) {
                    ExpressionInputView(booleanFunc: booleanFunc)
                        .tag(0)
                    
                    DetailedTruthTableView(booleanFunc: booleanFunc)
                        .tag(1)
                    
                    ResultsView(booleanFunc: booleanFunc)
                        .tag(2)
                    
                    GraphsView(booleanFunc: booleanFunc)
                        .tag(3)
                }
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif
            }
            .navigationTitle("Boolean Calculator")
            #if os(macOS)
            .frame(minWidth: 800, minHeight: 600)
            #endif
        }
        #if os(iOS)
        .navigationViewStyle(.stack)
        #endif
    }
}

// Expression Input View with buttons
struct ExpressionInputView: View {
    @ObservedObject var booleanFunc: BooleanFunction
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Expression Display
                VStack(spacing: 10) {
                    Text("f(x,y,z) =")
                        .font(.headline)
                    
                    Text(booleanFunc.expressionString.isEmpty ? "..." : booleanFunc.expressionString)
                        .font(.system(size: 24, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                        .textSelection(.enabled)
                }
                .padding()
                
                // Variable Buttons
                VStack(spacing: 12) {
                    Text("Variables")
                        .font(.headline)
                    
                    HStack(spacing: 15) {
                        VariableButton(text: "x") {
                            booleanFunc.addToken(.variable("x", negated: false))
                        }
                        VariableButton(text: "y") {
                            booleanFunc.addToken(.variable("y", negated: false))
                        }
                        VariableButton(text: "z") {
                            booleanFunc.addToken(.variable("z", negated: false))
                        }
                    }
                }
                .padding(.horizontal)
                
                // NOT Button (toggles last variable)
                VStack(spacing: 12) {
                    Text("Negation")
                        .font(.headline)
                    
                    OperatorButton(symbol: "¬", name: "NOT", color: .purple) {
                        booleanFunc.toggleLastNegation()
                    }
                    .frame(maxWidth: 200)
                }
                .padding(.horizontal)
                
                // Binary Operators
                VStack(spacing: 12) {
                    Text("Binary Operators")
                        .font(.headline)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        OperatorButton(symbol: "∧", name: "AND", color: .blue) {
                            booleanFunc.addToken(.operation(.and))
                        }
                        OperatorButton(symbol: "∨", name: "OR", color: .green) {
                            booleanFunc.addToken(.operation(.or))
                        }
                        OperatorButton(symbol: "⊕", name: "XOR", color: .orange) {
                            booleanFunc.addToken(.operation(.xor))
                        }
                        OperatorButton(symbol: "↓", name: "NOR", color: .red) {
                            booleanFunc.addToken(.operation(.nor))
                        }
                        OperatorButton(symbol: "↑", name: "NAND", color: .pink) {
                            booleanFunc.addToken(.operation(.nand))
                        }
                        OperatorButton(symbol: "→", name: "IMP", color: .cyan) {
                            booleanFunc.addToken(.operation(.implies))
                        }
                        OperatorButton(symbol: "←", name: "R-IMP", color: .teal) {
                            booleanFunc.addToken(.operation(.reverseImplies))
                        }
                        OperatorButton(symbol: "↔", name: "XNOR", color: .indigo) {
                            booleanFunc.addToken(.operation(.xnor))
                        }
                    }
                }
                .padding(.horizontal)
                
                // Parentheses
                VStack(spacing: 12) {
                    Text("Parentheses")
                        .font(.headline)
                    
                    HStack(spacing: 15) {
                        OperatorButton(symbol: "(", name: "", color: .gray) {
                            booleanFunc.addToken(.leftParen)
                        }
                        OperatorButton(symbol: ")", name: "", color: .gray) {
                            booleanFunc.addToken(.rightParen)
                        }
                    }
                    .frame(maxWidth: 300)
                }
                .padding(.horizontal)
                
                // Control Buttons
                HStack(spacing: 15) {
                    Button(action: {
                        booleanFunc.removeLastToken()
                    }) {
                        Label("Delete", systemImage: "delete.left")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        booleanFunc.clearExpression()
                    }) {
                        Label("Clear", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(8)
                    }
                }
                .padding()
                
                Spacer()
            }
        }
    }
}

// Helper Views
struct VariableButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .frame(width: 80, height: 80)
                .background(Color.blue.opacity(0.2))
                .foregroundColor(.blue)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct OperatorButton: View {
    let symbol: String
    let name: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(symbol)
                    .font(.system(size: 24, weight: .bold))
                if !name.isEmpty {
                    Text(name)
                        .font(.caption)
                }
            }
            .frame(height: 70)
            .frame(maxWidth: .infinity)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// Detailed Truth Table with intermediate steps
// TODO: extra sign bug, last column bug. 
struct DetailedTruthTableView: View {
    @ObservedObject var booleanFunc: BooleanFunction
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(spacing: 15) {
                Text("Truth Table with Steps")
                    .font(.headline)
                    .padding(.top)
                
                if booleanFunc.expression.isEmpty {
                    Text("Enter an expression to see the truth table")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    HStack(spacing: 0) {
                        // Input variables
                        VStack(spacing: 0) {
                            TableCell(text: "x", isHeader: true, width: 40)
                            ForEach(0..<8, id: \.self) { i in
                                TableCell(text: (i & 4) != 0 ? "1" : "0", width: 40)
                                if i < 7 { Divider() }
                            }
                        }
                        
                        VStack(spacing: 0) {
                            TableCell(text: "y", isHeader: true, width: 40)
                            ForEach(0..<8, id: \.self) { i in
                                TableCell(text: (i & 2) != 0 ? "1" : "0", width: 40)
                                if i < 7 { Divider() }
                            }
                        }
                        
                        VStack(spacing: 0) {
                            TableCell(text: "z", isHeader: true, width: 40)
                            ForEach(0..<8, id: \.self) { i in
                                TableCell(text: (i & 1) != 0 ? "1" : "0", width: 40)
                                if i < 7 { Divider() }
                            }
                        }
                        
                        // Intermediate steps
                        ForEach(Array(booleanFunc.stepLabels.enumerated()), id: \.offset) { index, label in
                            VStack(spacing: 0) {
                                TableCell(text: label, isHeader: true, width: 60)
                                ForEach(0..<8, id: \.self) { row in
                                    let value = index < booleanFunc.intermediateSteps.count && row < booleanFunc.intermediateSteps[index].count
                                        ? (booleanFunc.intermediateSteps[index][row] ? "1" : "0")
                                        : "?"
                                    TableCell(text: value, width: 60)
                                    if row < 7 { Divider() }
                                }
                            }
                        }
                        
                        // Final result
                        VStack(spacing: 0) {
                            TableCell(text: "f", isHeader: true, width: 50, backgroundColor: .blue.opacity(0.3))
                            ForEach(0..<8, id: \.self) { i in
                                TableCell(
                                    text: booleanFunc.truthVector[i] ? "1" : "0",
                                    width: 50,
                                    backgroundColor: booleanFunc.truthVector[i] ? .green.opacity(0.2) : .red.opacity(0.2)
                                )
                                if i < 7 { Divider() }
                            }
                        }
                    }
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                    .padding()
                    
                    // Minterms and Maxterms
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Minterms (f=1):")
                                .font(.subheadline)
                                .bold()
                            Text(booleanFunc.minterms.map(String.init).joined(separator: ", "))
                                .font(.subheadline)
                        }
                        
                        HStack {
                            Text("Maxterms (f=0):")
                                .font(.subheadline)
                                .bold()
                            Text(booleanFunc.maxterms.map(String.init).joined(separator: ", "))
                                .font(.subheadline)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
    }
}

struct TableCell: View {
    let text: String
    var isHeader: Bool = false
    var width: CGFloat = 50
    var backgroundColor: Color = .clear
    
    var body: some View {
        Text(text)
            .font(isHeader ? .headline : .body.monospaced())
            .frame(width: width)
            .padding(.vertical, 10)
            .background(backgroundColor)
    }
}

// Results view - CDNF, CCNF, Shannon
struct ResultsView: View {
    @ObservedObject var booleanFunc: BooleanFunction
    @State private var selectedVariable = "x"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Results")
                    .font(.headline)
                    .padding(.top)
                
                if booleanFunc.expression.isEmpty {
                    Text("Enter an expression to see results")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    resultContent
                }
                
                Spacer()
            }
            .padding(.bottom)
        }
    }
    
    var resultContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Expression: \(booleanFunc.expressionString)")
                .font(.subheadline)
                .padding(.horizontal)
                
                // Operations Reference
                GroupBox(label: Label("Operations", systemImage: "function")) {
                    VStack(alignment: .leading, spacing: 6) {
                        OperationRow(symbol: "∧", name: "AND (conjunction)")
                        OperationRow(symbol: "∨", name: "OR (disjunction)")
                        OperationRow(symbol: "⊕", name: "XOR (exclusive or)")
                        OperationRow(symbol: "¬ or x̄", name: "NOT (negation)")
                        OperationRow(symbol: "↓", name: "NOR (Pierce arrow)")
                        OperationRow(symbol: "↑", name: "NAND (Sheffer stroke)")
                    }
                    .font(.caption)
                }
                .padding(.horizontal)
                
                // CDNF
                FormCard(
                    title: "СДНФ (Canonical DNF)",
                    content: booleanFunc.getCDNF(),
                    color: .blue
                )
                
                // Minimal CDNF with steps
                VStack(alignment: .leading, spacing: 10) {
                    Text("СДНФ (Minimal)")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Text(booleanFunc.getMinimalCDNF())
                        .font(.system(.title3, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                        .textSelection(.enabled)
                    
                    DisclosureGroup("Show Minimization Steps") {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(booleanFunc.getCDNFMinimizationSteps(), id: \.self) { step in
                                Text(step)
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal)
                }
                .padding(.horizontal)
                
                // CCNF
                FormCard(
                    title: "СКНФ (Canonical CNF)",
                    content: booleanFunc.getCCNF(),
                    color: .orange
                )
                
                // Minimal CCNF with steps
                VStack(alignment: .leading, spacing: 10) {
                    Text("СКНФ (Minimal)")
                        .font(.headline)
                        .foregroundColor(.purple)
                    
                    Text(booleanFunc.getMinimalCCNF())
                        .font(.system(.title3, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.purple.opacity(0.2))
                        .cornerRadius(8)
                        .textSelection(.enabled)
                    
                    DisclosureGroup("Show Minimization Steps") {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(booleanFunc.getCCNFMinimizationSteps(), id: \.self) { step in
                                Text(step)
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal)
                }
                .padding(.horizontal)
                
                // Shannon Decomposition with variable selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Shannon Decomposition")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Picker("Variable", selection: $selectedVariable) {
                        Text("x").tag("x")
                        Text("y").tag("y")
                        Text("z").tag("z")
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(booleanFunc.getShannonDecompositionDetailed(by: selectedVariable), id: \.self) { step in
                            Text(step)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Polynomial Form (Zhegalkin / ANF)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Polynomial Form P_f(x,y,z)")
                        .font(.headline)
                        .foregroundColor(.purple)
                    
                    // Method 1: Coefficients
                    let coeffResult = booleanFunc.getPolynomialFormCoefficients()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        DisclosureGroup("Method 1: Coefficients (Möbius Transform)") {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(coeffResult.steps, id: \.self) { step in
                                    Text(step)
                                        .font(.system(.body, design: .monospaced))
                                        .textSelection(.enabled)
                                }
                            }
                            .padding(.top, 8)
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal)
                    
                    // Method 2: Triangle
                    let triangleResult = booleanFunc.getPolynomialFormTriangle()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        DisclosureGroup("Method 2: Pascal's Triangle (XOR of lines)") {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(triangleResult.steps, id: \.self) { step in
                                    Text(step)
                                        .font(.system(.body, design: .monospaced))
                                        .textSelection(.enabled)
                                }
                            }
                            .padding(.top, 8)
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal)
                    
                    // Final result box
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Result:")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Text("P_f(x,y,z) = \(coeffResult.polynomial)")
                            .font(.system(.title3, design: .monospaced))
                            .fontWeight(.semibold)
                            .foregroundColor(.purple)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
        }
    }
}

struct OperationRow: View {
    let symbol: String
    let name: String
    
    var body: some View {
        HStack {
            Text(symbol)
                .font(.system(size: 16))
                .frame(width: 30)
            Text(name)
        }
    }
}

struct FormCard: View {
    let title: String
    let content: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(color)
            
            Text(content)
                .font(.system(.body, design: .monospaced))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(color.opacity(0.1))
                .cornerRadius(8)
                .textSelection(.enabled)
        }
        .padding(.horizontal)
    }
}

// MARK: - Graphs View
struct GraphsView: View {
    @ObservedObject var booleanFunc: BooleanFunction
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if booleanFunc.expression.isEmpty {
                    Text("Enter an expression to see graphs")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    // Semantic Tree (Truth table based)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Semantic Tree")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text("Based on truth table analysis")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        SemanticTreeView(booleanFunc: booleanFunc)
                            .padding()
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Syntactic Tree (Expression based)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Syntactic Tree")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        Text("Based on expression structure")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        SyntacticTreeView(booleanFunc: booleanFunc)
                            .padding()
                            .background(Color.green.opacity(0.05))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Semantic Tree View
struct SemanticTreeView: View {
    @ObservedObject var booleanFunc: BooleanFunction
    
    var body: some View {
        ScrollView(.horizontal) {
            VStack(spacing: 20) {
                Text("Shannon Expansion Tree")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                SemanticNodeView(
                    truthVector: booleanFunc.truthVector,
                    level: 0,
                    indexOffset: 0
                )
            }
            .padding()
        }
    }
}

struct SemanticNodeView: View {
    let truthVector: [Bool]
    let level: Int  // 0=x, 1=y, 2=z, 3=leaf
    let indexOffset: Int
    
    var body: some View {
        VStack(spacing: 0) {
            if level < 3 {
                // Variable node
                let varName = level == 0 ? "x" : (level == 1 ? "y" : "z")
                
                ZStack {
                    Text(varName)
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(10)
                        .background(Circle().fill(Color.blue.opacity(0.3)))
                    
                    // Diagonal lines positioned relative to the circle
                    GeometryReader { geometry in
                        let centerX = geometry.size.width / 2
                        let bottomY = geometry.size.height
                        
                        // Left diagonal line (to positive variable) - solid
                        Path { path in
                            path.move(to: CGPoint(x: centerX, y: bottomY))
                            path.addLine(to: CGPoint(x: centerX - 60, y: bottomY + 40))
                        }
                        .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                        
                        // Right diagonal line (to negated variable) - dashed
                        Path { path in
                            path.move(to: CGPoint(x: centerX, y: bottomY))
                            path.addLine(to: CGPoint(x: centerX + 60, y: bottomY + 40))
                        }
                        .stroke(Color.blue.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                    }
                }
                .frame(height: 50)
                
                Spacer()
                    .frame(height: 30)
                
                HStack(spacing: 80) {
                    // Left branch (variable = 1, positive)
                    VStack(spacing: 5) {
                        Text(varName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        
                        let leftOffset = indexOffset + (1 << (2 - level))
                        SemanticNodeView(
                            truthVector: truthVector,
                            level: level + 1,
                            indexOffset: leftOffset
                        )
                    }
                    
                    // Right branch (variable = 0, negated)
                    VStack(spacing: 5) {
                        Text("\(varName)̄")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        
                        let rightOffset = indexOffset
                        SemanticNodeView(
                            truthVector: truthVector,
                            level: level + 1,
                            indexOffset: rightOffset
                        )
                    }
                }
            } else {
                // Leaf node - show truth value
                let value = truthVector[indexOffset]
                Text(value ? "1" : "0")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(value ? .green : .red)
                    .padding(8)
                    .background(Circle().fill(value ? Color.green.opacity(0.2) : Color.red.opacity(0.2)))
            }
        }
    }
}

// MARK: - Syntactic Tree View
struct SyntacticTreeView: View {
    @ObservedObject var booleanFunc: BooleanFunction
    
    var body: some View {
        ScrollView(.horizontal) {
            VStack(spacing: 15) {
                if let tree = buildTree(from: booleanFunc.expression) {
                    TreeNodeView(node: tree, depth: 0)
                } else {
                    Text("Cannot parse expression tree")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
    
    private func buildTree(from expression: [ExprToken]) -> TreeNode? {
        if expression.isEmpty { return nil }
        
        // Handle negated variable as unary operator
        if expression.count == 1, case .variable(let name, let negated) = expression[0] {
            if negated {
                // Create negation operator node with variable as child
                return TreeNode(
                    value: "¬",
                    type: .operatorNode,
                    left: TreeNode(value: name, type: .variable, left: nil, right: nil),
                    right: nil
                )
            } else {
                return TreeNode(value: name, type: .variable, left: nil, right: nil)
            }
        }
        
        // Find the main operator (lowest precedence, rightmost)
        var minPrecedence = Int.max
        var mainOpIndex: Int?
        var parenDepth = 0
        
        for (index, token) in expression.enumerated() {
            switch token {
            case .leftParen:
                parenDepth += 1
            case .rightParen:
                parenDepth -= 1
            case .operation(let op):
                if parenDepth == 0 {
                    if op.precedence <= minPrecedence {
                        minPrecedence = op.precedence
                        mainOpIndex = index
                    }
                }
            case .variable:
                break
            }
        }
        
        // If we found an operator, split the expression
        if let opIndex = mainOpIndex {
            let leftExpr = Array(expression[..<opIndex])
            let rightExpr = Array(expression[(opIndex + 1)...])
            
            if case .operation(let op) = expression[opIndex] {
                return TreeNode(
                    value: op.rawValue,
                    type: .operatorNode,
                    left: buildTree(from: leftExpr),
                    right: buildTree(from: rightExpr)
                )
            }
        }
        
        // Remove outer parentheses if present
        if expression.first == .leftParen && expression.last == .rightParen {
            let inner = Array(expression.dropFirst().dropLast())
            return buildTree(from: inner)
        }
        
        return nil
    }
}

// Tree Node Model
class TreeNode {
    let value: String
    let type: NodeType
    let left: TreeNode?
    let right: TreeNode?
    
    enum NodeType {
        case operatorNode
        case variable
    }
    
    init(value: String, type: NodeType, left: TreeNode?, right: TreeNode?) {
        self.value = value
        self.type = type
        self.left = left
        self.right = right
    }
}

// Tree Node View
struct TreeNodeView: View {
    let node: TreeNode
    let depth: Int
    
    var body: some View {
        VStack(spacing: 10) {
            // Current node
            Text(node.value)
                .font(node.type == .operatorNode ? .title3 : .body)
                .fontWeight(node.type == .operatorNode ? .bold : .regular)
                .padding(8)
                .background(
                    Circle()
                        .fill(node.type == .operatorNode ? Color.green.opacity(0.2) : Color.purple.opacity(0.2))
                )
            
            // Children
            if node.left != nil || node.right != nil {
                Rectangle()
                    .fill(Color.green.opacity(0.3))
                    .frame(width: 2, height: 20)
                
                // Check if unary operator (only left child)
                if node.left != nil && node.right == nil {
                    // Unary operator (negation)
                    TreeNodeView(node: node.left!, depth: depth + 1)
                } else {
                    // Binary operator
                    HStack(spacing: 30) {
                        if let left = node.left {
                            VStack {
                                Text("L")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                TreeNodeView(node: left, depth: depth + 1)
                            }
                        }
                        
                        if let right = node.right {
                            VStack {
                                Text("R")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                TreeNodeView(node: right, depth: depth + 1)
                            }
                        }
                    }
                }
            }
        }
    }
}
