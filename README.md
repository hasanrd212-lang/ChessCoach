# ChessCoach — setup, step by step

You already have a Mac-free build pipeline from SudokuPro (GitHub Actions →
IPA → sideload). Reuse it here — the steps below just get the source into a
buildable shape.

## 1. Create the Xcode project
- New project → iOS → App → SwiftUI, name it `ChessCoach`, min target iOS 16.
- Delete the auto-generated `ContentView.swift` and `ChessCoachApp.swift`.
- Drag in every `.swift` file from `Sources/ChessCoach/` in this folder.

## 2. Add the Stockfish engine via Swift Package Manager
File → Add Package Dependencies… → paste:
https://github.com/varton86/StockfishKit
Pick "main" or latest tagged version, add it to the ChessCoach target.
(If that package ever gets pulled or renamed, `goncharik/stockfishengine-ios`
is a second working option — same idea, swap the import in `ChessEngine.swift`.)

## 3. Build and run once, empty
Confirm it compiles with just the engine wired up before adding features —
this is the step most likely to need small API tweaks depending on which
StockfishKit version you land on (method names drift between versions).

## 4. Wire in the app icon
- Take `AppIcon-1024.svg` (in this folder), export it as a 1024×1024 PNG
  (Figma, or any SVG-to-PNG tool).
- Drop the PNG into **appicon.co** — it generates every required iOS icon
  size as a ready-to-drag `.appiconset` folder.
- Drag that folder into `Assets.xcassets` in Xcode, replacing the default
  AppIcon set.

## 5. Test each screen
- **Study tab** — paste a FEN, tap "Find best move," confirm you get an
  evaluation back. This proves the engine loop works end to end.
- **Openings tab** — tap a line, drill through it. Static data for now;
  swap in real lines from `https://explorer.lichess.ovh` later.
- **My Games tab** — enter a real Lichess username, import games. Chess.com
  import is written in `GameImporter.swift` too, just not wired to a button
  yet — add one when you're ready.

## 6. Ship it through your existing pipeline
Same GitHub Actions → IPA → sideload flow as SudokuPro. No changes needed
there — this is just another SwiftUI app to it.

---

### What's stubbed vs. real
- **Real**: engine wrapper, move classification logic, Chess.com/Lichess
  importers, full navigation and design system (`Theme` in
  `ChessCoachApp.swift` — change the accent color there and the whole app
  reskins).
- **Stubbed, on purpose**: check/castling/en passant aren't enforced yet in
  the board — worth adding once the rest feels solid.
