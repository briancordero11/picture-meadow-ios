import SwiftUI

struct CommunicationBoardView: View {
    @EnvironmentObject private var store: WishStore

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                drawerTab
                Spacer(minLength: 0)
            }
            if store.boardExpanded {
                VStack(spacing: 14) {
                    phraseBar
                    ScrollView {
                        VStack(spacing: 0) {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 44), spacing: 0), count: 5), spacing: 0) {
                                ForEach(CommunicationWord.mainRows.flatMap { $0 }) { word in
                                    wordTile(word)
                                }
                            }
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 44), spacing: 0), count: 4), spacing: 0) {
                                ForEach(CommunicationWord.phraseWords) { word in
                                    wordTile(word)
                                }
                            }
                        }.padding(.bottom, 10)
                    }
                }
                .padding(.horizontal, 22).padding(.top, 14).padding(.bottom, 10)
                .background(WishTheme.boardBackground)
            }
        }
    }

    private func wordTile(_ word: CommunicationWord) -> some View {
        PictureTile(label: word.label, selected: false, compact: true, backgroundColor: tileColor(word)) {
            store.addWord(word)
        }
        .accessibilityHint("Say \(word.speech) and add it to the sentence")
    }

    private func tileColor(_ word: CommunicationWord) -> Color {
        if word.label == "No / don't" { return Color(red: 0.98, green: 0.79, blue: 0.79) }
        if CommunicationWord.phraseWords.contains(where: { $0.id == word.id }) {
            return Color(red: 0.96, green: 0.82, blue: 0.89)
        }
        if ["Yes", "Finished"].contains(word.label) { return Color(red: 0.80, green: 0.93, blue: 0.81) }
        switch word.group {
        case .people: return Color(red: 1, green: 0.94, blue: 0.68)
        case .actions: return Color(red: 0.80, green: 0.93, blue: 0.81)
        case .questions: return Color(red: 0.89, green: 0.83, blue: 0.95)
        case .feelings:
            if word.label == "Help" { return Color(red: 0.80, green: 0.93, blue: 0.81) }
            return Color(red: 0.83, green: 0.92, blue: 0.98)
        }
    }

    /// A single visible handle is kept on screen while every word tile is tucked away.
    private var drawerTab: some View {
        Button { store.boardExpanded.toggle() } label: {
            VStack(spacing: 7) {
                Capsule().fill(WishTheme.ink.opacity(0.35)).frame(width: 38, height: 4)
                Image(systemName: store.boardExpanded ? "chevron.down" : "chevron.up")
                    .font(.system(size: 13, weight: .bold)).foregroundStyle(WishTheme.ink)
            }
            .frame(width: 96, height: 32)
            .background(WishTheme.boardBackground, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(WishTheme.ink.opacity(0.18), lineWidth: 1))
            .frame(width: 120, height: 48, alignment: .bottom)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(store.boardExpanded ? "Close talking board" : "Open talking board")
        .accessibilityHint("Tap to toggle, or drag up to open and down to close")
        .accessibilityValue(store.boardExpanded ? "Open" : "Closed")
        .simultaneousGesture(DragGesture(minimumDistance: 12).onEnded { value in
            if value.translation.height < -20 { store.boardExpanded = true }
            else if value.translation.height > 20 { store.boardExpanded = false }
        })
        .accessibilityAction(named: Text(store.boardExpanded ? "Close board" : "Open board")) {
            store.boardExpanded.toggle()
        }
    }

    private var phraseBar: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { phraseText; phraseActions }
            VStack(alignment: .leading, spacing: 10) { phraseText; HStack { Spacer(); phraseActions } }
        }
        .padding(.horizontal, 14).padding(.vertical, 6)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
    }

    private var phraseText: some View {
        Text(store.phrase.isEmpty ? "Tap pictures to say something" : store.phrase.joined(separator: " "))
            .font(.body.weight(.medium)).foregroundStyle(.black)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel("Sentence: \(store.phrase.joined(separator: " "))")
    }

    @ViewBuilder private var phraseActions: some View {
        Button { store.say(store.phrase.joined(separator: " "), explicit: true) } label: {
            Image(systemName: "speaker.wave.2.fill").font(.title2).padding(12)
        }.disabled(store.phrase.isEmpty).accessibilityLabel("Speak sentence")
        Button { store.stopSpeaking() } label: {
            Image(systemName: "speaker.slash.fill").font(.title2).padding(12)
                .frame(minWidth: 44, minHeight: 44)
        }.accessibilityLabel("Stop speaking")
        Button { if !store.phrase.isEmpty { store.phrase.removeLast() } } label: {
            Image(systemName: "delete.left").font(.title2).padding(12)
        }.disabled(store.phrase.isEmpty).accessibilityLabel("Remove last word")
        Button("Clear") { store.phrase = [] }.font(.headline).padding(12).disabled(store.phrase.isEmpty)
    }
}
