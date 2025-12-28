import SwiftUI
import SwiftUIBackports

struct ToggleChipButton: View {
    @Binding var isOn: Bool
    let label: LocalizedStringKey

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(isOn ? .primary : .tertiary)
                    .contentTransition(.symbolEffect(.replace))

                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isOn ? .primary : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .allowsTightening(true)

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .animation(.easeOut(duration: 0.08), value: isOn)
        }
        .buttonStyle(.plain)
        .backport.glassEffect(in: .rect(cornerRadius: 12))
        .accessibilityLabel(label)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityAddTraits(.isButton)
    }
}
