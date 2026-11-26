import SwiftUI

struct AdaptiveNavigation<PrimaryView, SecondaryView, Enum>: View where PrimaryView: View, SecondaryView: View, Enum: Identifiable & Hashable {
#if os(macOS)
    let sizeClass = UserInterfaceSizeClass.compact
#else
    @Environment(\.horizontalSizeClass) var sizeClass
#endif
    @ViewBuilder var primaryColumn: PrimaryView
    @ViewBuilder var secondaryColumn: SecondaryView
    @Binding var showNav: Enum?
    
    init(_ primary: PrimaryView, _ secondary: SecondaryView, showNav: Binding<Enum?>) {
        primaryColumn = primary
        secondaryColumn = secondary
        _showNav = showNav
    }
    
    var body: some View {
        Group {
            if sizeClass == .regular {
                HStack(spacing: 0) {
                    primaryColumn
                        .columnGutter(.trailing)
                        .frame(maxWidth: columnMaxWidth)
                    secondaryColumn
                        .columnGutter(.leading)
                }
            } else {
                primaryColumn
            }
        }
        .adaptiveNavigationDestination(item: (sizeClass == .compact ? $showNav : .constant(nil)), destination: { secondaryColumn })
    }
}

extension View {
    func columnGutter(_ edge: HorizontalEdge, minimum: CGFloat = 10) -> some View {
        modifier(ColumnGutter(edge: edge, minimum: minimum))
    }

    func adaptiveNavigationDestination<Enum: Identifiable & Hashable, Destination: View>(
        item: Binding<Enum?>,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        // iOS 14 has no navigationDestination; present the detail view as a sheet.
        // The binding is cleared on dismissal, matching the original behaviour.
        return self.sheet(item: item) { _ in
            NavigationView {
                destination()
            }
        }
    }
}

private struct ColumnGutter: ViewModifier {
    let edge: HorizontalEdge
    let minimum: CGFloat
    @State private var extra: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .compatSafeAreaInset(edge: edge, spacing: 0) {
                Color.clear.frame(width: extra)
            }
            .compatBackground {
                Color.clear
            }
    }
}
