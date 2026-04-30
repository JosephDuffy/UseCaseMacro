import Testing
import UseCaseMacro

@UseCase
private struct DoubleUseCase: Sendable {
    func callAsFunction(value: Int) -> Int
}

@UseCase
private struct LoadNameUseCase: Sendable {
    @UseCaseCall
    func load(id: Int) async throws -> String
}

@MainActor
@UseCase
private struct MainActorUseCase: Sendable {
    func callAsFunction(value: Int) -> Int
}

struct UseCaseMacroAPITests {
    @Test
    func generatedUseCaseCanBeCalled() {
        let useCase = DoubleUseCase { value in
            value * 2
        }

        #expect(useCase(value: 4) == 8)
        #expect(DoubleUseCase.constant(42)(value: 4) == 42)
    }

    @Test
    func customUseCaseCallCanBeCalled() async throws {
        let useCase = LoadNameUseCase { id in
            "Name \(id)"
        }

        let name = try await useCase.load(id: 7)
        #expect(name == "Name 7")
    }

    @MainActor
    @Test
    func mainActorUseCaseCanBeCalled() {
        let useCase = MainActorUseCase { value in
            value + 1
        }

        #expect(useCase(value: 4) == 5)
        #expect(MainActorUseCase.constant(42)(value: 4) == 42)
    }
}
