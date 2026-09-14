import SwiftUI

struct ChessBoardView: View {
    @ObservedObject var board: ChessBoard

    private let lightSquare = Color(red: 0.93, green: 0.93, blue: 0.90)
    private let darkSquare = Color(red: 0.22, green: 0.27, blue: 0.24)

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let cell = size / 8

            ZStack {
                VStack(spacing: 0) {
                    ForEach((0...7).reversed(), id: \.self) { rank in
                        HStack(spacing: 0) {
                            ForEach(0...7, id: \.self) { file in
                                squareView(file: file, rank: rank, cell: cell)
                            }
                        }
                    }
                }
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.surface, lineWidth: 2))
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private func squareView(file: Int, rank: Int, cell: CGFloat) -> some View {
        let square = Square(file: file, rank: rank)
        let isLight = (file + rank) % 2 == 1
        let isSelected = board.selected == square
        let isTarget = board.legalTargets.contains(square)

        ZStack {
            (isLight ? lightSquare : darkSquare)
            if isSelected {
                Theme.accent.opacity(0.45)
            }
            if isTarget {
                Circle()
                    .fill(Theme.accent.opacity(0.55))
                    .frame(width: cell * 0.3, height: cell * 0.3)
            }
            if let piece = board.squares[square] {
                Text(piece.kind.glyph[piece.color] ?? "")
                    .font(.system(size: cell * 0.72))
                    .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
            }
        }
        .frame(width: cell, height: cell)
        .contentShape(Rectangle())
        .onTapGesture { board.tap(square) }
    }
}

#Preview {
    ChessBoardView(board: ChessBoard())
        .padding()
        .background(Theme.background)
}
