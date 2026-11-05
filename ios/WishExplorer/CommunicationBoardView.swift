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
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 125), spacing: 12)], spacing: 12) {
                            ForEach(CommunicationWord.all) { word in
                                PictureTile(label: word.label, selected: false, compact: true) {
                                    store.addWord(word)
                                }
                                .accessibilityHint("Say \(word.speech) and add it to the sentence")
                            }
                        }.padding(.bottom, 14)
                    }
                }
                .padding(.horizontal, 22).padding(.top, 14).padding(.bottom, 10)
                .background(WishTheme.boardBackground)
            }
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
        Button { if !store.phrase.isEmpty { store.phrase.removeLast() } } label: {
            Image(systemName: "delete.left").font(.title2).padding(12)
        }.disabled(store.phrase.isEmpty).accessibilityLabel("Remove last word")
        Button("Clear") { store.phrase = [] }.font(.headline).padding(12).disabled(store.phrase.isEmpty)
    }
}
