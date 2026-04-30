import SwiftSyntax

extension FunctionDeclSyntax {
    var hasUseCaseCallAttribute: Bool {
        attributes.contains { attribute in
            guard let attribute = attribute.as(AttributeSyntax.self) else { return false }
            let attributeName = attribute.attributeName.trimmedDescription
            return attributeName == "UseCaseCall" || attributeName.hasSuffix(".UseCaseCall")
        }
    }

    var isInstanceMethod: Bool {
        modifiers.allSatisfy { modifier in
            switch modifier.name.tokenKind {
            case .keyword(.static), .keyword(.class):
                return false
            default:
                return true
            }
        }
    }
}

extension DeclGroupSyntax {
    var useCaseFunctions: [FunctionDeclSyntax] {
        memberBlock.members.compactMap { $0.decl.as(FunctionDeclSyntax.self) }
    }

    var isSendableUseCase: Bool {
        inheritanceClause?.inheritedTypes.contains { inheritedType in
            inheritedType.type.trimmedDescription.hasSuffix("Sendable")
        } ?? false
    }

    var useCaseGlobalActorAttributes: [String] {
        attributes.compactMap { attribute in
            guard let attribute = attribute.as(AttributeSyntax.self) else { return nil }
            let attributeName = attribute.attributeName.trimmedDescription

            switch attributeName {
            case "MainActor", "Swift.MainActor":
                return "@MainActor"
            default:
                return nil
            }
        }
    }
}
