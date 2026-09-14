import Foundation

/// Pulls finished games from the public Chess.com and Lichess APIs.
/// Neither requires an API key for reading public game history.
struct GameImporter {

    /// Chess.com: https://api.chess.com/pub/player/{username}/games/{YYYY}/{MM}
    func fetchChessDotComGames(username: String, year: Int, month: Int) async throws -> [ImportedGame] {
        let monthStr = String(format: "%02d", month)
        let url = URL(string: "https://api.chess.com/pub/player/\(username.lowercased())/games/\(year)/\(monthStr)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(ChessDotComResponse.self, from: data)

        return decoded.games.map { g in
            let playedAsWhite = g.white.username.lowercased() == username.lowercased()
            let opponent = playedAsWhite ? g.black.username : g.white.username
            return ImportedGame(
                source: .chessDotCom,
                opponent: opponent,
                result: g.result,
                playedAsWhite: playedAsWhite,
                pgn: g.pgn,
                date: Date(timeIntervalSince1970: TimeInterval(g.endTime))
            )
        }
    }

    /// Lichess: https://lichess.org/api/games/user/{username}
    func fetchLichessGames(username: String, max: Int = 20) async throws -> [ImportedGame] {
        var request = URLRequest(url: URL(string: "https://lichess.org/api/games/user/\(username)?max=\(max)&pgnInJson=false")!)
        request.setValue("application/x-ndjson", forHTTPHeaderField: "Accept")
        let (data, _) = try await URLSession.shared.data(for: request)

        // Lichess returns newline-delimited PGN blocks when pgnInJson=false.
        let pgnBlocks = String(data: data, encoding: .utf8)?
            .components(separatedBy: "\n\n\n")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? []

        return pgnBlocks.map { pgn in
            ImportedGame(
                source: .lichess,
                opponent: extractTag("Black", from: pgn) ?? "Unknown",
                result: extractTag("Result", from: pgn) ?? "*",
                playedAsWhite: extractTag("White", from: pgn)?.lowercased() == username.lowercased(),
                pgn: pgn,
                date: Date()
            )
        }
    }

    private func extractTag(_ tag: String, from pgn: String) -> String? {
        guard let range = pgn.range(of: "[\(tag) \"") else { return nil }
        let afterTag = pgn[range.upperBound...]
        guard let end = afterTag.firstIndex(of: "\"") else { return nil }
        return String(afterTag[..<end])
    }
}

// MARK: - Chess.com response models

private struct ChessDotComResponse: Decodable {
    let games: [ChessDotComGame]
}

private struct ChessDotComGame: Decodable {
    let white: Player
    let black: Player
    let pgn: String
    let result: String
    let endTime: Int

    enum CodingKeys: String, CodingKey {
        case white, black, pgn
        case result = "result"
        case endTime = "end_time"
    }

    struct Player: Decodable {
        let username: String
    }
}
