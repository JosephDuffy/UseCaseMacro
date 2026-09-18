import MacroTesting
import Testing

@testable import UseCaseMacroMacros

@Suite(
    .macros(
        [
            UseCaseMacro.self,
            UseCaseCallMacro.self,
        ],
        record: .never,
    )
)
struct UseCaseMacroDiagnosticsTests {
    @Test
    func useCaseRequiresStruct() {
        assertMacro {
            """
            @UseCase
            enum BadUseCase {}
            """
        } diagnostics: {
            """
            @UseCase
            ┬───────
            ╰─ 🛑 '@UseCase' can only be attached to structs.
            enum BadUseCase {}
            """
        }
    }

    @Test
    func missingSelectedFunction() {
        assertMacro {
            """
            @UseCase
            struct BadUseCase {}
            """
        } diagnostics: {
            """
            @UseCase
            ┬───────
            ╰─ 🛑 '@UseCase' requires a 'callAsFunction' method or exactly one method marked '@UseCaseCall'.
            struct BadUseCase {}
            """
        }
    }

    @Test
    func ambiguousDefaultFunction() {
        assertMacro {
            """
            @UseCase
            struct BadUseCase {
                func callAsFunction(id: UUID) -> Account
                func callAsFunction(name: String) -> Account
            }
            """
        } diagnostics: {
            """
            @UseCase
            ┬───────
            ╰─ 🛑 '@UseCase' found multiple 'callAsFunction' methods. Mark exactly one method with '@UseCaseCall'.
            struct BadUseCase {
                func callAsFunction(id: UUID) -> Account
                func callAsFunction(name: String) -> Account
            }
            """
        }
    }

    @Test
    func multipleUseCaseCallFunctions() {
        assertMacro {
            """
            @UseCase
            struct BadUseCase {
                @UseCaseCall
                func load(id: UUID) -> Account
                @UseCaseCall
                func refresh(id: UUID) -> Account
            }
            """
        } diagnostics: {
            """
            @UseCase
            ┬───────
            ╰─ 🛑 '@UseCase' supports only one method marked '@UseCaseCall'.
            struct BadUseCase {
                @UseCaseCall
                func load(id: UUID) -> Account
                @UseCaseCall
                func refresh(id: UUID) -> Account
            }
            """
        }
    }

    @Test
    func unsupportedParameter() {
        assertMacro {
            """
            @UseCase
            struct BadUseCase {
                func callAsFunction(value: inout Int)
            }
            """
        } diagnostics: {
            """
            @UseCase
            ┬───────
            ╰─ 🛑 '@UseCase' does not support 'inout' parameters.
            struct BadUseCase {
                func callAsFunction(value: inout Int)
            }
            """
        }
    }

    @Test
    func invalidGeneratedHelper() {
        assertMacro {
            """
            @UseCase(generatedHelper: [.mock])
            struct BadUseCase {
                func callAsFunction() -> Account
            }
            """
        } diagnostics: {
            """
            @UseCase(generatedHelper: [.mock])
            ┬─────────────────────────────────
            ╰─ 🛑 Unknown generated helper '.mock'.
            struct BadUseCase {
                func callAsFunction() -> Account
            }
            """
        }
    }

    @Test
    func selectedFunctionMustBeSignatureOnly() {
        assertMacro {
            """
            @UseCase
            struct BadUseCase {
                func callAsFunction() -> Account {
                    Account()
                }
            }
            """
        } diagnostics: {
            """
            @UseCase
            ┬───────
            ╰─ 🛑 The selected use case function must not declare a body.
            struct BadUseCase {
                func callAsFunction() -> Account {
                    Account()
                }
            }
            """
        }
    }
}
