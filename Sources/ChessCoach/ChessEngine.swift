import Foundation
// Add via Swift Package Manager first — see README.md step 2.
// https://github.com/varton86/StockfishKit
import StockfishKit

/// Thin wrapper so the rest of the app never talks to StockfishKit directly.
/// If you swap engines later (or add a second one for comparison), this is
/// the only file that needs to change.
@MainActor
final class ChessEngine: ObservableObject {
    @Published var isThinking = false
    @Published var lastEvaluation: EngineEvaluation?

    private var engine: Stockfish?

    init() {
        Task { await startEngine() }
    }

    private func startEngine() async {
        do {
            engine = try await Stockfish()
            try await engine?.setOption(name: "Threads", value: "2")
            try await engine?.setOption(name: "Hash", value: "128")
        } catch {
            print("Engine failed to start: \(error)")
        }
    }

    /// Evaluate a single position to a fixed depth. Good for the study board
    /// where you want a quick, responsive answer.
    func evaluate(fen: String, depth: Int = 18) async -> EngineEvaluation? {
        guard let engine else { return nil }
        isThinking = true
        defer { isThinking = false }

        do {
            let result = try await engine.analyze(fen: fen, depth: depth)
            let eval = EngineEvaluation(
                fen: fen,
                centipawns: result.scoreCentipawns,
                mateIn: result.scoreMateIn,
                bestMoveUCI: result.bestMove,
                bestMoveSAN: result.bestMoveSAN ?? result.bestMove,
                principalVariationSAN: result.principalVariationSAN ?? []
            )
            lastEvaluation = eval
            return eval
        } catch {
            print("Evaluation failed: \(error)")
            return nil
        }
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

            if let prevScore = previousBestEval, let currentScore = eval.centipawns {
                let playerIsWhite = move.ply % 2 == 1
                let loss = playerIsWhite
                    ? max(0, prevScore - currentScore)
                    : max(0, currentScore - prevScore)
                annotated.moves[i].classification = MoveClassification.classify(centipawnLoss: loss)
            }
            previousBestEval = eval.centipawns
        }
        return annotated
    }
}
