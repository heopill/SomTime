//
//  PacerModels.swift
//  SomTime
//

import Foundation

/// 페이서 포인트 지갑 (iCloud 키-값 저장소에 저장해 같은 Apple ID 기기끼리 동기화한다).
/// 페이서는 문자열 ID로 저장한다. enum으로 저장하면 나중에 페이서를 없앴을 때 지갑 전체를 읽지 못해 포인트까지 잃는다
nonisolated struct PacerWallet: Codable, Equatable, Sendable {
    /// 광고 1회 시청 보상
    static let rewardPerAd = 10
    /// 하루에 받을 수 있는 광고 보상 횟수 (광고 5번이면 페이서 하나 값)
    static let dailyAdRewardLimit = 5
    /// 하루 한 번 출석 보상
    static let attendanceReward = 10
    /// 출석 · 광고 보상 횟수가 초기화되는 시각 (기기 시간대 기준 오전 9시)
    static let dailyResetHour = 9

    var points = 0
    /// 해제한 페이서 ID(PipPacer.rawValue) → 해제할 때 쓴 포인트 (운영을 끝낼 때 낸 만큼 돌려주기 위해 저장한다)
    var unlockedPacers: [String: Int] = [:]
    /// 운영 종료로 포인트를 돌려준 페이서 ID (여러 번 돌려주지 않도록 기록한다)
    var refundedPacerIDs: Set<String> = []
    var lastAttendanceAt: Date?
    /// 마지막 광고 보상을 받은 날(오전 9시 기준)에 받은 광고 보상 횟수
    var adRewardCount = 0
    var lastAdRewardAt: Date?

    /// 해당 페이서를 쓸 수 있는지 여부 (무료 페이서는 항상 쓸 수 있다)
    func isUnlocked(_ pacer: PipPacer) -> Bool {
        return pacer.isFree || unlockedPacers[pacer.rawValue] != nil
    }

    /// 포인트를 써서 페이서를 해제한다 (이미 해제했거나 포인트가 모자라면 false)
    mutating func unlock(_ pacer: PipPacer) -> Bool {
        guard !isUnlocked(pacer), points >= pacer.price else { return false }

        points -= pacer.price
        unlockedPacers[pacer.rawValue] = pacer.price

        return true
    }

    /// 지금 출석 보상을 받을 수 있는지 여부.
    /// 마지막 출석이 가장 최근 오전 9시보다 앞서야 하고, 기기 시간을 마지막 출석보다 과거로 돌린 경우는 받을 수 없다
    func canAttend(at date: Date, calendar: Calendar = .current) -> Bool {
        guard let lastAttendanceAt else { return true }
        guard lastAttendanceAt <= date else { return false }

        return lastAttendanceAt < Self.latestDailyReset(before: date, calendar: calendar)
    }

    /// 출석 보상을 받는다 (받을 수 없으면 false)
    mutating func attend(at date: Date, calendar: Calendar = .current) -> Bool {
        guard canAttend(at: date, calendar: calendar) else { return false }

        points += Self.attendanceReward
        lastAttendanceAt = date

        return true
    }

    /// 오늘(가장 최근 오전 9시 이후) 받은 광고 보상 횟수.
    /// 기기 시간을 마지막 광고 보상보다 과거로 돌려도 초기화되지 않는다
    func todayAdRewardCount(at date: Date, calendar: Calendar = .current) -> Int {
        guard let lastAdRewardAt,
              lastAdRewardAt >= Self.latestDailyReset(before: date, calendar: calendar) else { return 0 }

        return adRewardCount
    }

    /// 광고 보상을 받는다 (오늘 받을 수 있는 횟수를 다 썼으면 false)
    mutating func earnAdReward(at date: Date, calendar: Calendar = .current) -> Bool {
        let count = todayAdRewardCount(at: date, calendar: calendar)
        guard count < Self.dailyAdRewardLimit else { return false }

        points += Self.rewardPerAd
        adRewardCount = count + 1
        lastAdRewardAt = max(lastAdRewardAt ?? date, date)

        return true
    }

    /// 운영을 끝낸 페이서를 해제했던 만큼 포인트로 돌려주고, 돌려준 포인트 합계를 돌려준다 (돌려줄 것이 없으면 0)
    mutating func applyRetirements(_ retiredPacerIDs: Set<String> = PacerRetirement.retiredPacerIDs) -> Int {
        var refunded = 0
        for id in retiredPacerIDs where !refundedPacerIDs.contains(id) {
            guard let paid = unlockedPacers[id] else { continue }

            refunded += paid
            unlockedPacers[id] = nil
            refundedPacerIDs.insert(id)
        }
        points += refunded

        return refunded
    }

    /// 다른 기기에서 저장한 지갑과 합친다 (포인트는 지금 지갑 값을 따른다).
    /// 해제 · 환불 기록은 합집합으로 합쳐 잃지 않게 하고, 출석 시각은 늦은 쪽을 따라 같은 날 두 번 받지 않게 한다.
    /// 광고 보상 횟수는 더 늦은 날의 횟수를 따르고, 같은 날이면 큰 값을 따라 하루 횟수를 넘기지 않게 한다
    func merged(with other: PacerWallet, calendar: Calendar = .current) -> PacerWallet {
        var result = self
        result.unlockedPacers.merge(other.unlockedPacers) { current, _ in current }
        result.refundedPacerIDs.formUnion(other.refundedPacerIDs)
        for id in result.refundedPacerIDs {
            result.unlockedPacers[id] = nil
        }
        if let otherDate = other.lastAttendanceAt {
            result.lastAttendanceAt = max(result.lastAttendanceAt ?? otherDate, otherDate)
        }
        if let otherDate = other.lastAdRewardAt {
            if let currentDate = result.lastAdRewardAt {
                let currentDay = Self.latestDailyReset(before: currentDate, calendar: calendar)
                let otherDay = Self.latestDailyReset(before: otherDate, calendar: calendar)
                if currentDay == otherDay {
                    result.adRewardCount = max(result.adRewardCount, other.adRewardCount)
                } else if otherDay > currentDay {
                    result.adRewardCount = other.adRewardCount
                }
                result.lastAdRewardAt = max(currentDate, otherDate)
            } else {
                result.adRewardCount = other.adRewardCount
                result.lastAdRewardAt = otherDate
            }
        }

        return result
    }

    /// 해당 시각 이전(같은 시각 포함)의 가장 최근 초기화 시각 (오전 9시)
    private static func latestDailyReset(before date: Date, calendar: Calendar) -> Date {
        let todayReset = calendar.date(bySettingHour: dailyResetHour, minute: 0, second: 0, of: date) ?? date
        guard todayReset > date else { return todayReset }

        return calendar.date(byAdding: .day, value: -1, to: todayReset) ?? todayReset
    }
}

extension PacerWallet {
    /// 저장된 지갑을 읽는다. 나중에 추가한 항목이 없는 예전 지갑도 기본값으로 채워 읽는다
    /// (읽지 못하면 빈 지갑으로 덮어써서 포인트와 해제 기록을 잃는다)
    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        points = try container.decodeIfPresent(Int.self, forKey: .points) ?? 0
        unlockedPacers = try container.decodeIfPresent([String: Int].self, forKey: .unlockedPacers) ?? [:]
        refundedPacerIDs = try container.decodeIfPresent(Set<String>.self, forKey: .refundedPacerIDs) ?? []
        lastAttendanceAt = try container.decodeIfPresent(Date.self, forKey: .lastAttendanceAt)
        adRewardCount = try container.decodeIfPresent(Int.self, forKey: .adRewardCount) ?? 0
        lastAdRewardAt = try container.decodeIfPresent(Date.self, forKey: .lastAdRewardAt)
    }
}

/// 운영을 끝낸 페이서 목록. 페이서를 없앨 때 여기에 ID를 넣고, 해당 enum 케이스와 에셋을 지운다
nonisolated enum PacerRetirement {
    static let retiredPacerIDs: Set<String> = []
}
