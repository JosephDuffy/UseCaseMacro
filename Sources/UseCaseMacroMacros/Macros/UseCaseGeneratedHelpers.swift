import SwiftDiagnostics
import SwiftSyntax

enum UseCaseGeneratedHelpers {
    case staticConstant

    static func parse(from node: AttributeSyntax) throws -> Set<Self> {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return [.staticConstant]
        }

        for argument in arguments {
            guard argument.label?.trimmed.text == "generatedHelper" else { continue }

            guard let arrayExpression = argument.expression.as(ArrayExprSyntax.self) else {
                throw UseCaseMacroDiagnosticMessage(
                    id: "invalid-generated-helper",
                    message: "'generatedHelper' must be an array literal.",
                    severity: .error
                )
            }

            var helpers: Set<Self> = []
            for element in arrayExpression.elements {
                let helperName = element.expression.trimmedDescription
                switch helperName {
                case ".staticConstant", "UseCaseGeneratedHelper.staticConstant":
                    helpers.insert(.staticConstant)
                default:
                    throw UseCaseMacroDiagnosticMessage(
                        id: "unknown-generated-helper",
                        message: "Unknown generated helper '\(helperName)'.",
                        severity: .error
                    )
                }
            }
            return helpers
        }

        return [.staticConstant]
    }
}
