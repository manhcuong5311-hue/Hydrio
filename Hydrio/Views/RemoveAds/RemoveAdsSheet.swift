import SwiftUI
import StoreKit

// MARK: - Remove Ads Sheet

/// The only purchase screen in Hydrio. Every feature is free; this one-time
/// purchase just removes the banner and full-screen ads.
/// Opened from Settings only — it never pops up by itself.
struct RemoveAdsSheet: View {
    @EnvironmentObject var store: StoreManager
    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false

    private let benefits: [(icon: String, color: Color, title: String)] = [
        ("eye.slash.fill", .hydrationBlue,        "No banner or full-screen ads"),
        ("infinity",       .goldPrimary,          "One-time purchase, yours forever"),
        ("heart.fill",     Color(hex: "FF5252"),  "Supports an indie developer"),
    ]

    private let termsURL   = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private let privacyURL = URL(string: "https://manhcuong5311-hue.github.io/Hydrio/")!

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            RadialGradient(colors: [Color.goldPrimary.opacity(0.12), Color.clear],
                           center: .top, startRadius: 0, endRadius: 380)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.lg) {
                    hero
                    benefitsCard
                    actions
                }
                .padding(.top, Spacing.xl)
                .padding(.bottom, Spacing.xxl)
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.white.opacity(0.25))
                    }
                    .accessibilityLabel("Close")
                    .padding([.top, .trailing], Spacing.md)
                }
                Spacer()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { appeared = true }
        }
        .task { await store.loadProduct() }
        // Purchase or restore succeeded (also via Transaction.updates) → close.
        .onChange(of: store.isAdFree) { _, adFree in
            guard adFree else { return }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: Hero

    private var hero: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.goldPrimary.opacity(0.15))
                    .frame(width: 110, height: 110)
                    .blur(radius: 20)
                Image(systemName: "nosign")
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundStyle(LinearGradient.goldGradient)
                    .shadow(color: Color.goldPrimary.opacity(0.5), radius: 14)
                    .scaleEffect(appeared ? 1.0 : 0.6)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.65), value: appeared)
            }

            VStack(spacing: Spacing.xs) {
                Text("Remove Ads")
                    .font(.displaySmall).foregroundStyle(.textPrimary)
                Text("Enjoy Hydrio without interruptions — every feature is already free.")
                    .font(.bodyMedium).foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Spacing.lg)
        }
    }

    // MARK: Benefits

    private var benefitsCard: some View {
        GlassCard(padding: Spacing.md) {
            VStack(spacing: 0) {
                ForEach(Array(benefits.enumerated()), id: \.offset) { idx, benefit in
                    HStack(spacing: Spacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(benefit.color.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: benefit.icon)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(benefit.color)
                        }
                        Text(benefit.title)
                            .font(.titleSmall).foregroundStyle(.textPrimary)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.bodyMedium).foregroundStyle(.goldPrimary)
                    }
                    .padding(.vertical, Spacing.sm)
                    .opacity(appeared ? 1 : 0)
                    .offset(x: appeared ? 0 : 28)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8)
                        .delay(0.15 + Double(idx) * 0.07), value: appeared)

                    if idx < benefits.count - 1 {
                        Divider().background(Color.white.opacity(0.06))
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    // MARK: Actions

    private var actions: some View {
        VStack(spacing: Spacing.md) {
            purchaseButton

            Button {
                Task { await restore() }
            } label: {
                HStack(spacing: 6) {
                    if store.purchaseState == .restoring {
                        ProgressView().tint(.textSecondary).scaleEffect(0.8)
                    }
                    Text(store.purchaseState == .restoring ? "Restoring…" : "Restore Purchases")
                }
                .font(.bodySmall).fontWeight(.semibold).foregroundStyle(.textSecondary)
            }
            .disabled(store.purchaseState.isLoading)

            VStack(spacing: Spacing.xs) {
                Text("One-time payment charged to your Apple ID. No subscription.")
                    .font(.captionSmall).foregroundStyle(.textTertiary)
                    .multilineTextAlignment(.center)

                HStack(spacing: Spacing.sm) {
                    Link(destination: termsURL) {
                        Text("Terms of Use").underline().foregroundStyle(.textTertiary)
                    }
                    Text("·").foregroundStyle(.textTertiary)
                    Link(destination: privacyURL) {
                        Text("Privacy Policy").underline().foregroundStyle(.textTertiary)
                    }
                }
                .font(.captionSmall)
            }
        }
        .padding(.horizontal, Spacing.xl)
    }

    private var isBusy: Bool {
        store.purchaseState.isLoading || (store.product == nil && store.isLoadingProduct)
    }

    private var purchaseButton: some View {
        Button {
            Task { await purchase() }
        } label: {
            HStack(spacing: Spacing.sm) {
                if isBusy {
                    ProgressView().tint(Color(hex: "0B0B0B")).scaleEffect(0.85)
                } else {
                    Image(systemName: "nosign")
                }
                Text(purchaseTitle).fontWeight(.semibold)
            }
            .font(.titleSmall)
            .foregroundStyle(Color(hex: "0B0B0B"))
            .frame(maxWidth: .infinity).frame(height: 56)
            .background(LinearGradient.goldGradient)
            .clipShape(RoundedRectangle(cornerRadius: Radius.full, style: .continuous))
            .shadow(color: Color.goldPrimary.opacity(0.4), radius: 12, y: 6)
            .opacity(isBusy ? 0.75 : 1)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isBusy)
    }

    private var purchaseTitle: String {
        if store.purchaseState == .purchasing { return "Processing…" }
        if let product = store.product { return "Remove Ads – \(product.displayPrice)" }
        return "Remove Ads"
    }

    // MARK: Store actions

    private func purchase() async {
        await store.purchase()
        if let error = store.purchaseState.errorMessage {
            store.resetState()
            present("Purchase Failed", error)
        }
        // Success is handled by `onChange(of: store.isAdFree)`;
        // cancelled / pending purchases simply stay on this sheet.
    }

    private func restore() async {
        await store.restore()
        if !store.isAdFree {
            present("Restore Purchases",
                    store.purchaseState.errorMessage ?? "No previous purchases found for this Apple ID.")
        }
        store.resetState()
    }

    private func present(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

// MARK: - Remove Ads Card (Settings)

/// Settings entry point for the Remove Ads purchase.
/// Shows a "thank you" state once the user is ad-free.
struct RemoveAdsCard: View {
    let isAdFree: Bool
    let price: String?
    let onTap: () -> Void

    var body: some View {
        if isAdFree {
            content
        } else {
            Button(action: onTap) { content }
                .buttonStyle(ScaleButtonStyle())
        }
    }

    private var content: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.goldPrimary.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: isAdFree ? "checkmark.seal.fill" : "nosign")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(LinearGradient.goldGradient)
            }

            VStack(alignment: .leading, spacing: 3) {
                if isAdFree {
                    Text("Ads removed — thank you!")
                        .font(.titleMedium).foregroundStyle(.textPrimary)
                    Text("Your support keeps Hydrio growing.")
                        .font(.captionLarge).foregroundStyle(.goldPrimary)
                } else {
                    Text("Remove Ads")
                        .font(.titleMedium).foregroundStyle(.textPrimary)
                    Text(price.map { "One-time purchase · \($0)" } ?? "One-time purchase")
                        .font(.captionLarge).foregroundStyle(.goldPrimary)
                }
            }

            Spacer()

            if !isAdFree {
                Text("Remove")
                    .font(.captionLarge).fontWeight(.bold)
                    .foregroundStyle(Color(hex: "0B0B0B"))
                    .padding(.horizontal, Spacing.md).padding(.vertical, Spacing.sm)
                    .background(LinearGradient.goldGradient)
                    .clipShape(Capsule())
                    .shadow(color: Color.goldPrimary.opacity(0.4), radius: 8, y: 4)
            }
        }
        .padding(Spacing.md)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color(hex: "1A1500"), Color(hex: "0F0C00")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                RadialGradient(
                    colors: [Color.goldPrimary.opacity(0.18), Color.clear],
                    center: .bottomTrailing, startRadius: 0, endRadius: 160
                )
                .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.goldPrimary.opacity(0.8), Color.goldSecondary.opacity(0.3),
                                     Color.goldPrimary.opacity(0.1)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        )
    }
}
