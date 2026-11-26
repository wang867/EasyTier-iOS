import SwiftUI

#if os(iOS)
    let ToolbarLeading = ToolbarItemPlacement.topBarLeading
    let ToolbarTrailing = ToolbarItemPlacement.topBarTrailing
#else
    let ToolbarLeading = ToolbarItemPlacement.navigation
    let ToolbarTrailing = ToolbarItemPlacement.primaryAction
#endif

extension View {
    func decimalKeyboardType() -> some View {
#if os(iOS)
        return self.keyboardType(.decimalPad)
#else
        return self
#endif
    }
    
    func numberKeyboardType() -> some View {
#if os(iOS)
        return self.keyboardType(.numberPad)
#else
        return self
#endif
    }
    
    func adaptiveNavigationBarTitleInline() -> some View {
#if os(iOS)
        return self.navigationBarTitleDisplayMode(.inline)
#else
        return self
#endif
    }
    
    func adaptiveNoTextInputAutocapitalization() -> some View {
#if os(iOS)
        return self.textInputAutocapitalization(.never)
#else
        return self
#endif
    }

    @ViewBuilder
    func adaptiveToolbarLabelStyle(padding: CGFloat) -> some View {
        self.labelStyle(.titleAndIcon).padding(padding)
    }
}

extension ToolbarContent {
    /// Prefers placing the item in the vertical bar (e.g. on iPhone Duo) when one is present.
    /// iOS 14 build: no vertical bar support, return unchanged.
    @ToolbarContentBuilder
    func adaptiveVerticalPreferred() -> some ToolbarContent {
        self
    }
}

// MARK: - iOS 14 compatibility shims
// These wrappers shadow iOS 15/16 SwiftUI APIs so the rest of the codebase can
// stay unchanged while the deployment target is lowered to iOS 14.

// NavigationStack (iOS 16+) -> NavigationView (iOS 13+)
typealias NavigationStack = NavigationView

// LabeledContent (iOS 16+) -> simple HStack based replacement
struct CompatLabeledContent<LabelContent: View, ValueContent: View>: View {
    let label: LabelContent
    let value: ValueContent

    init(@ViewBuilder content: () -> ValueContent, @ViewBuilder label: () -> LabelContent) {
        self.label = label()
        self.value = content()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            label
            Spacer(minLength: 8)
            value
        }
    }
}

extension CompatLabeledContent where LabelContent == Text {
    init(_ key: LocalizedStringKey, @ViewBuilder content: () -> ValueContent) {
        self.init(content: content, label: { Text(key) })
    }

    init(_ key: String, @ViewBuilder content: () -> ValueContent) {
        self.init(content: content, label: { Text(key) })
    }
}

extension CompatLabeledContent where LabelContent == Text, ValueContent == Text {
    init(_ key: LocalizedStringKey, value: String) {
        self.init(content: { Text(value) }, label: { Text(key) })
    }

    init(_ key: String, value: String) {
        self.init(content: { Text(value) }, label: { Text(key) })
    }
}

typealias LabeledContent = CompatLabeledContent

extension View {
    // foregroundStyle (iOS 15+) -> foregroundColor (iOS 13+)
    func compatFG(_ color: Color) -> some View {
        foregroundColor(color)
    }

    func compatFG(_ first: Color, _ second: Color) -> some View {
        foregroundColor(first)
    }

    // safeAreaInset with HorizontalEdge (iOS 15+) -> no-op on iOS 14
    func compatSafeAreaInset<Content: View>(
        edge: HorizontalEdge,
        spacing: CGFloat = 0,
        @ViewBuilder content: () -> Content
    ) -> some View {
        self
    }

    // closure-based background (iOS 15+) -> iOS 13 background(_:)
    @ViewBuilder
    func compatBackground<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        background(content())
    }

    // animation(_:value:) (iOS 15+) -> animation(_:)
    func compatAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        self.animation(animation)
    }
}

