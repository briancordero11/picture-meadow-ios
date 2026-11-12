import SwiftUI

struct CommunicationBoardView: View {
    @EnvironmentObject private var store: WishStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @GestureState private var isDragging = false
    @State private var drawerHeight = CommunicationDrawerGeometry.collapsedHeight
    @State private var presentedHeight = CommunicationDrawerGeometry.collapsedHeight
    @State private var dragStartHeight: CGFloat?
    @State private var ignoreCurrentDrag = false

    var expandedHeight: CGFloat = 600

    private var fullHeight: CGFloat {
        max(CommunicationDrawerGeometry.collapsedHeight, expandedHeight)
    }

    private var visibleHeight: CGFloat {
        CommunicationDrawerGeometry.clampedHeight(drawerHeight, expandedHeight: fullHeight)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                drawerTab
                Spacer(minLength: 0)
            }
            .frame(height: CommunicationDrawerGeometry.collapsedHeight)
            VStack(spacing: 12) {
                phraseBar
                ScrollView {
                    VStack(spacing: 0) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 44), spacing: 1), count: 5), spacing: 1) {
                            ForEach(CommunicationWord.mainRows.flatMap { $0 }) { word in
                                wordTile(word)
                            }
                        }
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 44), spacing: 1), count: 4), spacing: 1) {
                            ForEach(CommunicationWord.phraseWords) { word in
                                wordTile(word)
                            }
                        }
                    }.padding(.bottom, 10)
                }
            }
            .padding(.horizontal, 12).padding(.top, 12).padding(.bottom, 15)
            .frame(height: fullHeight - CommunicationDrawerGeometry.collapsedHeight)
            .background(WishTheme.boardBackground)
            .allowsHitTesting(store.boardExpanded && !isDragging)
            .accessibilityHidden(!store.boardExpanded)
        }
        .frame(maxWidth: .infinity)
        .frame(height: visibleHeight, alignment: .top)
        .clipped()
        .background {
            GeometryReader { geometry in
                Color.clear.preference(key: CommunicationDrawerHeightKey.self, value: geometry.size.height)
            }
        }
        .onPreferenceChange(CommunicationDrawerHeightKey.self) { presentedHeight = $0 }
        .onAppear { resizeWithoutAnimation() }
        .onChange(of: fullHeight) { _, _ in
            ignoreCurrentDrag = isDragging
            resizeWithoutAnimation()
        }
        .onChange(of: store.boardExpanded) { _, expanded in
            let target = expanded ? fullHeight : CommunicationDrawerGeometry.collapsedHeight
            if drawerHeight != target { snap(to: expanded) }
        }
        .onChange(of: isDragging) { _, dragging in
            if !dragging {
                // A canceled gesture returns to the last committed open/closed state.
                if dragStartHeight != nil { snap(to: store.boardExpanded) }
                ignoreCurrentDrag = false
            }
        }
    }

    private var drawerDrag: some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .global)
            .updating($isDragging) { _, dragging, transaction in
                dragging = true
                transaction.disablesAnimations = true
            }
            .onChanged { value in
                guard !ignoreCurrentDrag else { return }
                if dragStartHeight == nil {
                    // Read the presented height so a new drag can interrupt a snap.
                    dragStartHeight = presentedHeight
                }
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    drawerHeight = CommunicationDrawerGeometry.height(
                        startHeight: dragStartHeight ?? visibleHeight,
                        translation: value.translation.height,
                        expandedHeight: fullHeight
                    )
                }
            }
            .onEnded { value in
                guard !ignoreCurrentDrag else { return }
                let expanded = CommunicationDrawerGeometry.shouldExpand(
                    startHeight: dragStartHeight ?? visibleHeight,
                    predictedEndTranslation: value.predictedEndTranslation.height,
                    expandedHeight: fullHeight
                )
                snap(to: expanded)
            }
    }

    private func snap(to expanded: Bool) {
        dragStartHeight = nil
        withAnimation(reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.86)) {
            store.boardExpanded = expanded
            drawerHeight = expanded ? fullHeight : CommunicationDrawerGeometry.collapsedHeight
        }
    }

    private func resizeWithoutAnimation() {
        dragStartHeight = nil
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            drawerHeight = store.boardExpanded ? fullHeight : CommunicationDrawerGeometry.collapsedHeight
        }
    }

    private func wordTile(_ word: CommunicationWord) -> some View {
        PictureTile(label: word.label, selected: false, compact: true, backgroundColor: tileColor(word)) {
            store.addWord(word)
        }
        .accessibilityHint("Say \(word.speech) and add it to the sentence")
    }

    private func tileColor(_ word: CommunicationWord) -> Color {
        if word.label == "No / don't" { return Color(red: 245.0 / 255, green: 170.0 / 255, blue: 162.0 / 255) }
        if CommunicationWord.phraseWords.contains(where: { $0.id == word.id }) {
            return Color(red: 243.0 / 255, green: 191.0 / 255, blue: 209.0 / 255)
        }
        if ["Yes", "Finished"].contains(word.label) { return Color(red: 185.0 / 255, green: 223.0 / 255, blue: 141.0 / 255) }
        switch word.group {
        case .people: return Color(red: 1, green: 227.0 / 255, blue: 139.0 / 255)
        case .actions: return Color(red: 185.0 / 255, green: 223.0 / 255, blue: 141.0 / 255)
        case .questions: return WishTheme.lavender
        case .feelings:
            if word.label == "Help" { return Color(red: 185.0 / 255, green: 223.0 / 255, blue: 141.0 / 255) }
            return WishTheme.sky
        }
    }

    /// A single visible handle is kept on screen while every word tile is tucked away.
    private var drawerTab: some View {
        Button { snap(to: !store.boardExpanded) } label: {
            VStack(spacing: 1) {
                Capsule().fill(Color(red: 154.0 / 255, green: 121.0 / 255, blue: 85.0 / 255)).frame(width: 30, height: 4)
                WishUIIcon(name: store.boardExpanded ? "chevron-down" : "chevron-up", size: 22)
            }
            .frame(width: 90, height: 44)
            .background(Color(red: 1, green: 232.0 / 255, blue: 199.0 / 255), in: UnevenRoundedRectangle(topLeadingRadius: 18, topTrailingRadius: 18))
            .overlay(UnevenRoundedRectangle(topLeadingRadius: 18, topTrailingRadius: 18).stroke(WishTheme.line, lineWidth: 1.5))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(store.boardExpanded ? "Close talking board" : "Open talking board")
        .accessibilityHint("Tap to toggle, or drag up to open and down to close")
        .accessibilityValue(store.boardExpanded ? "Open" : "Closed")
        .highPriorityGesture(drawerDrag)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: snap(to: true)
            case .decrement: snap(to: false)
            @unknown default: break
            }
        }
        .accessibilityAction(named: Text(store.boardExpanded ? "Close board" : "Open board")) {
            snap(to: !store.boardExpanded)
        }
    }

    private var phraseBar: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) { phraseText; HStack(spacing: 4) { phraseActions } }
            VStack(alignment: .leading, spacing: 10) { phraseText; HStack { Spacer(); HStack(spacing: 4) { phraseActions } } }
        }
        .padding(.horizontal, 9).padding(.vertical, 7)
        .frame(minHeight: 58)
        .background(Color(red: 1, green: 253.0 / 255, blue: 247.0 / 255), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(red: 186.0 / 255, green: 168.0 / 255, blue: 142.0 / 255), lineWidth: 1))
        .buttonStyle(BoardPhraseButtonStyle())
    }

    private var phraseText: some View {
        Text(store.phrase.isEmpty ? "My words…" : store.phrase.joined(separator: " "))
            .font(WishTheme.cardFont(size: 16)).foregroundStyle(WishTheme.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel("Sentence: \(store.phrase.joined(separator: " "))")
    }

    @ViewBuilder private var phraseActions: some View {
        Button { store.say(store.phrase.joined(separator: " "), explicit: true) } label: {
            WishUIIcon(name: "volume-2")
        }.disabled(store.phrase.isEmpty).accessibilityLabel("Speak sentence")
        Button { store.stopSpeaking() } label: {
            WishUIIcon(name: "volume-off")
        }.accessibilityLabel("Stop speaking")
        Button { if !store.phrase.isEmpty { store.phrase.removeLast() } } label: {
            WishUIIcon(name: "delete")
        }.disabled(store.phrase.isEmpty).accessibilityLabel("Remove last word")
        Button("Clear") { store.phrase = [] }.font(WishTheme.cardFont(size: 13)).disabled(store.phrase.isEmpty)
    }
}

private struct BoardPhraseButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(WishTheme.line)
            .padding(8)
            .frame(minWidth: 44, minHeight: 44)
            .background(Color(red: 1, green: 240.0 / 255, blue: 210.0 / 255), in: RoundedRectangle(cornerRadius: 13))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

private struct CommunicationDrawerHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = CommunicationDrawerGeometry.collapsedHeight

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
