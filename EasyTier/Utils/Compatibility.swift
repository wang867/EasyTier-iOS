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
        return self
#else
        return self
#endif
    }

    @ViewBuilder
    func adaptiveToolbarLabelStyle(padding: CGFloat) -> some View {
        self.labelStyle(.titleOnly).padding(padding)
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

    // task(id:) (iOS 15+) -> plain task (runs on appear)
    func compatTask<V: Equatable>(id: V, priority: TaskPriority? = nil, @ViewBuilder action: @escaping () async -> Void) -> some View {
        self.onAppear { Task(priority: priority) { await action() } }
    }

    // background(_:ignoresSafeAreaEdges:) (iOS 15+) -> plain background
    func compatBackgroundIgnoring<Content: View>(_ content: Content, edges: Edge.Set = .all) -> some View {
        self.background(content)
    }

    // lineLimit(_:reservesSpace:) (iOS 15+) -> lineLimit(_:)
    func compatLineLimit(_ limit: Int, reservesSpace: Bool = false) -> some View {
        self.lineLimit(limit)
    }

    // swipeActions (iOS 15+) -> no-op on iOS 14 (actions via other affordances)
    func compatSwipeActions<Content: View>(edge: Edge = .trailing, allowsFullSwipe: Bool = true, @ViewBuilder content: () -> Content) -> some View {
        self
    }
}

// Font.compatMonospaced() (iOS 15+) -> system design (iOS 13+)
extension Font {
    func compatMonospaced() -> Font {
        self
    }
    func compatMonospacedDigit() -> Font {
        self
    }
}

// Color.tertiary (iOS 15+) -> gray
extension Color {
    static var compatTertiary: Color { Color.gray.opacity(0.6) }
    static var compatSecondary: Color { Color.gray }
}

enum CompatVisibility { case automatic, visible, hidden }

// HorizontalEdge (iOS 15+) -> simple enum
enum CompatHorizontalEdge {
    case leading
    case trailing
}
typealias HorizontalEdge = CompatHorizontalEdge

// ViewThatFits (iOS 15+) -> simple fallback (first view)
struct CompatViewThatFits<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    // Accept and ignore the axis parameter used by the real ViewThatFits.
    init(in axis: Axis, @ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View { content }
}
typealias ViewThatFits = CompatViewThatFits

// NavigationLink(_:value:) (iOS 16+) -> plain label link without value-based navigation.
// On iOS 14 these secondary navigation entries fall back to a no-op link.
extension NavigationLink where Destination == EmptyView, Label == Text {
    init<V: Hashable>(_ titleKey: LocalizedStringKey, value: V) {
        self.init(destination: EmptyView()) { Text(titleKey) }
    }
    init<V: Hashable>(_ title: String, value: V) {
        self.init(destination: EmptyView()) { Text(title) }
    }
}

// iOS 15 alert(_:isPresented:actions:message:) -> sheet-based shim (iOS 14).
struct CompatAlertSheet<Actions: View, Message: View>: View {
    @Binding var isPresented: Bool
    let title: Text
    let actions: Actions
    let message: Message
    init(isPresented: Binding<Bool>, title: Text, @ViewBuilder actions: () -> Actions, @ViewBuilder message: () -> Message) {
        self._isPresented = isPresented
        self.title = title
        self.actions = actions()
        self.message = message()
    }
    var body: some View {
        VStack(spacing: 16) {
            title.font(.headline)
            message.font(.subheadline)
            actions
            Button("common.cancel") { isPresented = false }
        }
        .padding()
    }
}

extension View {
    // iOS 15 alert with actions/message builders -> iOS 14 sheet fallback.
    func compatAlert<Actions: View, Message: View>(
        _ titleKey: LocalizedStringKey,
        isPresented: Binding<Bool>,
        @ViewBuilder actions: @escaping () -> Actions,
        @ViewBuilder message: @escaping () -> Message
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            CompatAlertSheet(isPresented: isPresented, title: Text(titleKey), actions: actions, message: message)
        }
    }

    // alert without message
    func compatAlert<Actions: View>(
        _ titleKey: LocalizedStringKey,
        isPresented: Binding<Bool>,
        @ViewBuilder actions: @escaping () -> Actions
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            CompatAlertSheet(isPresented: isPresented, title: Text(titleKey), actions: actions, message: { EmptyView() })
        }
    }

    // iOS 15 confirmationDialog -> iOS 14 actionSheet fallback is not ViewBuilder-capable;
    // use a sheet with the actions instead.
    func compatConfirmationDialog<Actions: View, Message: View>(
        _ titleKey: LocalizedStringKey,
        isPresented: Binding<Bool>,
        titleVisibility: CompatVisibility = .automatic,
        @ViewBuilder actions: @escaping () -> Actions,
        @ViewBuilder message: @escaping () -> Message
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            CompatAlertSheet(isPresented: isPresented, title: Text(titleKey), actions: actions, message: message)
        }
    }
}


