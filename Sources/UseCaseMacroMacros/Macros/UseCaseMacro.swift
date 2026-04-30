import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct UseCaseMacro: MemberMacro, MemberAttributeMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) else {
            throw UseCaseMacroDiagnosticMessage(
                id: "non-struct",
                message: "'@UseCase' can only be attached to structs.",
                severity: .error
            )
        }

        let selectedFunction = try UseCaseSelection.selectedFunction(in: declaration)
        if selectedFunction.hasUseCaseCallAttribute {
            guard selectedFunction.body == nil else { return [] }
            guard let operation = try? UseCaseOperation(function: selectedFunction) else { return [] }
            return memberDeclarations(for: operation, declaration: declaration)
        } else {
            guard selectedFunction.body == nil else {
                throw UseCaseMacroDiagnosticMessage(
                    id: "selected-function-has-body",
                    message: "The selected use case function must not declare a body.",
                    severity: .error
                )
            }
            let operation = try UseCaseOperation(function: selectedFunction)
            return memberDeclarations(for: operation, declaration: declaration)
        }
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        guard declaration.is(StructDeclSyntax.self) else { return [] }
        guard let function = member.as(FunctionDeclSyntax.self) else { return [] }
        guard !function.hasUseCaseCallAttribute else { return [] }
        guard !declaration.useCaseFunctions.contains(where: \.hasUseCaseCallAttribute) else { return [] }

        let callAsFunctions = declaration.useCaseFunctions.filter { function in
            function.name.trimmed.text == "callAsFunction"
        }
        guard callAsFunctions.count == 1 else { return [] }
        guard function.name.trimmed.text == "callAsFunction" else { return [] }
        guard function.body == nil else { return [] }
        guard function.isInstanceMethod else { return [] }
        guard (try? UseCaseOperation(function: function)) != nil else { return [] }

        return [AttributeSyntax(stringLiteral: "@UseCaseCall")]
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) else { return [] }
        guard let selectedFunction = try? UseCaseSelection.selectedFunction(in: declaration) else { return [] }
        guard selectedFunction.body == nil else { return [] }
        guard let operation = try? UseCaseOperation(function: selectedFunction) else { return [] }

        let generatedHelpers: Set<UseCaseGeneratedHelpers>
        do {
            generatedHelpers = try UseCaseGeneratedHelpers.parse(from: node)
        } catch let message as UseCaseMacroDiagnosticMessage {
            context.diagnose(
                Diagnostic(
                    node: Syntax(node),
                    message: message
                )
            )
            return []
        }

        guard generatedHelpers.contains(.staticConstant), !operation.returnsVoid else {
            return []
        }

        let accessLevelPrefix = accessLevel(for: declaration)
            .map { "\($0) " } ?? ""
        let constantDeclaration = """
        \(operation.constantFunctionDocumentation)
        \(accessLevelPrefix)static func constant(_ value: \(operation.returnType)) -> Self {
            \(operation.constantClosureHeader)
                value
            }
        }
        """
        return [
            try ExtensionDeclSyntax("""
            extension \(raw: type.trimmedDescription) {
            \(raw: indent(constantDeclaration, by: 4))
            }
            """),
        ]
    }

    private static func memberDeclarations(
        for operation: UseCaseOperation,
        declaration: some DeclGroupSyntax
    ) -> [DeclSyntax] {
        let accessLevel = accessLevel(for: declaration)
        let accessLevelPrefix = accessLevel.map { "\($0) " } ?? ""
        let closureAttributes = declaration.useCaseGlobalActorAttributes
            + (declaration.isSendableUseCase ? ["@Sendable"] : [])

        return [
            DeclSyntax(stringLiteral: """
            \(operation.closureHandlerDocumentation)
            \(accessLevelPrefix)typealias ClosureHandler = \(operation.closureHandlerType(closureAttributes: closureAttributes))
            """),
            DeclSyntax(stringLiteral: """
            /// The closure used to perform the use case.
            private let closureHandler: ClosureHandler
            """),
            DeclSyntax(stringLiteral: """
            /// Creates a new instance using the provided closure to perform the use case.
            ///
            /// - parameter closureHandler: The closure used to perform the use case.
            \(accessLevelPrefix)init(closureHandler: @escaping ClosureHandler) {
                self.closureHandler = closureHandler
            }
            """),
        ]
    }

    private static func accessLevel(for declaration: some DeclGroupSyntax) -> String? {
        for modifier in declaration.modifiers {
            switch modifier.name.tokenKind {
            case .keyword(.public):
                return "public"
            case .keyword(.internal):
                return "internal"
            case .keyword(.fileprivate):
                return "fileprivate"
            case .keyword(.package):
                return "package"
            default:
                break
            }
        }
        return nil
    }

    private static func indent(_ string: String, by spaceCount: Int) -> String {
        let indentation = String(repeating: " ", count: spaceCount)
        return string
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { "\($0.isEmpty ? "" : indentation)\($0)" }
            .joined(separator: "\n")
    }
}

private extension UseCaseOperation {
    var closureHandlerDocumentation: String {
        if parameterDocumentationLines.isEmpty {
            return "/// A closure used to perform the use case."
        } else {
            return """
            /// A closure used to perform the use case.
            ///
            \(parameterDocumentationLines.joined(separator: "\n"))
            """
        }
    }

    var constantFunctionDocumentation: String {
        """
        /// Creates a use case that always returns the provided value.
        ///
        /// - parameter value: The value for the use case to always return.
        /// - returns: A use case that always returns the provided value.
        """
    }
}
