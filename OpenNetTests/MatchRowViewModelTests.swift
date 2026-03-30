import Foundation
import Testing
@testable import OpenNet

@MainActor
struct MatchRowViewModelTests {

    // MARK: - Helpers

    private func makeSUT(
        matchID: Int = 1,
        teamA: String = "Eagles",
        teamB: String = "Tigers",
        startTime: Date = Date(),
        odds: MatchOdds? = MatchOdds(matchID: 1, teamAOdds: 1.50, teamBOdds: 2.30)
    ) -> MatchRowViewModel {
        MatchRowViewModel(
            match: Match(
                matchID: matchID,
                teamA: teamA,
                teamB: teamB,
                startTime: startTime
            ),
            odds: odds,
            colorScheme: .western
        )
    }

    // MARK: - Initialization

    @Test func init_withOdds_setsAllProperties() {
        // Given
        let date = Date()

        // When
        let sut = makeSUT(
            matchID: 42,
            teamA: "Lions",
            teamB: "Bears",
            startTime: date,
            odds: MatchOdds(matchID: 42, teamAOdds: 1.80, teamBOdds: 2.10)
        )

        // Then
        #expect(sut.id == 42)
        #expect(sut.teamA == "Lions")
        #expect(sut.teamB == "Bears")
        #expect(sut.startTime == date)
        #expect(sut.teamAOdds == 1.80)
        #expect(sut.teamBOdds == 2.10)
    }

    @Test func init_withoutOdds_setsOddsToNil() {
        // Given / when
        let sut = makeSUT(odds: nil)

        // Then
        #expect(sut.teamAOdds == nil)
        #expect(sut.teamBOdds == nil)
    }

    // MARK: - Formatting

    @Test func teamAOddsText_withValue_formatsTwoDecimalPlaces() {
        // Given
        let sut = makeSUT(odds: MatchOdds(matchID: 1, teamAOdds: 1.5, teamBOdds: 2.3))

        // When — computed property access

        // Then
        #expect(sut.teamAOddsText == "1.50")
        #expect(sut.teamBOddsText == "2.30")
    }

    @Test func oddsText_withoutValue_returnsPlaceholder() {
        // Given
        let sut = makeSUT(odds: nil)

        // When — computed property access

        // Then
        #expect(sut.teamAOddsText == "-")
        #expect(sut.teamBOddsText == "-")
    }

    @Test func formattedStartTime_returnsNonEmptyString() {
        // Given
        let sut = makeSUT()

        // When — computed property access

        // Then
        #expect(!sut.formattedStartTime.isEmpty)
    }

    // MARK: - currentOdds

    @Test func currentOdds_withBothValues_returnsMatchOdds() {
        // Given
        let sut = makeSUT(odds: MatchOdds(matchID: 1, teamAOdds: 1.5, teamBOdds: 2.3))

        // When
        let odds = sut.currentOdds

        // Then
        #expect(odds != nil)
        #expect(odds?.matchID == 1)
        #expect(odds?.teamAOdds == 1.5)
        #expect(odds?.teamBOdds == 2.3)
    }

    @Test func currentOdds_withNoOdds_returnsNil() {
        // Given
        let sut = makeSUT(odds: nil)

        // When
        let odds = sut.currentOdds

        // Then
        #expect(odds == nil)
    }

    // MARK: - applyUpdate

    @Test func applyUpdate_updatesOddsValues() {
        // Given
        let sut = makeSUT(odds: MatchOdds(matchID: 1, teamAOdds: 1.5, teamBOdds: 2.3))
        let update = OddsUpdate(matchID: 1, teamAOdds: 1.8, teamBOdds: 2.0)

        // When
        sut.applyUpdate(update)

        // Then
        #expect(sut.teamAOdds == 1.8)
        #expect(sut.teamBOdds == 2.0)
        #expect(sut.teamAOddsText == "1.80")
        #expect(sut.teamBOddsText == "2.00")
    }

    @Test func applyUpdate_fromNilOdds_setsValues() {
        // Given
        let sut = makeSUT(odds: nil)
        let update = OddsUpdate(matchID: 1, teamAOdds: 3.0, teamBOdds: 1.2)

        // When
        sut.applyUpdate(update)

        // Then
        #expect(sut.teamAOdds == 3.0)
        #expect(sut.teamBOdds == 1.2)
        #expect(sut.currentOdds != nil)
    }

    // MARK: - Equatable

    @Test func equality_sameValues_areEqual() {
        // Given
        let date = Date()
        let odds = MatchOdds(matchID: 1, teamAOdds: 1.5, teamBOdds: 2.3)

        // When
        let a = makeSUT(matchID: 1, teamA: "Eagles", teamB: "Tigers", startTime: date, odds: odds)
        let b = makeSUT(matchID: 1, teamA: "Eagles", teamB: "Tigers", startTime: date, odds: odds)

        // Then
        #expect(a.id == b.id)
        #expect(a.teamA == b.teamA)
        #expect(a.teamB == b.teamB)
        #expect(a.startTime == b.startTime)
        #expect(a.teamAOdds == b.teamAOdds)
        #expect(a.teamBOdds == b.teamBOdds)
    }

    @Test func equality_differentOdds_areNotEqual() {
        // Given
        let date = Date()

        // When
        let a = makeSUT(matchID: 1, startTime: date, odds: MatchOdds(matchID: 1, teamAOdds: 1.5, teamBOdds: 2.3))
        let b = makeSUT(matchID: 1, startTime: date, odds: MatchOdds(matchID: 1, teamAOdds: 1.8, teamBOdds: 2.3))

        // Then
        #expect(a.teamAOdds != b.teamAOdds)
    }
}
