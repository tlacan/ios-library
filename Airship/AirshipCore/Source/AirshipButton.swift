/* Copyright Airship and Contributors */

import Foundation
import SwiftUI

/// Button view.
struct AirshipButton<Label> : View  where Label : View {

    @EnvironmentObject private var formState: FormState
    @EnvironmentObject private var pagerState: PagerState
    @EnvironmentObject private var viewState: ViewState
    @EnvironmentObject private var thomasEnvironment: ThomasEnvironment
    @Environment(\.layoutState) private var layoutState

    let identifier: String
    let reportingMetadata: AirshipJSON?
    let description: String
    let clickBehaviors:[ButtonClickBehavior]?
    let eventHandlers: [EventHandler]?
    let actions: ActionsPayload?
    let tapEffect: ButtonTapEffect?
    let label: () -> Label

    var body: some View {
        Button(
            action: {
                doButtonActions()
            },
            label: self.label
        )
        .accessibilityLabel(self.description)
        .buttonTapEffect(self.tapEffect)
    }

    private func doButtonActions() {
        let taps = self.eventHandlers?.filter { $0.type == .tap }

        // Button reporting
        thomasEnvironment.buttonTapped(
            buttonIdentifier: self.identifier,
            reportingMetatda: self.reportingMetadata,
            layoutState: layoutState
        )

        // Buttons
        handleBehaviors(self.clickBehaviors ?? [])
        handleActions(self.actions)

        /// Tap handlers
        taps?.forEach { tap in
            handleStateActions(tap.stateActions)
        }
    }

    private func handleBehaviors(
        _ behaviors: [ButtonClickBehavior]?
    ) {
        behaviors?.sorted { first, second in
            first.sortOrder < second.sortOrder
        }.forEach { behavior in
            switch(behavior) {
            case .dismiss:
                thomasEnvironment.dismiss(
                    buttonIdentifier: self.identifier,
                    buttonDescription: self.description,
                    cancel: false,
                    layoutState: layoutState
                )

            case .cancel:
                  thomasEnvironment.dismiss(
                    buttonIdentifier: self.identifier,
                    buttonDescription: self.description,
                    cancel: true,
                    layoutState: layoutState
                  )

            case .pagerNext:
                withAnimation {
                    pagerState.pageIndex = min(
                        pagerState.pageIndex + 1,
                        pagerState.pages.count - 1
                    )
                }

            case .pagerPrevious:
                withAnimation {
                    pagerState.pageIndex = max(pagerState.pageIndex - 1, 0)
                }

            case .pagerNextOrDismiss:
                if pagerState.isLastPage() {
                    thomasEnvironment.dismiss(
                        buttonIdentifier: self.identifier,
                        buttonDescription: self.description,
                        cancel: false,
                        layoutState: layoutState
                    )
                } else {
                    withAnimation {
                        pagerState.pageIndex = max(pagerState.pageIndex + 1, 0)
                    }
                }

            case .pagerNextOrFirst:
                if pagerState.isLastPage() {
                    withAnimation {
                        pagerState.pageIndex = 0
                    }
                } else {
                    withAnimation {
                        pagerState.pageIndex = max(pagerState.pageIndex + 1, 0)
                    }
                }

            case .pagerPause:
                pagerState.pause()

            case .pagerResume:
                pagerState.resume()

            case .formSubmit:
                let formState = formState.topFormState
                thomasEnvironment.submitForm(formState, layoutState: layoutState)
                formState.markSubmitted()
            }
        }
    }

    private func handleActions(_ actionPayload: ActionsPayload?) {
        if let actionPayload {
            thomasEnvironment.runActions(actionPayload, layoutState: layoutState)
        }
    }

    private func handleStateActions(_ stateActions: [StateAction]) {
        stateActions.forEach { action in
            switch action {
            case .setState(let details):
                viewState.updateState(
                    key: details.key,
                    value: details.value?.unWrap()
                )
            case .clearState:
                viewState.clearState()
            case .formValue(_):
                AirshipLogger.error("Unable to process form value")
            }
        }
    }
}


fileprivate struct AirshipButtonEmptyStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

fileprivate extension View {
    @ViewBuilder
    func buttonTapEffect(_ tapEffect: ButtonTapEffect?) -> some View {
        switch(tapEffect ??  .default) {
        case .default:
            self.buttonStyle(.plain)
        case .none:
            self.buttonStyle(AirshipButtonEmptyStyle())
        }
    }
}
