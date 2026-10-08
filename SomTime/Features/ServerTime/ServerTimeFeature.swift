//
//  ServerTimeFeature.swift
//  SomTime
//

import ComposableArchitecture

// TODO: 서버 시간 화면 이슈에서 구현
@Reducer
struct ServerTimeFeature {
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
