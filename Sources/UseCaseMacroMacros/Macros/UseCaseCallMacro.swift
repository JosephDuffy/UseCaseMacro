import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct UseCaseCallMacro: BodyMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
        in context: some MacroExpansionContext
    ) throws -> [CodeBlockItemSyntax] {
        guard let function = declaration.as(FunctionDeclSyntax.self) else {
            throw UseCaseMacroDiagnosticMessage(
                id: "use-case-call-non-function",
                message: "'@UseCaseCall' can only be attached to functions.",
                severity: .error
            )
        }

        guard function.body == nil else {
            throw UseCaseMacroDiagnosticMessage(
                id: "use-case-call-has-body",
                message: "The selected use case function must not declare a body.",
                severity: .error
            )
        }

        guard function.isInstanceMethod else {
            throw UseCaseMacroDiagnosticMessage(
                id: "use-case-call-not-instance-method",
                message: "The selected use case function must be an instance method.",
                severity: .error
            )
        }

        let operation = try UseCaseOperation(function: function)
        return [CodeBlockItemSyntax(stringLiteral: operation.forwardingExpression)]
    }
}
