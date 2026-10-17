//
//  ContentView.swift
//  GraphStudio
//
//  Root of the app: owns the graph store and hosts the navigation stack that
//  connects the graph list to the per-graph editor.
//

import SwiftUI
import UIKit

// MARK: - Keyboard dismissal

extension EnvironmentValues {
    /// A closure that hides the on-screen keyboard by resigning the first
    /// responder. Injected once at the root and read from any screen.
    var keyboardDismiss: () -> Void {
        get { self[KeyboardDismissKey.self] }
        set { self[KeyboardDismissKey.self] = newValue }
    }

    struct KeyboardDismissKey: EnvironmentKey {
        static let defaultValue: () -> Void = {}
    }
}

extension View {
    /// Injects a keyboard-dismiss closure so every descendant can read it.
    func injectKeyboardDismiss(_ action: @escaping () -> Void) -> some View {
        environment(\.keyboardDismiss, action)
    }

    /// Dismisses the keyboard when the user taps a non-interactive area of this
    /// view. Interactive controls (fields, buttons, pickers) keep their own
    /// taps, so tapping a field still focuses it.
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTapModifier())
    }
}

/// Attaches a tap gesture to a clear background layer. Because the layer sits
/// *behind* the content, only taps on empty space reach it; tapping a control
/// is consumed by that control instead, so fields can still be focused.
private struct DismissKeyboardOnTapModifier: ViewModifier {
    @Environment(\.keyboardDismiss) private var keyboardDismiss

    func body(content: Content) -> some View {
        content
            .background(
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(perform: keyboardDismiss)
            )
    }
}

/// Resigns the first responder so the on-screen keyboard hides.
@available(iOS 16.0, *)
func resignKeyboard() {
    if let scene = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first(where: { $0.activationState == .foregroundActive }) {
        for window in scene.windows {
            window.endEditing(true)
        }
    }
}

struct ContentView: View {
    @StateObject private var store = GraphStore()
    @State private var path = NavigationPath()

    var body: some View {
        // A full-bleed background sits behind the navigation stack so the window
        // is painted edge-to-edge instead of leaving black bars above the status
        // bar and below the home indicator.
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea(.all)

            NavigationStack(path: $path) {
                GraphListView(store: store, path: $path)
                    // Route value-based navigation (tap a graph row, or the "+" button)
                    // to the per-graph editor.
                    .navigationDestination(for: Graph.ID.self) { id in
                        GraphEditorView(store: store, graphID: id, path: $path)
                            .navigationTitle("New Graph")
                    }
            }
        }
        // Resigns the first responder so tapping empty space hides the keyboard.
        // Injected here it is available to every screen pushed onto the stack.
        .injectKeyboardDismiss { resignKeyboard() }
    }
}

#Preview {
    ContentView()
}
