import SwiftUI

struct CommunicationBoardView: View {
    @EnvironmentObject private var store: WishStore

    var body: some View {
        VStack(spacing: 14) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 14) {
                    boardToggle
                    Spacer(minLength: 0)
                    HStack(spacing: 8) { quickButtonContents }.fixedSize(horizontal: true, vertical: false)
                }
                VStack(alignment: .leading, spacing: 8) {
                    boardToggle
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], spacing: 8) { quickButtonContents }
                }
            }
            if store.boardExpanded {
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(spacing: 10) {
                        ForEach(CommunicationWord.Group.allCases) { group in
                            Button { store.boardGroup = group } label: {
                                Text(group.rawValue).font(.headline).padding(.horizontal, 18).padding(.vertical, 14)
                                    .foregroundStyle(store.boardGroup == group ? .white : WishTheme.ink)
                                    .background(store.boardGroup == group ? WishTheme.blue : WishTheme.sky, in: Capsule())
                            }.buttonStyle(.plain)
                                .accessibilityAddTraits(store.boardGroup == group ? [.isSelected] : [])
                        }
                    }.padding(.horizontal, 2)
                }.fixedSize(horizontal: false, vertical: true)
                phraseBar
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 125), spacing: 12)], spacing: 12) {
                        ForEach(CommunicationWord.all.filter { $0.group == store.boardGroup }) { word in
                            Button { store.addWord(word) } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: word.symbol).font(.title).accessibilityHidden(true)
                                    Text(word.label).font(.headline).multilineTextAlignment(.center)
                                }
                                .padding(14).frame(maxWidth: .infinity, minHeight: 94)
                                .foregroundStyle(WishTheme.ink)
                                .background(word.group == .feelings ? WishTheme.mint : WishTheme.sky, in: RoundedRectangle(cornerRadius: 18))
                            }.buttonStyle(.plain).accessibilityHint("Say \(word.speech) and add it to the sentence")
                        }
                    }.padding(.bottom, 10)
                }
            }
        }
        .padding(.horizontal, 22).padding(.top, 8).padding(.bottom, 10)
        .background(.white.shadow(.drop(color: WishTheme.ink.opacity(0.09), radius: 14, y: -4)))
        .foregroundStyle(WishTheme.blue)
    }

    private var boardToggle: some View {
        Button { store.boardExpanded.toggle() } label: {
            HStack(spacing: 10) {
                Image(systemName: "bubble.left.and.bubble.right.fill").accessibilityHidden(true)
                Text("Talking board").font(.headline)
                Image(systemName: store.boardExpanded ? "chevron.down" : "chevron.up").accessibilityHidden(true)
            }.padding(.vertical, 14).padding(.horizontal, 12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(store.boardExpanded ? "Close talking board" : "Open talking board")
        .accessibilityHint("Words and pictures you can use at any time")
    }

    @ViewBuilder private var quickButtonContents: some View {
        quickButton("No", symbol: "xmark.circle.fill", tint: WishTheme.peach) {
            store.quickMessage("No")
        }
        quickButton("Stop", symbol: "stop.circle.fill", tint: WishTheme.peach) {
            store.quickMessage("Stop")
        }
        quickButton("Think", symbol: "clock.fill", tint: WishTheme.sky) {
            store.quickMessage("I need time to think")
        }
        quickButton("Break", symbol: "pause.circle.fill", tint: WishTheme.lavender) {
            store.quickMessage("I need a break")
        }
        quickButton("Finished", symbol: "flag.checkered", tint: WishTheme.mint) {
            store.finishSession()
        }
    }

    private func quickButton(_ title: String, symbol: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol).font(.subheadline.weight(.bold))
                .padding(.horizontal, 14).padding(.vertical, 13).frame(minHeight: 48)
                .background(tint, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(WishTheme.ink)
        }.buttonStyle(.plain)
            .accessibilityLabel(title == "Break" ? "I need a break" : title == "Think" ? "I need time to think" : title)
    }

    private var phraseBar: some View {
        HStack(spacing: 12) {
            Text(store.phrase.isEmpty ? "Tap words to make a sentence" : store.phrase.joined(separator: " "))
                .font(.body.weight(.medium)).foregroundStyle(WishTheme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel("Sentence: \(store.phrase.joined(separator: " "))")
            Button { store.say(store.phrase.joined(separator: " "), explicit: true) } label: {
                Image(systemName: "speaker.wave.2.fill").font(.title2).padding(12)
            }.disabled(store.phrase.isEmpty).accessibilityLabel("Speak sentence")
            Button { if !store.phrase.isEmpty { store.phrase.removeLast() } } label: {
                Image(systemName: "delete.left").font(.title2).padding(12)
            }.disabled(store.phrase.isEmpty).accessibilityLabel("Remove last word")
            Button("Clear") { store.phrase = [] }.font(.headline).padding(12).disabled(store.phrase.isEmpty)
        }.padding(.horizontal, 14).padding(.vertical, 6)
            .background(WishTheme.background, in: RoundedRectangle(cornerRadius: 16))
    }
}
