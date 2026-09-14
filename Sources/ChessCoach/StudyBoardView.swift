import SwiftUI

struct StudyBoardView: View {
    @EnvironmentObject var engine: ChessEngine
    @StateObject private var board = ChessBoard()
    @State private var fen: String = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ChessBoardView(board: board)
                        .padding(.horizontal)
                        .onReceive(board.objectWillChange) { _ in
                            // Keep the FEN field in sync whenever a move is made on the board.
                            fen = board.exportFEN()
                        }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Position (FEN)").font(.caption).foregroundStyle(Theme.textSecondary)
                        HStack {
                            TextField("Paste FEN", text: $fen)
                                .font(.system(.footnote, design: .monospaced))
                                .padding(12)
                                .background(Theme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            Button("Load") { board.load(fen: fen) }
                                .font(.caption.weight(.semibold))
                        }
                    }
                    .padding(.horizontal)

                    Button {
                        Task { await engine.evaluate(fen: fen) }
                    } label: {
                        Label(engine.isThinking ? "Thinking…" : "Find best move",
                              systemImage: "bolt.fill")
                            .font(Theme.bodyFont.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.accent)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner))
                    }
                    .disabled(engine.isThinking)
                    .padding(.horizontal)

                    if let eval = engine.lastEvaluation {
                        EvaluationCard(eval: eval)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Study Board")
        }
    }
}

struct EvaluationCard: View {
    let eval: EngineEvaluation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Best move")
                    .font(.caption).foregroundStyle(Theme.textSecondary)
                Spacer()
                Text(eval.displayScore)
                    .font(.system(.subheadline, design: .monospaced, weight: .bold))
                    .foregroundStyle(Theme.accent)
            }
            Text(eval.bestMoveSAN)
                .font(Theme.titleFont)
                .foregroundStyle(Theme.textPrimary)

            if !eval.principalVariationSAN.isEmpty {
                Text(eval.principalVariationSAN.joined(separator: "  "))
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner))
    }
}
