import SwiftDiagnostics

struct UseCaseMacroDiagnosticMessage: DiagnosticMessage, Error {
    let id: String
    let message: String
    let severity: DiagnosticSeverity

    var diagnosticID: MessageID {
        MessageID(domain: "UseCaseMacro", id: id)
    }
}
