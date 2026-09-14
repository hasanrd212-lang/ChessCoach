import Foundation

enum PieceColor { case white, black }

enum PieceKind: String {
    case pawn = "p", knight = "n", bishop = "b", rook = "r", queen = "q", king = "k"

    var glyph: [PieceColor: String] {
        switch self {
        case .pawn:   return [.white: "♙", .black: "♟"]
        case .knight: return [.white: "♘", .black: "♞"]
        case .bishop: return [.white: "♗", .black: "♝"]
        case .rook:   return [.white: "♖", .black: "♜"]
        case .queen:  return [.white: "♕", .black: "♛"]
        case .king:   return [.white: "♔", .black: "♚"]
        }
    }
}

struct Piece {
    let kind: PieceKind
    let color: PieceColor
}

struct Square: Hashable {
    let file: Int // 0...7, a...h
    let rank: Int // 0...7, rank 0 = rank "1" (White's back rank)

    var algebraic: String {
        let f = Character(UnicodeScalar(97 + file)!)
        return "\(f)\(rank + 1)"
    }
}

/// A minimal board model: enough to display a position, let the user tap
/// out a move, and hand the resulting FEN to the engine or an importer.
///
/// KNOWN LIMITATION: move generation here is *pseudo-legal* — it checks
/// how each piece type moves and whether the path/target is valid, but it
/// does not detect check, pins, castling, or en passant. That's the next
/// layer to add once the basic board feels good; until then, treat this as
/// a board for stepping through known-good games and testing positions,
/// not as a fully rules-enforcing opponent.
final class ChessBoard: ObservableObject {
    @Published var squares: [Square: Piece] = [:]
    @Published var sideToMove: PieceColor = .white
    @Published var selected: Square?
    @Published var legalTargets: Set<Square> = []

    init(fen: String = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1") {
        load(fen: fen)
    }

    func load(fen: String) {
        squares = [:]
        let parts = fen.split(separator: " ")
        guard let placement = parts.first else { return }
        let ranks = placement.split(separator: "/")

        for (i, rankStr) in ranks.enumerated() {
            let rank = 7 - i // FEN starts at rank 8
            var file = 0
            for ch in rankStr {
                if let empty = ch.wholeNumberValue {
                    file += empty
                } else {
                    let color: PieceColor = ch.isUppercase ? .white : .black
                    if let kind = PieceKind(rawValue: String(ch).lowercased()) {
                        squares[Square(file: file, rank: rank)] = Piece(kind: kind, color: color)
                    }
                    file += 1
                }
            }
        }

        if parts.count > 1 {
            sideToMove = parts[1] == "w" ? .white : .black
        }
    }

    func exportFEN() -> String {
        var rows: [String] = []
        for rank in stride(from: 7, through: 0, by: -1) {
            var row = ""
            var emptyRun = 0
            for file in 0...7 {
                if let piece = squares[Square(file: file, rank: rank)] {
                    if emptyRun > 0 { row += "\(emptyRun)"; emptyRun = 0 }
                    let letter = piece.kind.rawValue
                    row += piece.color == .white ? letter.uppercased() : letter
                } else {
                    emptyRun += 1
                }
            }
            if emptyRun > 0 { row += "\(emptyRun)" }
            rows.append(row)
        }
        let placement = rows.joined(separator: "/")
        return "\(placement) \(sideToMove == .white ? "w" : "b") - - 0 1"
    }

    // MARK: - Interaction

    func tap(_ square: Square) {
        if let from = selected {
            if legalTargets.contains(square) {
                move(from: from, to: square)
            }
            selected = nil
            legalTargets = []
        } else if let piece = squares[square], piece.color == sideToMove {
            selected = square
            legalTargets = Set(pseudoLegalTargets(from: square))
        }
    }

    private func move(from: Square, to: Square) {
        guard let piece = squares[from] else { return }
        squares[to] = piece
        squares[from] = nil
        sideToMove = sideToMove == .white ? .black : .white
    }

    // MARK: - Pseudo-legal move generation

    private func pseudoLegalTargets(from: Square) -> [Square] {
        guard let piece = squares[from] else { return [] }
        switch piece.kind {
        case .pawn: return pawnTargets(from: from, color: piece.color)
        case .knight: return knightTargets(from: from, color: piece.color)
        case .bishop: return slidingTargets(from: from, color: piece.color, directions: diagonals)
        case .rook: return slidingTargets(from: from, color: piece.color, directions: orthogonals)
        case .queen: return slidingTargets(from: from, color: piece.color, directions: diagonals + orthogonals)
        case .king: return kingTargets(from: from, color: piece.color)
        }
    }

    private let diagonals = [(1, 1), (1, -1), (-1, 1), (-1, -1)]
    private let orthogonals = [(1, 0), (-1, 0), (0, 1), (0, -1)]

    private func inBounds(_ f: Int, _ r: Int) -> Bool { (0...7).contains(f) && (0...7).contains(r) }

    private func pawnTargets(from: Square, color: PieceColor) -> [Square] {
        var targets: [Square] = []
        let dir = color == .white ? 1 : -1
        let startRank = color == .white ? 1 : 6
        let one = Square(file: from.file, rank: from.rank + dir)
        if inBounds(one.file, one.rank), squares[one] == nil {
            targets.append(one)
            let two = Square(file: from.file, rank: from.rank + 2 * dir)
            if from.rank == startRank, squares[two] == nil { targets.append(two) }
        }
        for df in [-1, 1] {
            let capture = Square(file: from.file + df, rank: from.rank + dir)
            if inBounds(capture.file, capture.rank), let target = squares[capture], target.color != color {
                targets.append(capture)
            }
        }
        return targets
    }

    private func knightTargets(from: Square, color: PieceColor) -> [Square] {
        let offsets = [(1,2),(2,1),(2,-1),(1,-2),(-1,-2),(-2,-1),(-2,1),(-1,2)]
        return offsets.compactMap { (df, dr) in
            let sq = Square(file: from.file + df, rank: from.rank + dr)
            guard inBounds(sq.file, sq.rank) else { return nil }
            if let occ = squares[sq], occ.color == color { return nil }
            return sq
        }
    }

    private func kingTargets(from: Square, color: PieceColor) -> [Square] {
        (diagonals + orthogonals).compactMap { (df, dr) in
            let sq = Square(file: from.file + df, rank: from.rank + dr)
            guard inBounds(sq.file, sq.rank) else { return nil }
            if let occ = squares[sq], occ.color == color { return nil }
            return sq
        }
    }

    private func slidingTargets(from: Square, color: PieceColor, directions: [(Int, Int)]) -> [Square] {
        var targets: [Square] = []
        for (df, dr) in directions {
            var f = from.file + df, r = from.rank + dr
            while inBounds(f, r) {
                let sq = Square(file: f, rank: r)
                if let occ = squares[sq] {
                    if occ.color != color { targets.append(sq) }
                    break
                }
                targets.append(sq)
                f += df; r += dr
            }
        }
        return targets
    }
}
