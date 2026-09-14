import SwiftUI

struct GameReviewView: View {
    @EnvironmentObject var engine: ChessEngine
    @State private var username: String = ""
    @State private var games: [ImportedGame] = []
    @State private var isImporting = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack {
                    TextField("Chess.com or Lichess username", text: $username)
                        .padding(12).background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Button {
                        Task { await importGames() }
                    } label: {
                        Image(systemName: "arrow.down.circle.fill").font(.title2)
                    }
                    .disabled(username.isEmpty || isImporting)
                }
                .padding(.horizontal)

                if games.isEmpty {
                    Spacer()
                    Text(isImporting ? "Importing…" : "Import your recent games to see where you're losing points.")
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                } else {
                    List(games) { game in
                        GameRow(game: game)
                            .listRowBackground(Theme.surface)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("My Games")
        }
    }

    private func importGames() async {
        isImporting = true
        defer { isImporting = false }
        let importer = GameImporter()
        // Try Lichess first, fall back to Chess.com — wire up a picker
        // once you know which platform you actually play on.
        if let fetched = try? await importer.fetchLichessGames(username: username) {
            games = fetched
        }
    }
}

struct GameRow: View {
    let game: ImportedGame
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("vs \(game.opponent)").font(Theme.bodyFont.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                Text(game.playedAsWhite ? "Playing White" : "Playing Black")
                    .font(.caption).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Text(game.result)
                .font(.system(.footnote, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.accent)
        }
        .padding(.vertical, 4)
    }
}
