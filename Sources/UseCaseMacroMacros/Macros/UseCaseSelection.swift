import SwiftDiagnostics
import SwiftSyntax

enum UseCaseSelection {
    static func selectedFunction(in declaration: some DeclGroupSyntax) throws -> FunctionDeclSyntax {
        let functions = declaration.useCaseFunctions
        let markedFunctions = functions.filter(\.hasUseCaseCallAttribute)

        guard markedFunctions.count <= 1 else {
            throw UseCaseMacroDiagnosticMessage(
                id: "multiple-use-case-call-functions",
                message: "'@UseCase' supports only one method marked '@UseCaseCall'.",
                severity: .error
            )
        }

        if let markedFunction = markedFunctions.first {
            try validateInstanceMethod(markedFunction)
            return markedFunction
        }

        let callAsFunctions = functions.filter { function in
            function.name.trimmed.text == "callAsFunction"
        }

        guard !callAsFunctions.isEmpty else {
            throw UseCaseMacroDiagnosticMessage(
                id: "missing-selected-function",
                message: "'@UseCase' requires a 'callAsFunction' method or exactly one method marked '@UseCaseCall'.",
                severity: .error
            )
        }

        guard callAsFunctions.count == 1 else {
            throw UseCaseMacroDiagnosticMessage(
                id: "ambiguous-call-as-function",
                message: "'@UseCase' found multiple 'callAsFunction' methods. Mark exactly one method with '@UseCaseCall'.",
                severity: .error
            )
        }

        let selectedFunction = callAsFunctions[callAsFunctions.startIndex]
        try validateInstanceMethod(selectedFunction)
        return selectedFunction
    }

    private static func validateInstanceMethod(_ function: FunctionDeclSyntax) throws {
        guard function.isInstanceMethod else {
            throw UseCaseMacroDiagnosticMessage(
                id: "selected-function-not-instance-method",
                message: "The selected use case function must be an instance method.",
                severity: .error
            )
        }
    }
}
