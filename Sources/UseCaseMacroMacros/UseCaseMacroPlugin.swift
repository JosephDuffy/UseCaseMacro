import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct UseCaseMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        UseCaseMacro.self,
        UseCaseCallMacro.self,
    ]
}
