import SwiftUI
import StoreKit

struct OnboardingView: View {
    @EnvironmentObject var hydrationVM: HydrationViewModel
    @StateObject private var vm = OnboardingViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            // Background glow
            RadialGradient(
                colors: [Color.hydrationBlue.opacity(0.12), Color.clear],
                center: .top, startRadius: 0, endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page indicator
                if vm.currentPage > 0 {
                    HStack(spacing: 6) {
                        ForEach(0..<vm.totalPages, id: \.self) { i in
                            Capsule()
                                .fill(i <= vm.currentPage ? Color.hydrationBlue : Color.white.opacity(0.2))
                                .frame(width: i == vm.currentPage ? 20 : 6, height: 6)
                                .animation(.spring(response: 0.4), value: vm.currentPage)
                        }
                    }
                    .padding(.top, Spacing.lg)
                }

                // Pages
                TabView(selection: $vm.currentPage) {
                    OnboardingHeroPage(onNext: vm.next).tag(0)
                    OnboardingBenefitsPage(onNext: vm.next).tag(1)
                    OnboardingProfilePage(vm: vm, onNext: vm.next).tag(2)
                    OnboardingGoalPage(vm: vm, onNext: vm.next).tag(3)
                    OnboardingReminderPage(vm: vm, onNext: vm.next).tag(4)
                    OnboardingPremiumPage(vm: vm, onFinish: {
                        vm.finish(hydrationVM: hydrationVM)
                        withAnimation { hasCompletedOnboarding = true }
                    }).tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.35), value: vm.currentPage)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Page 1: Hero

struct OnboardingHeroPage: View {
    let onNext: () -> Void
    @State private var dropScale: CGFloat = 0.6
    @State private var dropOpacity: Double = 0
    @State private var glowRadius: CGFloat = 20
    @State private var showContent = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Animated water drop
            ZStack {
                // Outer glow rings
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(Color.hydrationBlue.opacity(0.15 - Double(i) * 0.04), lineWidth: 1)
                        .frame(width: 160 + CGFloat(i * 40), height: 160 + CGFloat(i * 40))
                        .scaleEffect(dropScale)
                }

                // Glow blob
                Circle()
                    .fill(Color.hydrationBlue.opacity(0.2))
                    .frame(width: 140, height: 140)
                    .blur(radius: glowRadius)

                // Drop shape
                Image(systemName: "drop.fill")
                    .font(.system(size: 100, weight: .regular))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "7DC4FF"), Color.hydrationBlue],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.hydrationBlue.opacity(0.6), radius: 20)
                    .scaleEffect(dropScale)
                    .opacity(dropOpacity)

                // Shine
                Ellipse()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 18, height: 30)
                    .offset(x: -18, y: -22)
                    .rotationEffect(.degrees(-20))
                    .scaleEffect(dropScale)
                    .opacity(dropOpacity)
            }
            .frame(height: 200)

            VStack(spacing: Spacing.md) {
                Text("Hydrio")
                    .font(.displayMedium)
                    .foregroundStyle(LinearGradient.goldGradient)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                Text("Stay Hydrated")
                    .font(.displaySmall)
                    .foregroundStyle(.textPrimary)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                Text("Build a healthy hydration habit and\ntransform your wellbeing.")
                    .font(.bodyMedium)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
            }
            .animation(.easeOut(duration: 0.6).delay(0.4), value: showContent)

            Spacer()

            VStack(spacing: Spacing.sm) {
                NavigationHintButton(title: "Get Started", isPrimary: true) {
                    onNext()
                }
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.7), value: showContent)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
                dropScale = 1.0
                dropOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(1)) {
                glowRadius = 40
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showContent = true }
        }
    }
}

struct NavigationHintButton: View {
    let title: String
    let isPrimary: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title).font(.titleSmall).fontWeight(.semibold)
                Image(systemName: "chevron.right").font(.bodySmall)
            }
            .foregroundStyle(isPrimary ? Color(hex: "0B0B0B") : .white)
            .frame(maxWidth: .infinity).frame(height: 56)
            .background(isPrimary ? AnyView(LinearGradient.goldGradient) : AnyView(Color.white.opacity(0.1)))
            .clipShape(RoundedRectangle(cornerRadius: Radius.full, style: .continuous))
            .shadow(color: isPrimary ? Color.goldPrimary.opacity(0.4) : .clear, radius: 12, y: 6)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Page 2: Benefits

struct OnboardingBenefitsPage: View {
    let onNext: () -> Void
    @State private var appeared = false

    let benefits: [(icon: String, title: String, desc: String, color: Color)] = [
        ("brain.fill",        "Better Focus",      "Stay mentally sharp and alert all day.",    Color(hex: "9C27B0")),
        ("bolt.heart.fill",   "More Energy",        "Fuel your body with proper hydration.",     Color(hex: "FF6B35")),
        ("figure.walk",       "Healthier Body",     "Support every cell and organ you have.",    Color(hex: "4CAF50")),
        ("moon.stars.fill",   "Better Sleep",       "Hydrated bodies rest and recover faster.",  Color.hydrationBlue),
    ]

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            VStack(spacing: Spacing.sm) {
                Text("Why Hydration?")
                    .font(.displaySmall).foregroundStyle(.textPrimary)
                Text("The science is clear — water powers everything.")
                    .font(.bodyMedium).foregroundStyle(.textSecondary).multilineTextAlignment(.center)
            }
            .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 20)

            VStack(spacing: Spacing.sm) {
                ForEach(Array(benefits.enumerated()), id: \.offset) { idx, benefit in
                    HStack(spacing: Spacing.md) {
                        ZStack {
                            Circle().fill(benefit.color.opacity(0.15)).frame(width: 52, height: 52)
                            Image(systemName: benefit.icon)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(benefit.color)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(benefit.title).font(.titleSmall).foregroundStyle(.textPrimary)
                            Text(benefit.desc).font(.bodySmall).foregroundStyle(.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                                    .strokeBorder(benefit.color.opacity(0.15), lineWidth: 1)
                            )
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(x: appeared ? 0 : 40)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1 + Double(idx) * 0.1), value: appeared)
                }
            }
            .padding(.horizontal, Spacing.md)

            Spacer()

            PrimaryButton("Continue", icon: "chevron.right") { onNext() }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxl)
        }
        .padding(.horizontal, Spacing.md)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { appeared = true }
        }
    }
}

// MARK: - Page 3: Profile

struct OnboardingProfilePage: View {
    @ObservedObject var vm: OnboardingViewModel
    let onNext: () -> Void
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                VStack(spacing: Spacing.sm) {
                    Text("Tell Us About You")
                        .font(.displaySmall).foregroundStyle(.textPrimary)
                    Text("We'll calculate your perfect daily goal.")
                        .font(.bodyMedium).foregroundStyle(.textSecondary)
                }
                .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 20)

                VStack(spacing: Spacing.md) {
                    // Gender
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Label("Gender", systemImage: "person.fill")
                            .font(.captionLarge).foregroundStyle(.textSecondary).textCase(.uppercase)
                        HStack(spacing: Spacing.sm) {
                            ForEach(Gender.allCases, id: \.self) { g in
                                Button { vm.gender = g } label: {
                                    Text(g.displayName)
                                        .font(.titleSmall)
                                        .foregroundStyle(vm.gender == g ? Color(hex: "0B0B0B") : .textPrimary)
                                        .frame(maxWidth: .infinity).frame(height: 44)
                                        .background(
                                            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                                                .fill(vm.gender == g
                                                      ? AnyShapeStyle(LinearGradient.goldGradient)
                                                      : AnyShapeStyle(Color.white.opacity(0.06)))
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                    }

                    // Weight
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Label("Weight: \(Int(vm.weight)) kg", systemImage: "scalemass.fill")
                            .font(.captionLarge).foregroundStyle(.textSecondary).textCase(.uppercase)
                        Slider(value: $vm.weight, in: 40...150, step: 1)
                            .tint(.hydrationBlue)
                    }
                    .padding(Spacing.md)
                    .background(RoundedRectangle(cornerRadius: Radius.md).fill(Color.white.opacity(0.04)))

                    // Activity Level
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Label("Activity Level", systemImage: "figure.run")
                            .font(.captionLarge).foregroundStyle(.textSecondary).textCase(.uppercase)
                        VStack(spacing: Spacing.xs) {
                            ForEach(ActivityLevel.allCases, id: \.self) { level in
                                Button { vm.activityLevel = level } label: {
                                    HStack {
                                        Image(systemName: level.icon)
                                            .font(.bodyMedium)
                                            .foregroundStyle(vm.activityLevel == level ? .goldPrimary : .textSecondary)
                                            .frame(width: 24)
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(level.displayName).font(.titleSmall)
                                                .foregroundStyle(vm.activityLevel == level ? .textPrimary : .textSecondary)
                                            Text(level.description).font(.captionSmall)
                                                .foregroundStyle(.textTertiary)
                                        }
                                        Spacer()
                                        if vm.activityLevel == level {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.goldPrimary)
                                        }
                                    }
                                    .padding(.vertical, Spacing.sm)
                                    .padding(.horizontal, Spacing.md)
                                    .background(
                                        RoundedRectangle(cornerRadius: Radius.md)
                                            .fill(vm.activityLevel == level ? Color.goldPrimary.opacity(0.08) : Color.white.opacity(0.03))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: Radius.md)
                                                    .strokeBorder(vm.activityLevel == level ? Color.goldPrimary.opacity(0.3) : Color.clear, lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xl)

            PrimaryButton("Calculate My Goal", icon: "chevron.right") { onNext() }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xl)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { appeared = true }
        }
    }
}

// MARK: - Page 4: Goal

struct OnboardingGoalPage: View {
    @ObservedObject var vm: OnboardingViewModel
    let onNext: () -> Void
    @State private var ringProgress: Double = 0
    @State private var appeared = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            VStack(spacing: Spacing.sm) {
                Text("Your Daily Goal")
                    .font(.displaySmall).foregroundStyle(.textPrimary)
                Text("Calculated for your body and lifestyle.")
                    .font(.bodyMedium).foregroundStyle(.textSecondary)
            }

            // Ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.07), lineWidth: 20)
                    .frame(width: 220, height: 220)
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        LinearGradient(colors: [.hydrationBlue, Color(hex: "7DC4FF")],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Color.hydrationBlue.opacity(0.4), radius: 10)
                VStack(spacing: 4) {
                    Text(vm.displayGoal)
                        .font(.numberLarge).foregroundStyle(.textPrimary)
                    Text("per day").font(.bodyMedium).foregroundStyle(.textSecondary)
                }
            }

            // Adjust goal slider
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label("Adjust Goal: \(vm.displayGoal)", systemImage: "slider.horizontal.3")
                    .font(.captionLarge).foregroundStyle(.textSecondary).textCase(.uppercase)
                Slider(value: $vm.selectedGoalML, in: 1000...5000, step: 100)
                    .tint(.hydrationBlue)
                    .onChange(of: vm.selectedGoalML) { _, newVal in
                        withAnimation(.spring()) { ringProgress = min(newVal / 4000, 1.0) }
                    }
                HStack {
                    Text("1.0L").font(.captionSmall).foregroundStyle(.textTertiary)
                    Spacer()
                    Text("5.0L").font(.captionSmall).foregroundStyle(.textTertiary)
                }
            }
            .padding(Spacing.md)
            .background(RoundedRectangle(cornerRadius: Radius.md).fill(Color.white.opacity(0.04)))
            .padding(.horizontal, Spacing.md)

            Spacer()

            PrimaryButton("Set This Goal", icon: "checkmark") { onNext() }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxl)
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            vm.selectedGoalML = vm.calculatedGoalML
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                appeared = true
                withAnimation(.easeOut(duration: 1.2)) {
                    ringProgress = min(vm.selectedGoalML / 4000, 1.0)
                }
            }
        }
    }
}

// MARK: - Page 5: Reminders

struct OnboardingReminderPage: View {
    @ObservedObject var vm: OnboardingViewModel
    let onNext: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            ZStack {
                Circle().fill(Color.goldPrimary.opacity(0.15)).frame(width: 120, height: 120)
                    .blur(radius: 20)
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 64, weight: .regular))
                    .foregroundStyle(LinearGradient.goldGradient)
            }

            VStack(spacing: Spacing.sm) {
                Text("Stay on Track")
                    .font(.displaySmall).foregroundStyle(.textPrimary)
                Text("Set smart reminders to never miss a sip.")
                    .font(.bodyMedium).foregroundStyle(.textSecondary).multilineTextAlignment(.center)
            }

            VStack(spacing: Spacing.sm) {
                ForEach(ReminderInterval.allCases, id: \.self) { interval in
                    Button { vm.reminderInterval = interval } label: {
                        HStack {
                            Image(systemName: interval == .never ? "bell.slash.fill" : "bell.fill")
                                .foregroundStyle(vm.reminderInterval == interval ? .goldPrimary : .textSecondary)
                                .frame(width: 24)
                            Text(interval.displayName)
                                .font(.titleSmall)
                                .foregroundStyle(vm.reminderInterval == interval ? .textPrimary : .textSecondary)
                            Spacer()
                            if vm.reminderInterval == interval {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.goldPrimary)
                            }
                        }
                        .padding(Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.md)
                                .fill(vm.reminderInterval == interval
                                      ? Color.goldPrimary.opacity(0.08)
                                      : Color.white.opacity(0.04))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Radius.md)
                                        .strokeBorder(
                                            vm.reminderInterval == interval
                                                ? Color.goldPrimary.opacity(0.3)
                                                : Color.clear,
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.md)

            Spacer()

            PrimaryButton("Set Reminders", icon: "bell.fill") { onNext() }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxl)
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { appeared = true }
        }
    }
}

// MARK: - Page 6: Premium

struct OnboardingPremiumPage: View {
    @ObservedObject var vm: OnboardingViewModel
    @EnvironmentObject var store: StoreManager
    let onFinish: () -> Void
    @State private var appeared = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    let features: [(icon: String, text: String)] = [
        ("chart.xyaxis.line", "Advanced analytics & trends"),
        ("drop.fill",         "Unlimited drink types"),
        ("brain.head.profile","AI hydration coach"),
        ("pawprint.fill",     "Full pet evolution system"),
        ("bell.badge.fill",   "Smart reminder scheduling"),
    ]

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            // Crown icon
            ZStack {
                Circle().fill(Color.goldPrimary.opacity(0.15)).frame(width: 110, height: 110).blur(radius: 15)
                Image(systemName: "crown.fill")
                    .font(.system(size: 56)).foregroundStyle(LinearGradient.goldGradient)
                    .shadow(color: Color.goldPrimary.opacity(0.5), radius: 12)
            }

            VStack(spacing: Spacing.sm) {
                Text("Go Premium")
                    .font(.displaySmall).foregroundStyle(.textPrimary)
                Text("Lifetime Access — \(store.product?.displayPrice ?? "$4.99")")
                    .font(.bodyMedium).foregroundStyle(.goldPrimary)
            }

            // Features
            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(features, id: \.icon) { f in
                    HStack(spacing: Spacing.md) {
                        Image(systemName: f.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.goldPrimary)
                            .frame(width: 24)
                        Text(f.text).font(.bodyMedium).foregroundStyle(.textPrimary)
                        Spacer()
                        Image(systemName: "checkmark").font(.captionLarge).foregroundStyle(.goldPrimary)
                    }
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Radius.lg).fill(Color.goldPrimary.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(Color.goldPrimary.opacity(0.2), lineWidth: 1))
            )
            .padding(.horizontal, Spacing.md)

            Spacer()

            VStack(spacing: Spacing.sm) {
                // Buy button
                Button {
                    Task {
                        await store.purchase()
                        if store.isPremium {
                            let impact = UINotificationFeedbackGenerator()
                            impact.notificationOccurred(.success)
                            onFinish()
                        } else if let err = store.purchaseState.errorMessage {
                            store.resetState()
                            errorMessage = err
                            showErrorAlert = true
                        }
                        // .userCancelled / .pending → do nothing, stay on page
                    }
                } label: {
                    HStack {
                        if store.purchaseState == .purchasing {
                            ProgressView().tint(Color(hex: "0B0B0B")).scaleEffect(0.85)
                        } else {
                            Image(systemName: "crown.fill")
                        }
                        Text(store.purchaseState == .purchasing
                             ? "Processing…"
                             : "Get Lifetime Access — \(store.product?.displayPrice ?? "$4.99")")
                            .font(.titleSmall).fontWeight(.semibold)
                    }
                    .foregroundStyle(Color(hex: "0B0B0B"))
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .background(LinearGradient.goldGradient)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.full, style: .continuous))
                    .shadow(color: Color.goldPrimary.opacity(0.4), radius: 12, y: 6)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(store.purchaseState.isLoading)

                Button("Continue with Free") { onFinish() }
                    .font(.bodyMedium).foregroundStyle(.textSecondary)
                    .disabled(store.purchaseState.isLoading)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { appeared = true }
        }
        .alert("Purchase Failed", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
}
