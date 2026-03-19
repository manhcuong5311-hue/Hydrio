import SwiftUI

struct CustomAddView: View {
    @EnvironmentObject var vm: HydrationViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var amount: Double      = 250
    @State private var selectedType: DrinkType = .water
    @State private var note: String        = ""
    @State private var showSuccess         = false

    let presets: [Double] = [100, 150, 200, 250, 350, 500, 750, 1000]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {

                        // Amount display
                        VStack(spacing: Spacing.sm) {
                            ZStack {
                                Circle()
                                    .fill(selectedType.color.opacity(0.12))
                                    .frame(width: 120, height: 120)
                                    .blur(radius: 20)
                                VStack(spacing: 2) {
                                    Text(amount >= 1000
                                         ? String(format: "%.1fL", amount / 1000)
                                         : "\(Int(amount))")
                                        .font(.numberLarge)
                                        .foregroundStyle(.textPrimary)
                                    Text(amount >= 1000 ? "" : "ml")
                                        .font(.titleMedium)
                                        .foregroundStyle(.textSecondary)
                                }
                            }

                            Slider(value: $amount, in: 50...1500, step: 25)
                                .tint(selectedType.color)
                                .padding(.horizontal, Spacing.md)
                        }
                        .padding(.vertical, Spacing.md)

                        // Presets
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Quick Presets")
                                .font(.captionLarge).foregroundStyle(.textSecondary).textCase(.uppercase)
                                .padding(.horizontal, Spacing.md)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 4),
                                      spacing: Spacing.sm) {
                                ForEach(presets, id: \.self) { preset in
                                    Button {
                                        withAnimation(.spring(response: 0.3)) { amount = preset }
                                    } label: {
                                        VStack(spacing: 2) {
                                            Text(preset >= 1000 ? "\(Int(preset/1000))L" : "\(Int(preset))")
                                                .font(.titleSmall)
                                                .foregroundStyle(amount == preset ? Color(hex: "0B0B0B") : .textPrimary)
                                            Text(preset >= 1000 ? "" : "ml")
                                                .font(.captionSmall)
                                                .foregroundStyle(amount == preset ? Color(hex: "0B0B0B").opacity(0.7) : .textTertiary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 52)
                                        .background(
                                            amount == preset
                                                ? AnyView(LinearGradient(colors: [selectedType.color, selectedType.color.opacity(0.7)],
                                                                          startPoint: .top, endPoint: .bottom))
                                                : AnyView(Color.white.opacity(0.05))
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                                                .strokeBorder(amount == preset ? Color.clear : Color.white.opacity(0.08), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                            .padding(.horizontal, Spacing.md)
                        }

                        // Drink type
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Drink Type")
                                .font(.captionLarge).foregroundStyle(.textSecondary).textCase(.uppercase)
                                .padding(.horizontal, Spacing.md)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 3),
                                      spacing: Spacing.sm) {
                                ForEach(DrinkType.allCases) { type in
                                    Button { selectedType = type } label: {
                                        VStack(spacing: Spacing.xs) {
                                            ZStack {
                                                Circle()
                                                    .fill(type.color.opacity(selectedType == type ? 0.25 : 0.10))
                                                    .frame(width: 44, height: 44)
                                                Image(systemName: type.icon)
                                                    .font(.system(size: 18, weight: .semibold))
                                                    .foregroundStyle(type.color)
                                            }
                                            Text(type.displayName)
                                                .font(.captionLarge)
                                                .foregroundStyle(selectedType == type ? .textPrimary : .textSecondary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, Spacing.sm)
                                        .background(
                                            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                                                .fill(selectedType == type ? type.color.opacity(0.12) : Color.white.opacity(0.04))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                                                        .strokeBorder(selectedType == type ? type.color.opacity(0.4) : Color.white.opacity(0.07), lineWidth: 1.5)
                                                )
                                        )
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                            .padding(.horizontal, Spacing.md)
                        }

                        // Note (optional)
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Note (optional)")
                                .font(.captionLarge).foregroundStyle(.textSecondary).textCase(.uppercase)
                                .padding(.horizontal, Spacing.md)
                            TextField("e.g. Post-workout", text: $note)
                                .font(.bodyMedium)
                                .foregroundStyle(.textPrimary)
                                .padding(Spacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: Radius.md)
                                        .fill(Color.white.opacity(0.05))
                                        .overlay(RoundedRectangle(cornerRadius: Radius.md)
                                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                                )
                                .padding(.horizontal, Spacing.md)
                        }

                        // Log button
                        PrimaryButton("Log \(amount >= 1000 ? String(format: "%.1fL", amount/1000) : "\(Int(amount))ml") of \(selectedType.displayName)",
                                      icon: selectedType.icon) {
                            vm.addDrink(amountML: amount, type: selectedType)
                            let impact = UINotificationFeedbackGenerator()
                            impact.notificationOccurred(.success)
                            withAnimation { showSuccess = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { dismiss() }
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.bottom, Spacing.xl)
                    }
                    .padding(.top, Spacing.md)
                }

                // Success overlay
                if showSuccess {
                    ZStack {
                        Color.black.opacity(0.5).ignoresSafeArea()
                        VStack(spacing: Spacing.md) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(.successGreen)
                                .modifier(BounceEffectModifier())
                            Text("Logged!").font(.displaySmall).foregroundStyle(.white)
                        }
                    }
                    .transition(.opacity)
                }
            }
            .navigationTitle("Log a Drink")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.textSecondary)
                }
            }
        }
    }
}

struct BounceEffectModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 18, *) {
            content.symbolEffect(.bounce)
        } else {
            // Fallback animation cho iOS 17
            content
                .scaleEffect(1.0)
                .onAppear {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { }
                }
        }
    }
}
