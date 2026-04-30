import MacroTesting
import Testing

@testable import UseCaseMacroMacros

@Suite(
    .macros(
        record: .never,
        macros: [
            UseCaseMacro.self,
            UseCaseCallMacro.self,
        ]
    )
)
struct UseCaseMacroTests {
    @Test
    func loginUseCase() {
        assertMacro {
            """
            @UseCase
            struct LoginUseCase: Sendable {
                func callAsFunction(username: String, password: String) async throws -> Account?
            }
            """
        } expansion: {
            """
            struct LoginUseCase: Sendable {
                func callAsFunction(username: String, password: String) async throws -> Account? {
                    try await closureHandler(username, password)
                }

                /// A closure used to perform the use case.
                typealias ClosureHandler = @Sendable (_ username: String, _ password: String) async throws -> Account?

                /// The closure used to perform the use case.
                private let closureHandler: ClosureHandler

                /// Creates a new instance using the provided closure to perform the use case.
                ///
                /// - parameter closureHandler: The closure used to perform the use case.
                init(closureHandler: @escaping ClosureHandler) {
                    self.closureHandler = closureHandler
                }
            }

            extension LoginUseCase {
                /// Creates a use case that always returns the provided value.
                ///
                /// - parameter value: The value for the use case to always return.
                /// - returns: A use case that always returns the provided value.
                static func constant(_ value: Account?) -> Self {
                    Self { _, _ in
                        value
                    }
                }
            }
            """
        }
    }

    @Test
    func documentedUseCaseIncludesParameterDocumentationInGeneratedDeclarations() {
        assertMacro {
            """
            @UseCase
            struct FetchAccountUseCase: Sendable {
                /// Fetches an account.
                ///
                /// - parameter id: The account identifier.
                /// - returns: The account with the provided identifier.
                func callAsFunction(id: UUID) -> Account
            }
            """
        } expansion: {
            """
            struct FetchAccountUseCase: Sendable {
                /// Fetches an account.
                ///
                /// - parameter id: The account identifier.
                /// - returns: The account with the provided identifier.
                func callAsFunction(id: UUID) -> Account {
                    closureHandler(id)
                }

                /// A closure used to perform the use case.
                ///
                /// - parameter id: The account identifier.
                /// - returns: The account with the provided identifier.
                typealias ClosureHandler = @Sendable (_ id: UUID) -> Account

                /// The closure used to perform the use case.
                private let closureHandler: ClosureHandler

                /// Creates a new instance using the provided closure to perform the use case.
                ///
                /// - parameter closureHandler: The closure used to perform the use case.
                init(closureHandler: @escaping ClosureHandler) {
                    self.closureHandler = closureHandler
                }
            }

            extension FetchAccountUseCase {
                /// Creates a use case that always returns the provided value.
                ///
                /// - parameter value: The value for the use case to always return.
                /// - returns: A use case that always returns the provided value.
                static func constant(_ value: Account) -> Self {
                    Self { _ in
                        value
                    }
                }
            }
            """
        }
    }

    @Test
    func customUseCaseCall() {
        assertMacro {
            """
            @UseCase
            struct LoginUseCase: Sendable {
                @UseCaseCall
                func login(username: String, password: String) async throws -> Account?
            }
            """
        } expansion: {
            """
            struct LoginUseCase: Sendable {
                func login(username: String, password: String) async throws -> Account? {
                    try await closureHandler(username, password)
                }

                /// A closure used to perform the use case.
                typealias ClosureHandler = @Sendable (_ username: String, _ password: String) async throws -> Account?

                /// The closure used to perform the use case.
                private let closureHandler: ClosureHandler

                /// Creates a new instance using the provided closure to perform the use case.
                ///
                /// - parameter closureHandler: The closure used to perform the use case.
                init(closureHandler: @escaping ClosureHandler) {
                    self.closureHandler = closureHandler
                }
            }

            extension LoginUseCase {
                /// Creates a use case that always returns the provided value.
                ///
                /// - parameter value: The value for the use case to always return.
                /// - returns: A use case that always returns the provided value.
                static func constant(_ value: Account?) -> Self {
                    Self { _, _ in
                        value
                    }
                }
            }
            """
        }
    }

    @Test
    func generatedHelperCanBeDisabled() {
        assertMacro {
            """
            @UseCase(generatedHelper: [])
            struct LoginUseCase: Sendable {
                func callAsFunction(username: String, password: String) async throws -> Account?
            }
            """
        } expansion: {
            """
            struct LoginUseCase: Sendable {
                func callAsFunction(username: String, password: String) async throws -> Account? {
                    try await closureHandler(username, password)
                }

                /// A closure used to perform the use case.
                typealias ClosureHandler = @Sendable (_ username: String, _ password: String) async throws -> Account?

                /// The closure used to perform the use case.
                private let closureHandler: ClosureHandler

                /// Creates a new instance using the provided closure to perform the use case.
                ///
                /// - parameter closureHandler: The closure used to perform the use case.
                init(closureHandler: @escaping ClosureHandler) {
                    self.closureHandler = closureHandler
                }
            }
            """
        }
    }

    @Test
    func publicAccessControl() {
        assertMacro {
            """
            @UseCase
            public struct FetchAccountUseCase: Sendable {
                public func callAsFunction(id: UUID) async -> Account
            }
            """
        } expansion: {
            """
            public struct FetchAccountUseCase: Sendable {
                public func callAsFunction(id: UUID) async -> Account {
                    await closureHandler(id)
                }

                /// A closure used to perform the use case.
                public typealias ClosureHandler = @Sendable (_ id: UUID) async -> Account

                /// The closure used to perform the use case.
                private let closureHandler: ClosureHandler

                /// Creates a new instance using the provided closure to perform the use case.
                ///
                /// - parameter closureHandler: The closure used to perform the use case.
                public init(closureHandler: @escaping ClosureHandler) {
                    self.closureHandler = closureHandler
                }
            }

            extension FetchAccountUseCase {
                /// Creates a use case that always returns the provided value.
                ///
                /// - parameter value: The value for the use case to always return.
                /// - returns: A use case that always returns the provided value.
                public static func constant(_ value: Account) -> Self {
                    Self { _ in
                        value
                    }
                }
            }
            """
        }
    }

    @Test
    func mainActorUseCase() {
        assertMacro {
            """
            @MainActor
            @UseCase
            struct ShowSettingsUseCase: Sendable {
                func callAsFunction(value: Int) -> String
            }
            """
        } expansion: {
            """
            @MainActor
            struct ShowSettingsUseCase: Sendable {
                func callAsFunction(value: Int) -> String {
                    closureHandler(value)
                }

                /// A closure used to perform the use case.
                typealias ClosureHandler = @MainActor @Sendable (_ value: Int) -> String

                /// The closure used to perform the use case.
                private let closureHandler: ClosureHandler

                /// Creates a new instance using the provided closure to perform the use case.
                ///
                /// - parameter closureHandler: The closure used to perform the use case.
                init(closureHandler: @escaping ClosureHandler) {
                    self.closureHandler = closureHandler
                }
            }

            extension ShowSettingsUseCase {
                /// Creates a use case that always returns the provided value.
                ///
                /// - parameter value: The value for the use case to always return.
                /// - returns: A use case that always returns the provided value.
                static func constant(_ value: String) -> Self {
                    Self { _ in
                        value
                    }
                }
            }
            """
        }
    }

    @Test
    func syncNonThrowingUseCase() {
        assertMacro {
            """
            @UseCase
            struct FormatUseCase {
                func callAsFunction(value: Int) -> String
            }
            """
        } expansion: {
            """
            struct FormatUseCase {
                func callAsFunction(value: Int) -> String {
                    closureHandler(value)
                }

                /// A closure used to perform the use case.
                typealias ClosureHandler = (_ value: Int) -> String

                /// The closure used to perform the use case.
                private let closureHandler: ClosureHandler

                /// Creates a new instance using the provided closure to perform the use case.
                ///
                /// - parameter closureHandler: The closure used to perform the use case.
                init(closureHandler: @escaping ClosureHandler) {
                    self.closureHandler = closureHandler
                }
            }

            extension FormatUseCase {
                /// Creates a use case that always returns the provided value.
                ///
                /// - parameter value: The value for the use case to always return.
                /// - returns: A use case that always returns the provided value.
                static func constant(_ value: String) -> Self {
                    Self { _ in
                        value
                    }
                }
            }
            """
        }
    }

    @Test
    func asyncOnlyUseCase() {
        assertMacro {
            """
            @UseCase
            struct LoadUseCase {
                func callAsFunction(id: UUID) async -> Account
            }
            """
        } expansion: {
            """
            struct LoadUseCase {
                func callAsFunction(id: UUID) async -> Account {
                    await closureHandler(id)
                }

                /// A closure used to perform the use case.
                typealias ClosureHandler = (_ id: UUID) async -> Account

                /// The closure used to perform the use case.
                private let closureHandler: ClosureHandler

                /// Creates a new instance using the provided closure to perform the use case.
                ///
                /// - parameter closureHandler: The closure used to perform the use case.
                init(closureHandler: @escaping ClosureHandler) {
                    self.closureHandler = closureHandler
                }
            }

            extension LoadUseCase {
                /// Creates a use case that always returns the provided value.
                ///
                /// - parameter value: The value for the use case to always return.
                /// - returns: A use case that always returns the provided value.
                static func constant(_ value: Account) -> Self {
                    Self { _ in
                        value
                    }
                }
            }
            """
        }
    }

    @Test
    func throwingOnlyUseCase() {
        assertMacro {
            """
            @UseCase
            struct LoadUseCase {
                func callAsFunction(id: UUID) throws -> Account
            }
            """
        } expansion: {
            """
            struct LoadUseCase {
                func callAsFunction(id: UUID) throws -> Account {
                    try closureHandler(id)
                }

                /// A closure used to perform the use case.
                typealias ClosureHandler = (_ id: UUID) throws -> Account

                /// The closure used to perform the use case.
                private let closureHandler: ClosureHandler

                /// Creates a new instance using the provided closure to perform the use case.
                ///
                /// - parameter closureHandler: The closure used to perform the use case.
                init(closureHandler: @escaping ClosureHandler) {
                    self.closureHandler = closureHandler
                }
            }

            extension LoadUseCase {
                /// Creates a use case that always returns the provided value.
                ///
                /// - parameter value: The value for the use case to always return.
                /// - returns: A use case that always returns the provided value.
                static func constant(_ value: Account) -> Self {
                    Self { _ in
                        value
                    }
                }
            }
            """
        }
    }

    @Test
    func zeroParameters() {
        assertMacro {
            """
            @UseCase
            struct MakeIDUseCase {
                func callAsFunction() -> UUID
            }
            """
        } expansion: {
            """
            struct MakeIDUseCase {
                func callAsFunction() -> UUID {
                    closureHandler()
                }

                /// A closure used to perform the use case.
                typealias ClosureHandler = () -> UUID

                /// The closure used to perform the use case.
                private let closureHandler: ClosureHandler

                /// Creates a new instance using the provided closure to perform the use case.
                ///
                /// - parameter closureHandler: The closure used to perform the use case.
                init(closureHandler: @escaping ClosureHandler) {
                    self.closureHandler = closureHandler
                }
            }

            extension MakeIDUseCase {
                /// Creates a use case that always returns the provided value.
                ///
                /// - parameter value: The value for the use case to always return.
                /// - returns: A use case that always returns the provided value.
                static func constant(_ value: UUID) -> Self {
                    Self {
                        value
                    }
                }
            }
            """
        }
    }

    @Test
    func voidReturnDoesNotGenerateConstant() {
        assertMacro {
            """
            @UseCase
            struct SaveUseCase {
                /// Save the provided account.
                ///
                /// - parameter account: The account to save.
                func callAsFunction(account: Account)
            }
            """
        } expansion: {
            """
            struct SaveUseCase {
                /// Save the provided account.
                ///
                /// - parameter account: The account to save.
                func callAsFunction(account: Account) {
                    closureHandler(account)
                }

                /// A closure used to perform the use case.
                ///
                /// - parameter account: The account to save.
                typealias ClosureHandler = (_ account: Account) -> Void

                /// The closure used to perform the use case.
                private let closureHandler: ClosureHandler

                /// Creates a new instance using the provided closure to perform the use case.
                ///
                /// - parameter closureHandler: The closure used to perform the use case.
                init(closureHandler: @escaping ClosureHandler) {
                    self.closureHandler = closureHandler
                }
            }
            """
        }
    }
}
