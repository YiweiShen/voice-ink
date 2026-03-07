import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(CardBackground(isSelected: false))
    }
}
