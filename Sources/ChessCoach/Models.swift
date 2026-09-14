import Foundation

/// A single evaluated position, as returned by the engine.
struct EngineEvaluation: Identifiable {
    let id = UUID()
    let fen: String
    /// Centipawn score from White's perspective. Nil if it's a forced mate line.
    let centipawns: Int?
    /// Mate in N moves, positive = White mates, negative = Black mates.
    let mateIn: Int?
    let bestMoveUCI: String
    let bestMoveSAN: String
    let principalVariationSAN: [String]

    var displayScore: String {
        if let mate = mateIn {
            return "M\(abs(mate))"
        }
        if let cp = centipawns {
            let pawns = Double(cp) / 100.0
            return String(format: "%+.2f", pawns)
        }
        return "—"
    }
}

/// One move in a finished or in-progress game, with optional engine feedback attached.
struct GameMove: Identifiable {
    let id = UUID()
    let ply: Int
    let san: String
    let fenBefore: String
    let fenAfter: String
    var evaluation: EngineEvaluation?
    var classification: MoveClassification?
}

enum MoveClassification: String {
    case best = "Best"
    case good = "Good"
    case inaccuracy = "Inaccuracy"
    case mistake = "Mistake"
    case blunder = "Blunder"

    static func classify(centipawnsLoss: Int) -> MoveClassification {
        switch centipawnsLoss {
        case ..<10: return .best
        case 10..<40: return .good
        case 40..<100: return .inaccuracy
        case 100..<250: return .mistake
        default: return .blunder
        }
    }
}

/// A finished game pulled from Chess.com or Lichess.
struct ImportedGame: Identifiable {
    let id = UUID()
    let source: GameSource
    let opponent: String
    let result: String // "1-0", "0-1", "1/2-1/2"
    let playedAsWhite: Bool
    let pgn: String
    let date: Date
    var moves: [GameMove] = []
}

enum GameSource: String {
    case chessDotCom = "Chess.com"
    case lichess = "Lichess"
}

/// One line in an opening repertoire the user is drilling.
struct OpeningLine: Identifiable {
    let id = UUID()
    let name: String            // e.g. "Italian Game: Giuoco Piano"
    let movesSAN: [String]      // the book line, in order
    let asWhite: Bool
    var timesDrilled: Int = 0
    var timesMissed: Int = 0
}
