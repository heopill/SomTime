//
//  PrivacyPolicyFeature.swift
//  SomTime
//

import ComposableArchitecture

@Reducer
struct PrivacyPolicyFeature {
    @ObservableState
    struct State: Equatable {}

    enum Action {
        case backButtonTapped
    }

    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action> {
        Reduce { _, action in
            switch action {
            case .backButtonTapped:
                return .run { _ in await dismiss() }
            }
        }
    }
}
