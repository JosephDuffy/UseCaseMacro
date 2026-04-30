import Foundation
import SwiftDiagnostics
import SwiftSyntax

struct UseCaseOperation {
    struct Parameter {
        let localName: String
        let type: String
    }

    let function: FunctionDeclSyntax
    let parameters: [Parameter]
    let returnType: String
    let effectSpecifiers: String
    let isAsync: Bool
    let isThrowing: Bool
    let parameterDocumentationLines: [String]

    init(function: FunctionDeclSyntax) throws {
        self.function = function
        parameterDocumentationLines = Self.parameterDocumentationLines(from: function.leadingTrivia)

        let effectSpecifiers = function.signature.effectSpecifiers
        isAsync = effectSpecifiers?.asyncSpecifier != nil
        isThrowing = effectSpecifiers?.throwsClause != nil

        if effectSpecifiers?.throwsClause?.throwsSpecifier.tokenKind == .keyword(.rethrows) {
            throw UseCaseMacroDiagnosticMessage(
                id: "rethrows-not-supported",
                message: "'@UseCase' does not support 'rethrows' functions.",
                severity: .error
            )
        }

        self.effectSpecifiers = [
            isAsync ? "async" : nil,
            effectSpecifiers?.throwsClause?.trimmedDescription,
        ]
            .compactMap { $0 }
            .joined(separator: " ")

        returnType = function.signature.returnClause?.type.trimmedDescription ?? "Void"

        parameters = try function.signature.parameterClause.parameters.map { parameter in
            if parameter.ellipsis != nil {
                throw UseCaseMacroDiagnosticMessage(
                    id: "variadic-parameters-not-supported",
                    message: "'@UseCase' does not support variadic parameters.",
                    severity: .error
                )
            }

            if parameter.defaultValue != nil {
                throw UseCaseMacroDiagnosticMessage(
                    id: "default-arguments-not-supported",
                    message: "'@UseCase' does not support default parameter values.",
                    severity: .error
                )
            }

            let type = parameter.type.trimmedDescription
            if type == "inout" || type.hasPrefix("inout ") {
                throw UseCaseMacroDiagnosticMessage(
                    id: "inout-parameters-not-supported",
                    message: "'@UseCase' does not support 'inout' parameters.",
                    severity: .error
                )
            }

            let localName = parameter.secondName?.trimmed.text ?? parameter.firstName.trimmed.text
            if localName == "_" {
                throw UseCaseMacroDiagnosticMessage(
                    id: "unnamed-parameters-not-supported",
                    message: "'@UseCase' does not support unnamed parameters.",
                    severity: .error
                )
            }

            return Parameter(
                localName: localName,
                type: type
            )
        }
    }

    func closureHandlerType(closureAttributes: [String]) -> String {
        let parameterList = parameters
            .map { "_ \($0.localName): \($0.type)" }
            .joined(separator: ", ")
        let effectSpecifiersPrefix = effectSpecifiers.isEmpty ? "" : " \(effectSpecifiers)"
        let closureAttributesPrefix = closureAttributes.isEmpty
            ? ""
            : "\(closureAttributes.joined(separator: " ")) "
        return "\(closureAttributesPrefix)(\(parameterList))\(effectSpecifiersPrefix) -> \(returnType)"
    }

    var forwardingExpression: String {
        let callArguments = parameters
            .map(\.localName)
            .joined(separator: ", ")
        let prefix = [
            isThrowing ? "try" : nil,
            isAsync ? "await" : nil,
        ]
            .compactMap { $0 }
            .joined(separator: " ")
        let prefixWithTrailingSpace = prefix.isEmpty ? "" : "\(prefix) "
        return "\(prefixWithTrailingSpace)closureHandler(\(callArguments))"
    }

    var returnsVoid: Bool {
        switch returnType {
        case "Void", "()", "Swift.Void":
            true
        default:
            false
        }
    }

    var constantClosureHeader: String {
        guard !parameters.isEmpty else {
            return "Self {"
        }

        let ignoredParameters = Array(repeating: "_", count: parameters.count)
            .joined(separator: ", ")
        return "Self { \(ignoredParameters) in"
    }

    private static func parameterDocumentationLines(from trivia: Trivia) -> [String] {
        trivia.compactMap { piece in
            guard case let .docLineComment(text) = piece else { return nil }

            let documentationLine = text
                .dropFirst(3)
                .trimmingCharacters(in: .whitespaces)
            let lowercasedDocumentationLine = documentationLine.lowercased()
            guard lowercasedDocumentationLine.hasPrefix("- parameter ")
                || lowercasedDocumentationLine.hasPrefix("- returns:")
            else {
                return nil
            }

            return "/// \(documentationLine)"
        }
    }
}
