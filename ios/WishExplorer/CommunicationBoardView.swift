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
        Button { snap(to: !store.boardExpanded) } label: {
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

private struct CommunicationDrawerHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = CommunicationDrawerGeometry.collapsedHeight

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
