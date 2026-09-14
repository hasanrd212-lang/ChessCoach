import Foundation
import ChessKitEngine

/// Thin wrapper so the rest of the app never talks to ChessKitEngine directly.
/// If you swap engines later (or add a second one for comparison), this is
/// the only file that needs to change.
@MainActor
final class ChessEngine: ObservableObject {

    @Published var isThinking = false
    @Published var lastEvaluation: EngineEvaluation?

    private var engine: Engine?

    init() {
        Task { await startEngine() }
    }

    private func startEngine() async {
        let newEngine = Engine(type: .stockfish)
        engine = newEngine

        // Stockfish 17 needs its NNUE files pointed to explicitly.
        // Add nn-*.nnue files to the app bundle (see README/project.yml) first.
        if let bigFile = Bundle.main.url(forResource: "nn-1c0000000000", withExtension: "nnue") {
            await newEngine.send(command: .setoption(id: "EvalFile", value: bigFile.path))
        }
        if let smallFile = Bundle.main.url(forResource: "nn-37f18f62d772", withExtension: "nnue") {
            await newEngine.send(command: .setoption(id: "EvalFileSmall", value: smallFile.path))
        }

        await newEngine.send(command: .setoption(id: "Threads", value: "2"))
        await newEngine.send(command: .setoption(id: "Hash", value: "128"))

        newEngine.start()
    }

    /// Evaluate a single position to a fixed depth. Good for the study board
    /// where you want a quick, responsive answer.
    func evaluate(fen: String, depth: Int = 18) async -> EngineEvaluation? {
        guard let engine, await engine.isRunning else { return nil }
        guard let stream = await engine.responseStream else { return nil }

        isThinking = true
        defer { isThinking = false }

        await engine.send(command: .stop)
        await engine.send(command: .position(.fen(fen)))
        await engine.send(command: .go(depth: depth))

        var centipawns: Int? = nil
        var mateIn: Int? = nil
        var pv: [String] = []
        var bestMoveUCI: String? = nil

        for await response in stream {
            switch response {
            case .info(let info):
                if let score = info.score {
                    switch score {
                    case .cp(let cp):
                        centipawns = cp
                        mateIn = nil
                    case .mate(let moves):
                        mateIn = moves
                        centipawns = nil
                    }
                }
                if let infoPV = info.pv {
                    pv = infoPV
                }
            case .bestmove(let move, _):
                bestMoveUCI = move
            default:
                break
            }
            // Stop consuming once we have the final best move for this request.
            if bestMoveUCI != nil { break }
        }

        guard let bestMoveUCI else { return nil }

        let eval = EngineEvaluation(
            fen: fen,
            centipawns: centipawns,
            mateIn: mateIn,
            bestMoveUCI: bestMoveUCI,
            bestMoveSAN: bestMoveUCI,
            principalVariationSAN: pv
        )
        lastEvaluation = eval
        return eval
    }

    /// Walk every move of an imported game and attach an evaluation + a
    /// classification (best/good/inaccuracy/mistake/blunder) to each one.
    /// This is the core of "post-game analysis."
    func analyzeGame(_ game: ImportedGame, depth: Int = 16) async -> ImportedGame {
        var annotated = game
        var previousBestEval: Int? = nil

        for i in annotated.moves.indices {
            let move = annotated.moves[i]
            guard let eval = await evaluate(fen: move.fenAfter, depth: depth) else { continue }
            annotated.moves[i].evaluation = eval

            if let prevScore = previousBestEval, let currentScore = eval.centipawns }