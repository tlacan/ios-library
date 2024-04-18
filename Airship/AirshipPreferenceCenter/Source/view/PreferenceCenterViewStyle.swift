/* Copyright Airship and Contributors */

import Foundation
import SwiftUI

/// Preference Center view style configuration
public struct PreferenceCenterViewStyleConfiguration {
    /// The view's phase
    public let phase: PreferenceCenterViewPhase

    /// The preference center theme
    public let preferenceCenterTheme: PreferenceCenterTheme

    /// A block that can be called to refresh the view
    public let refresh: () -> Void
}

/// Preference Center view style
public protocol PreferenceCenterViewStyle {
    associatedtype Body: View
    typealias Configuration = PreferenceCenterViewStyleConfiguration
    func makeBody(configuration: Self.Configuration) -> Self.Body
}

extension PreferenceCenterViewStyle
where Self == DefaultPreferenceCenterViewStyle {
    /// Default style
    public static var defaultStyle: Self {
        return .init()
    }
}

/// The default Preference Center view style
public struct DefaultPreferenceCenterViewStyle: PreferenceCenterViewStyle {

    static let subtitleAppearance = PreferenceCenterTheme.TextAppearance(
        font: .subheadline
    )

    static let buttonLabelAppearance = PreferenceCenterTheme.TextAppearance(
        color: .white
    )

    private func navigationBarTitle(
        configuration: Configuration,
        state: PreferenceCenterState? = nil
    ) -> String {

        var title: String?
        if let state = state {
            title = state.config.display?.title?.nullIfEmpty()
        }

        let theme = configuration.preferenceCenterTheme
        if let overrideConfigTitle = theme.viewController?.navigationBar?.overrideConfigTitle, overrideConfigTitle {
            title = configuration.preferenceCenterTheme.viewController?
                .navigationBar?
                .title
        }
        return title ?? "ua_preference_center_title".preferenceCenterLocalizedString
    }

    @ViewBuilder
    private func makeProgressView(configuration: Configuration) -> some View {
        ProgressView()
            .frame(alignment: .center)
            .navigationTitle(navigationBarTitle(configuration: configuration))
    }

    @ViewBuilder
    public func makeErrorView(configuration: Configuration) -> some View {
        let theme = configuration.preferenceCenterTheme.preferenceCenter
        let retry = theme?.retryButtonLabel ?? "ua_retry_button".preferenceCenterLocalizedString
        let errorMessage =
        theme?.retryMessage ?? "ua_preference_center_empty".preferenceCenterLocalizedString

        VStack {
            Text(errorMessage)
                .textAppearance(theme?.retryMessageAppearance)
                .padding(16)

            Button(
                action: {
                    configuration.refresh()
                },
                label: {
                    Text(retry)
                        .textAppearance(
                            theme?.retryButtonLabelAppearance,
                            base: DefaultPreferenceCenterViewStyle
                                .buttonLabelAppearance
                        )
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(
                                    theme?.retryButtonBackgroundColor
                                    ?? Color.blue
                                )
                        )
                        .cornerRadius(8)
                        .frame(minWidth: 44)
                }
            )
        }
        .navigationTitle(navigationBarTitle(configuration: configuration))
    }

    public func makePreferenceCenterView(
        configuration: Configuration,
        state: PreferenceCenterState
    ) -> some View {
        let theme = configuration.preferenceCenterTheme
        return ScrollView {
            LazyVStack(alignment: .leading) {
                if let subtitle = state.config.display?.subtitle {
                    Text(subtitle)
                        .textAppearance(
                            theme.preferenceCenter?.subtitleAppearance,
                            base: DefaultPreferenceCenterViewStyle
                                .subtitleAppearance
                        )
                        .padding(.bottom, 16)
                }

                ForEach(0..<state.config.sections.count, id: \.self) { index in
                    self.section(
                        state.config.sections[index],
                        state: state
                    )
                }
            }
            .padding(16)
            Spacer()
        }
        .navigationTitle(navigationBarTitle(configuration: configuration, state: state))
    }

    @ViewBuilder
    public func makeBody(configuration: Configuration) -> some View {

        switch configuration.phase {
        case .loading:
            makeProgressView(configuration: configuration)
        case .error(_):
            makeErrorView(configuration: configuration)
        case .loaded(let state):
            makePreferenceCenterView(configuration: configuration, state: state)
        }
    }

    @ViewBuilder
    func section(
        _ section: PreferenceCenterConfig.Section,
        state: PreferenceCenterState
    ) -> some View {
        switch section {
        case .common(let section):
            CommonSectionView(
                section: section,
                state: state
            )
        case .labeledSectionBreak(let section):
            LabeledSectionBreakView(
                section: section,
                state: state
            )
        }
    }
}

struct AnyPreferenceCenterViewStyle: PreferenceCenterViewStyle {
    @ViewBuilder
    private var _makeBody: (Configuration) -> AnyView

    init<S: PreferenceCenterViewStyle>(style: S) {
        _makeBody = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }

    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        _makeBody(configuration)
    }
}

struct PreferenceCenterViewStyleKey: EnvironmentKey {
    static var defaultValue = AnyPreferenceCenterViewStyle(style: .defaultStyle)
}

extension EnvironmentValues {
    var airshipPreferenceCenterStyle: AnyPreferenceCenterViewStyle {
        get { self[PreferenceCenterViewStyleKey.self] }
        set { self[PreferenceCenterViewStyleKey.self] = newValue }
    }
}

extension String {
    fileprivate func nullIfEmpty() -> String? {
        return self.isEmpty ? nil : self
    }
}
