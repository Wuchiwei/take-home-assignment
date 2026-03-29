import SwiftUI

struct OddsView: View {
    @State private var flashColor: Color = .clear

    let teamName: String
    let oddsText: String
    let oddsValue: Double?
    let colorScheme: OddsFlashColorScheme

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        VStack(spacing: 4) {
            oddsLabel
            Text(teamName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onChange(of: oddsValue) { oldValue, newValue in
            guard let oldValue, let newValue, oldValue != newValue else { return }
            let color = newValue > oldValue ? colorScheme.riseColor : colorScheme.fallColor
            withAnimation(.easeIn(duration: 0.2)) {
                flashColor = color
            }
            withAnimation(.easeOut(duration: 1).delay(0.2)) {
                flashColor = .clear
            }
        }
    }

    private var oddsLabel: some View {
        Text(oddsText)
            .font(.title3.bold())
            .foregroundStyle(oddsValue != nil ? .primary : .tertiary)
            .frame(minWidth: 64, minHeight: 20)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(flashColor.opacity(0.25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            )
    }
}

#if DEBUG
#Preview("With odds") {
    HStack(spacing: 32) {
        OddsView(
            teamName: "Eagles",
            oddsText: "2.35",
            oddsValue: 2.35,
            colorScheme: .western
        )
        OddsView(
            teamName: "Tigers",
            oddsText: "1.75",
            oddsValue: 1.75,
            colorScheme: .western
        )
    }
    .padding()
}

#Preview("Placeholder") {
    HStack(spacing: 32) {
        OddsView(
            teamName: "Eagles",
            oddsText: "-",
            oddsValue: nil,
            colorScheme: .western
        )
        OddsView(
            teamName: "Tigers",
            oddsText: "-",
            oddsValue: nil,
            colorScheme: .western
        )
    }
    .padding()
}
#endif
