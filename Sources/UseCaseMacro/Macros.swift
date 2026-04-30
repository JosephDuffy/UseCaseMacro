import UseCaseMacroFoundation

/// A macro that turns a struct into a closure-backed use case.
///
/// The macro derives its closure handler from the function marked
/// ``UseCaseCall()``. If no function is marked it uses `callAsFunction`.
///
/// - parameter generatedHelper: Optional helper API generated alongside the
///   closure-backed use case implementation.
@attached(member, names: named(ClosureHandler), named(closureHandler), named(init))
@attached(memberAttribute)
@attached(extension, names: named(constant))
public macro UseCase(
    generatedHelper: [UseCaseGeneratedHelper] = [.staticConstant]
) = #externalMacro(module: "UseCaseMacroMacros", type: "UseCaseMacro")

/// Marks the function that should be backed by a use case closure handler.
@attached(body)
public macro UseCaseCall() = #externalMacro(module: "UseCaseMacroMacros", type: "UseCaseCallMacro")
