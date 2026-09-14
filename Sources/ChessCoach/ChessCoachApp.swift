import SwiftUI

@main
struct ChessCoachApp: App {
    @StateObject private var engine = ChessEngine()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(engine)
                .preferredColorScheme(.dark) // the "pro" look starts here
        }
    }
}

struct RootTabView: View {
    var body: some View {
        TabView {
            StudyBoardView()
                .tabItem { Label("Study", systemImage: "magnifyingglass") }

            OpeningTrainerView()
                .tabItem { Label("Openings", systemImage: "books.vertical.fill") }

            GameReviewView()
                .tabItem { Label("My Games", systemImage: "chart.line.uptrend.xyaxis") }
        }
        .tint(Theme.accent)
    }
}

/// Centralized design tokens so every screen looks like one app, not three
/// prototypes stitched together. Change these once, the whole app updates.
enum Theme {
    static let accent = Color(red: 0.20, green: 0.78, blue: 0.55)   // emerald — reads "engine/precision"
    static let background = Color(red: 0.07, green: 0.08, blue: 0.10)
    static let surface = Color(red: 0.12, green: 0.13, blue: 0.16)
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.65)

    static let bestMove = Color(red: 0.20, green: 0.78, blue: 0.55)
    static let mistakeColor = Color(red: 0.95, green: 0.65, blue: 0.15)
    static let blunderColor = Color(red: 0.90, green: 0.30, blue: 0.30)

    static let cardCorner: CGFloat = 16
    static let titleFont = Font.system(.title2, design: .rounded, weight: .bold)
    static let bodyFont = Font.system(.body, design: .rounded)
}
