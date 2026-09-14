import SwiftUI

struct OpeningTrainerView: View {
    // Starter repertoire — replace with lines pulled from the Lichess
    // opening explorer API (https://explorer.lichess.ovh) once you wire
    // up networking. Hardcoded here so the drill UI works immediately.
    @State private var lines: [OpeningLine] = [
        OpeningLine(name: "Italian Game: Giuoco Piano", movesSAN: ["e4", "e5", "Nf3", "Nc6", "Bc4", "Bc5"], asWhite: true),
        OpeningLine(name: "Caro-Kann: Advance", movesSAN: ["e4", "c6", "d4", "d5", "e5", "Bf5"], asWhite: false),
    ]
    @State private var selected: OpeningLine?

    var body: some View {
        NavigationStack {
            List {
                ForEach(lines) { line in
                    Button { selected = line } label: {
                        OpeningRow(line: line)
                    }
                    .listRowBackground(Theme.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Openings")
            .sheet(item: $selected) { line in
                DrillView(line: line)
            }
        }
    }
}

struct OpeningRow: View {
    let line: OpeningLine
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(line.name).font(Theme.bodyFont.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(line.asWhite ? "White" : "Black")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(line.asWhite ? Color.white.opacity(0.15) : Color.black.opacity(0.3))
                    .clipShape(Capsule())
                    .foregroundStyle(Theme.textSecondary)
            }
            Text(line.movesSAN.joined(separator: " "))
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.vertical, 4)
    }
}

/// Steps through the line one move at a time; the user has to find the
/// book move before it's revealed. This is deliberately simple —
/// the drill logic (SAN matching, move counter) is the whole feature.
struct DrillView: View {
    let line: OpeningLine
    @State private var currentIndex = 0
    @State private var revealed = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Text(line.name).font(Theme.titleFont).foregroundStyle(Theme.textPrimary)

            Text("Move \(currentIndex + 1) of \(line.movesSAN.count)")
                .font(.caption).foregroundStyle(Theme.textSecondary)

            if revealed {
                Text(line.movesSAN[currentIndex])
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.accent)
            } else {
                Text("?").font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }

            Button(revealed ? "Next" : "Reveal") {
                if revealed {
                    if currentIndex < line.movesSAN.count - 1 {
                        currentIndex += 1
                        revealed = false
                    } else {
                        dismiss()
                    }
                } else {
                    revealed = true
                }
            }
            .font(Theme.bodyFont.weight(.semibold))
            .padding().frame(maxWidth: .infinity)
            .background(Theme.accent).foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner))
            .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
    }
}
