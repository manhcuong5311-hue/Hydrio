import SwiftUI

// MARK: - Pet Character View (router)

struct PetCharacterView: View {
    let pet: Pet
    var size: CGFloat = 120

    @State private var bounce     = false
    @State private var glowPulse  = false

    var body: some View {
        ZStack {
            // Ambient glow
            Circle()
                .fill(stageColor.opacity(glowPulse ? 0.28 : 0.10))
                .frame(width: size * 1.35, height: size * 1.35)
                .blur(radius: 22)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: glowPulse)

            // Ground shadow
            Ellipse()
                .fill(Color.black.opacity(0.25))
                .frame(width: size * 0.65, height: size * 0.1)
                .offset(y: size * 0.52)
                .blur(radius: 4)

            // Pet body
            petBody
                .offset(y: bounce ? -5 : 0)
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: bounce)
        }
        .onAppear { bounce = true; glowPulse = true }
    }

    @ViewBuilder
    private var petBody: some View {
        switch pet.type {
        case .plant:
            switch pet.growthStage {
            case .seed:   SeedPet(size: size, happiness: pet.happiness)
            case .sprout: SproutPet(size: size, happiness: pet.happiness)
            case .plant:  PlantPet(size: size, happiness: pet.happiness)
            case .tree:   TreePet(size: size, happiness: pet.happiness)
            case .bloom:  BloomPet(size: size, happiness: pet.happiness)
            }
        case .dragon:
            switch pet.growthStage {
            case .seed:   DragonEggPet(size: size, happiness: pet.happiness)
            case .sprout: DragonHatchlingPet(size: size, happiness: pet.happiness)
            case .plant:  BabyDragonPet(size: size, happiness: pet.happiness)
            case .tree:   DragonPet(size: size, happiness: pet.happiness)
            case .bloom:  AncientDragonPet(size: size, happiness: pet.happiness)
            }
        case .cloud:
            switch pet.growthStage {
            case .seed:   MistPet(size: size, happiness: pet.happiness)
            case .sprout: CloudPet(size: size, happiness: pet.happiness)
            case .plant:  RainCloudPet(size: size, happiness: pet.happiness)
            case .tree:   StormPet(size: size, happiness: pet.happiness)
            case .bloom:  RainbowPet(size: size, happiness: pet.happiness)
            }
        }
    }

    private var stageColor: Color {
        switch pet.type {
        case .plant:
            switch pet.growthStage {
            case .seed:   return Color(hex: "8B6914")
            case .sprout: return Color(hex: "4CAF50")
            case .plant:  return Color(hex: "2E7D32")
            case .tree:   return Color(hex: "1B5E20")
            case .bloom:  return Color(hex: "E91E63")
            }
        case .dragon:
            switch pet.growthStage {
            case .seed:   return Color(hex: "7B4FA6")
            case .sprout: return Color(hex: "26A69A")
            case .plant:  return Color(hex: "00897B")
            case .tree:   return Color(hex: "004D40")
            case .bloom:  return Color(hex: "FFD700")
            }
        case .cloud:
            switch pet.growthStage {
            case .seed:   return Color(hex: "B0BEC5")
            case .sprout: return Color(hex: "90CAF9")
            case .plant:  return Color(hex: "5C8FA8")
            case .tree:   return Color(hex: "37474F")
            case .bloom:  return Color(hex: "FF6B8A")
            }
        }
    }
}

// MARK: - Happiness Eyes Helper

private struct PetEyes: View {
    let size: CGFloat
    let happiness: Double
    let color: Color

    var body: some View {
        HStack(spacing: size * 0.11) {
            eyeShape
            eyeShape
        }
    }

    @ViewBuilder
    private var eyeShape: some View {
        if happiness < 0.3 {
            // Sad: tilted ellipses
            Ellipse()
                .fill(color)
                .frame(width: size * 0.07, height: size * 0.05)
                .rotationEffect(.degrees(10))
        } else {
            Circle().fill(color).frame(width: size * 0.07, height: size * 0.07)
        }
    }
}

// MARK: ─────────────────── PLANT FAMILY ───────────────────

struct SeedPet: View {
    let size: CGFloat; let happiness: Double
    var body: some View {
        ZStack {
            Ellipse()
                .fill(LinearGradient(colors: [Color(hex: "C8A96E"), Color(hex: "8B6914")],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.5, height: size * 0.62)
            PetEyes(size: size, happiness: happiness, color: .white)
                .offset(y: -size * 0.05)
            if happiness > 0.5 {
                Path { p in
                    p.addArc(center: .zero, radius: size * 0.07,
                             startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                }
                .stroke(Color.white, lineWidth: 1.5)
                .offset(y: size * 0.08)
            }
        }
        .frame(width: size, height: size)
    }
}

struct SproutPet: View {
    let size: CGFloat; let happiness: Double
    var body: some View {
        ZStack {
            Capsule()
                .fill(Color(hex: "4CAF50"))
                .frame(width: size * 0.06, height: size * 0.5)
                .offset(y: size * 0.15)
            Ellipse().fill(Color(hex: "66BB6A"))
                .frame(width: size * 0.26, height: size * 0.14)
                .rotationEffect(.degrees(-30)).offset(x: -size * 0.18, y: size * 0.02)
            Ellipse().fill(Color(hex: "81C784"))
                .frame(width: size * 0.26, height: size * 0.14)
                .rotationEffect(.degrees(30)).offset(x: size * 0.18, y: size * 0.02)
            Circle()
                .fill(LinearGradient(colors: [Color(hex: "A5D6A7"), Color(hex: "4CAF50")],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.45).offset(y: -size * 0.18)
            PetEyes(size: size, happiness: happiness, color: Color(hex: "1B5E20"))
                .offset(y: -size * 0.22)
        }
        .frame(width: size, height: size)
    }
}

struct PlantPet: View {
    let size: CGFloat; let happiness: Double
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4).fill(
                LinearGradient(colors: [Color(hex: "8B4513"), Color(hex: "5D2E0C")],
                               startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.4, height: size * 0.28).offset(y: size * 0.32)
            Capsule().fill(Color(hex: "388E3C"))
                .frame(width: size * 0.07, height: size * 0.45).offset(y: size * 0.1)
            ForEach(0..<3, id: \.self) { i in
                Ellipse().fill(Color(hex: i % 2 == 0 ? "66BB6A" : "43A047"))
                    .frame(width: size * 0.35, height: size * 0.18)
                    .rotationEffect(.degrees(Double(i - 1) * 40))
                    .offset(x: CGFloat(i - 1) * size * 0.22, y: CGFloat(i) * (-size * 0.06) - size * 0.05)
            }
            Circle()
                .fill(LinearGradient(colors: [Color(hex: "C8E6C9"), Color(hex: "81C784")],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.38).offset(y: -size * 0.2)
            PetEyes(size: size, happiness: happiness, color: Color(hex: "2E7D32"))
                .offset(y: -size * 0.23)
        }
        .frame(width: size, height: size)
    }
}

struct TreePet: View {
    let size: CGFloat; let happiness: Double
    var body: some View {
        ZStack {
            Capsule().fill(Color(hex: "6D4C41"))
                .frame(width: size * 0.12, height: size * 0.45).offset(y: size * 0.22)
            Circle().fill(Color(hex: "2E7D32").opacity(0.8))
                .frame(width: size * 0.7).offset(y: -size * 0.05)
            Circle().fill(Color(hex: "43A047").opacity(0.9))
                .frame(width: size * 0.55).offset(y: -size * 0.12)
            Circle().fill(Color(hex: "66BB6A"))
                .frame(width: size * 0.42).offset(y: -size * 0.22)
            PetEyes(size: size, happiness: happiness, color: .white)
                .offset(y: -size * 0.17)
        }
        .frame(width: size, height: size)
    }
}

struct BloomPet: View {
    let size: CGFloat; let happiness: Double
    @State private var petalRot = 0.0
    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                Ellipse()
                    .fill(LinearGradient(colors: [Color(hex: "F48FB1"), Color(hex: "E91E63")],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: size * 0.22, height: size * 0.38)
                    .offset(y: -size * 0.28)
                    .rotationEffect(.degrees(Double(i) * 45 + petalRot))
                    .opacity(0.85)
            }
            Circle()
                .fill(LinearGradient(colors: [Color(hex: "FFD54F"), Color(hex: "D4AF37")],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.45)
            PetEyes(size: size, happiness: happiness, color: Color(hex: "5D2E0C"))
                .offset(y: -size * 0.04)
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) { petalRot = 360 }
        }
    }
}

// MARK: ─────────────────── DRAGON FAMILY ───────────────────

struct DragonEggPet: View {
    let size: CGFloat; let happiness: Double
    @State private var glowEyes = false

    var body: some View {
        ZStack {
            // Egg body
            Ellipse()
                .fill(LinearGradient(
                    colors: [Color(hex: "9C6FD6"), Color(hex: "4A3080")],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size * 0.55, height: size * 0.7)

            // Speckles
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: size * 0.05)
                    .offset(x: CGFloat([-0.15, 0.12, -0.08, 0.18, -0.2][i]) * size,
                            y: CGFloat([-0.2, 0.05, 0.22, -0.1, 0.15][i]) * size)
            }

            // Crack
            Path { p in
                p.move(to: CGPoint(x: 0, y: -size * 0.1))
                p.addLine(to: CGPoint(x: size * 0.05, y: 0))
                p.addLine(to: CGPoint(x: -size * 0.03, y: size * 0.1))
            }
            .stroke(Color(hex: "FFD700").opacity(0.6), lineWidth: 1.5)

            // Glowing eyes peeking through crack
            HStack(spacing: size * 0.14) {
                Circle()
                    .fill(Color(hex: "FF6B00"))
                    .frame(width: size * 0.07)
                    .shadow(color: Color(hex: "FF6B00").opacity(glowEyes ? 0.9 : 0.3), radius: 4)
                Circle()
                    .fill(Color(hex: "FF6B00"))
                    .frame(width: size * 0.07)
                    .shadow(color: Color(hex: "FF6B00").opacity(glowEyes ? 0.9 : 0.3), radius: 4)
            }
            .offset(y: size * 0.05)
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: glowEyes)
        }
        .frame(width: size, height: size)
        .onAppear { glowEyes = true }
    }
}

struct DragonHatchlingPet: View {
    let size: CGFloat; let happiness: Double
    var body: some View {
        ZStack {
            // Broken egg bottom
            Ellipse()
                .fill(LinearGradient(
                    colors: [Color(hex: "9C6FD6"), Color(hex: "4A3080")],
                    startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.5, height: size * 0.32)
                .offset(y: size * 0.3)
                .mask(Rectangle().offset(y: size * 0.25))

            // Eggshell pieces
            ForEach([(-0.18, 0.18, -25.0), (0.2, 0.15, 20.0)], id: \.0) { x, y, rot in
                Ellipse()
                    .fill(Color(hex: "9C6FD6"))
                    .frame(width: size * 0.18, height: size * 0.12)
                    .rotationEffect(.degrees(rot))
                    .offset(x: x * size, y: y * size)
            }

            // Dragon head
            Circle()
                .fill(LinearGradient(colors: [Color(hex: "4CAF50"), Color(hex: "2E7D32")],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.46)
                .offset(y: -size * 0.08)

            // Horns
            ForEach([-1, 1], id: \.self) { side in
                Ellipse()
                    .fill(Color(hex: "1B5E20"))
                    .frame(width: size * 0.08, height: size * 0.16)
                    .rotationEffect(.degrees(Double(side) * 15))
                    .offset(x: CGFloat(side) * size * 0.14, y: -size * 0.28)
            }

            // Eyes
            PetEyes(size: size, happiness: happiness, color: Color(hex: "FFD700"))
                .offset(y: -size * 0.1)
        }
        .frame(width: size, height: size)
    }
}

struct BabyDragonPet: View {
    let size: CGFloat; let happiness: Double
    var body: some View {
        ZStack {
            // Wings (behind body)
            ForEach([-1, 1], id: \.self) { side in
                Ellipse()
                    .fill(Color(hex: "80CBC4").opacity(0.7))
                    .frame(width: size * 0.28, height: size * 0.36)
                    .rotationEffect(.degrees(Double(side) * 30))
                    .offset(x: CGFloat(side) * size * 0.33, y: size * 0.08)
            }

            // Body
            Ellipse()
                .fill(LinearGradient(colors: [Color(hex: "4DB6AC"), Color(hex: "00897B")],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.52, height: size * 0.58)
                .offset(y: size * 0.1)

            // Tail
            Capsule()
                .fill(Color(hex: "00796B"))
                .frame(width: size * 0.1, height: size * 0.28)
                .rotationEffect(.degrees(40))
                .offset(x: size * 0.28, y: size * 0.3)

            // Head
            Circle()
                .fill(LinearGradient(colors: [Color(hex: "80CBC4"), Color(hex: "4DB6AC")],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.4)
                .offset(y: -size * 0.2)

            // Horns
            ForEach([-1, 1], id: \.self) { side in
                Ellipse()
                    .fill(Color(hex: "004D40"))
                    .frame(width: size * 0.07, height: size * 0.14)
                    .rotationEffect(.degrees(Double(side) * 12))
                    .offset(x: CGFloat(side) * size * 0.11, y: -size * 0.37)
            }

            // Eyes
            PetEyes(size: size, happiness: happiness, color: Color(hex: "FF8F00"))
                .offset(y: -size * 0.21)

            // Tiny fire puff
            if happiness > 0.5 {
                Circle()
                    .fill(Color(hex: "FF6B00").opacity(0.7))
                    .frame(width: size * 0.12)
                    .blur(radius: 3)
                    .offset(x: size * 0.02, y: -size * 0.13)
            }
        }
        .frame(width: size, height: size)
    }
}

struct DragonPet: View {
    let size: CGFloat; let happiness: Double
    var body: some View {
        ZStack {
            // Large wings
            ForEach([-1, 1], id: \.self) { side in
                ZStack {
                    Ellipse()
                        .fill(Color(hex: "004D40").opacity(0.85))
                        .frame(width: size * 0.4, height: size * 0.55)
                    // Wing vein
                    Capsule()
                        .fill(Color(hex: "00897B").opacity(0.5))
                        .frame(width: size * 0.03, height: size * 0.4)
                        .rotationEffect(.degrees(Double(side) * 20))
                }
                .rotationEffect(.degrees(Double(side) * 25))
                .offset(x: CGFloat(side) * size * 0.42, y: -size * 0.05)
            }

            // Body
            Ellipse()
                .fill(LinearGradient(colors: [Color(hex: "00897B"), Color(hex: "004D40")],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.5, height: size * 0.6)
                .offset(y: size * 0.1)

            // Tail
            Capsule()
                .fill(Color(hex: "00695C"))
                .frame(width: size * 0.1, height: size * 0.32)
                .rotationEffect(.degrees(45))
                .offset(x: size * 0.3, y: size * 0.35)

            // Head
            Circle()
                .fill(LinearGradient(colors: [Color(hex: "26A69A"), Color(hex: "00897B")],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.44)
                .offset(y: -size * 0.22)

            // Horns
            ForEach([-1, 1], id: \.self) { side in
                Ellipse()
                    .fill(Color(hex: "1B5E20"))
                    .frame(width: size * 0.09, height: size * 0.2)
                    .rotationEffect(.degrees(Double(side) * 14))
                    .offset(x: CGFloat(side) * size * 0.14, y: -size * 0.4)
            }

            // Glowing eyes
            HStack(spacing: size * 0.12) {
                ForEach(0..<2, id: \.self) { _ in
                    Circle()
                        .fill(happiness > 0.5 ? Color(hex: "FFD700") : Color(hex: "FF3D00"))
                        .frame(width: size * 0.09)
                        .shadow(color: (happiness > 0.5 ? Color(hex: "FFD700") : Color(hex: "FF3D00")).opacity(0.7), radius: 5)
                }
            }
            .offset(y: -size * 0.24)

            // Fire breath
            FireBreath(size: size)
                .offset(y: -size * 0.15)
        }
        .frame(width: size, height: size)
    }
}

private struct FireBreath: View {
    let size: CGFloat
    @State private var flicker = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "FF6B00").opacity(flicker ? 0.55 : 0.35))
                .frame(width: size * 0.22, height: size * 0.16)
                .blur(radius: 6)
                .offset(x: size * 0.33)
            Circle()
                .fill(Color(hex: "FFEB3B").opacity(flicker ? 0.4 : 0.2))
                .frame(width: size * 0.12)
                .blur(radius: 4)
                .offset(x: size * 0.38)
        }
        .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true), value: flicker)
        .onAppear { flicker = true }
    }
}

struct AncientDragonPet: View {
    let size: CGFloat; let happiness: Double
    @State private var auraScale = false

    var body: some View {
        ZStack {
            // Aura rings
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(Color(hex: "FFD700").opacity(0.08 - Double(i) * 0.02), lineWidth: 1.5)
                    .frame(width: size * (0.9 + CGFloat(i) * 0.18))
                    .scaleEffect(auraScale ? 1.05 : 0.95)
                    .animation(.easeInOut(duration: 1.8 + Double(i) * 0.3).repeatForever(autoreverses: true), value: auraScale)
            }

            // Grand wings
            ForEach([-1, 1], id: \.self) { side in
                ZStack {
                    Ellipse()
                        .fill(LinearGradient(
                            colors: [Color(hex: "B8860B"), Color(hex: "4A3000")],
                            startPoint: .top, endPoint: .bottom))
                        .frame(width: size * 0.46, height: size * 0.65)
                    // Wing membrane veins
                    ForEach(0..<3, id: \.self) { v in
                        Capsule()
                            .fill(Color(hex: "FFD700").opacity(0.25))
                            .frame(width: size * 0.025, height: size * (0.3 - CGFloat(v) * 0.06))
                            .rotationEffect(.degrees(Double(side) * Double(v - 1) * 12))
                    }
                }
                .rotationEffect(.degrees(Double(side) * 30))
                .offset(x: CGFloat(side) * size * 0.46, y: -size * 0.04)
            }

            // Body
            Ellipse()
                .fill(LinearGradient(
                    colors: [Color(hex: "D4AF37"), Color(hex: "7B5800")],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size * 0.52, height: size * 0.6)
                .offset(y: size * 0.1)
                .shadow(color: Color(hex: "FFD700").opacity(0.3), radius: 8)

            // Scales hint
            ForEach(0..<4, id: \.self) { i in
                Ellipse()
                    .fill(Color(hex: "FFD700").opacity(0.12))
                    .frame(width: size * 0.12, height: size * 0.08)
                    .offset(x: CGFloat(i % 2 == 0 ? -1 : 1) * size * 0.1,
                            y: size * (0.05 + CGFloat(i) * 0.07))
            }

            // Neck
            Capsule()
                .fill(Color(hex: "B8860B"))
                .frame(width: size * 0.18, height: size * 0.22)
                .offset(y: -size * 0.24)

            // Head
            Circle()
                .fill(LinearGradient(
                    colors: [Color(hex: "FFD54F"), Color(hex: "D4AF37")],
                    startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.46)
                .offset(y: -size * 0.32)
                .shadow(color: Color(hex: "FFD700").opacity(0.45), radius: 10)

            // Crown
            HStack(spacing: size * 0.04) {
                ForEach(0..<5, id: \.self) { i in
                    Capsule()
                        .fill(LinearGradient(
                            colors: [Color(hex: "FFD700"), Color(hex: "FF8F00")],
                            startPoint: .bottom, endPoint: .top))
                        .frame(width: size * 0.04,
                               height: size * (i == 2 ? 0.14 : (i == 1 || i == 3 ? 0.1 : 0.07)))
                }
            }
            .offset(y: -size * 0.5)

            // Ancient horns
            ForEach([-1, 1], id: \.self) { side in
                Ellipse()
                    .fill(LinearGradient(colors: [Color(hex: "FFD700"), Color(hex: "8B6500")],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: size * 0.08, height: size * 0.22)
                    .rotationEffect(.degrees(Double(side) * 16))
                    .offset(x: CGFloat(side) * size * 0.15, y: -size * 0.44)
            }

            // Legendary glowing eyes
            HStack(spacing: size * 0.14) {
                ForEach(0..<2, id: \.self) { _ in
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: size * 0.1)
                        Circle()
                            .fill(Color(hex: "FF6B00"))
                            .frame(width: size * 0.07)
                    }
                    .shadow(color: Color(hex: "FF6B00").opacity(0.8), radius: 6)
                }
            }
            .offset(y: -size * 0.34)
        }
        .frame(width: size, height: size)
        .onAppear { auraScale = true }
    }
}

// MARK: ─────────────────── CLOUD FAMILY ───────────────────

struct MistPet: View {
    let size: CGFloat; let happiness: Double
    @State private var drift = false

    private let offsets: [(CGFloat, CGFloat)] = [
        (-0.18, -0.1), (0.15, -0.15), (-0.05, 0.12), (0.2, 0.08), (0, -0.05)
    ]
    private let sizes: [CGFloat] = [0.22, 0.18, 0.25, 0.16, 0.2]

    var body: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .fill(Color(hex: "CFD8DC").opacity(0.35))
                    .frame(width: size * sizes[i])
                    .blur(radius: 6)
                    .offset(x: offsets[i].0 * size + (drift ? size * 0.03 : 0),
                            y: offsets[i].1 * size)
                    .animation(.easeInOut(duration: 2.0 + Double(i) * 0.4).repeatForever(autoreverses: true),
                               value: drift)
            }
            // tiny face in the center mist
            PetEyes(size: size * 0.7, happiness: happiness, color: Color(hex: "78909C"))
                .opacity(0.5)
        }
        .frame(width: size, height: size)
        .onAppear { drift = true }
    }
}

struct CloudPet: View {
    let size: CGFloat; let happiness: Double
    var body: some View {
        ZStack {
            // Fluffy cloud body
            cloudShape
            // Face
            PetEyes(size: size, happiness: happiness, color: Color(hex: "5C8FA8"))
                .offset(y: size * 0.02)
            // Smile
            if happiness >= 0.3 {
                Path { p in
                    p.addArc(center: .zero, radius: size * 0.08,
                             startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                }
                .stroke(Color(hex: "5C8FA8"), lineWidth: 2)
                .offset(y: size * 0.1)
            }
        }
        .frame(width: size, height: size)
    }

    private var cloudShape: some View {
        ZStack {
            Ellipse()
                .fill(cloudGradient)
                .frame(width: size * 0.65, height: size * 0.4)
            Circle().fill(cloudGradient).frame(width: size * 0.38).offset(x: -size * 0.14, y: -size * 0.14)
            Circle().fill(cloudGradient).frame(width: size * 0.32).offset(x: size * 0.14, y: -size * 0.14)
            Circle().fill(cloudGradient).frame(width: size * 0.26).offset(x: -size * 0.28, y: -size * 0.02)
            Circle().fill(cloudGradient).frame(width: size * 0.24).offset(x: size * 0.28, y: -size * 0.02)
        }
    }
    private var cloudGradient: LinearGradient {
        LinearGradient(colors: [Color(hex: "E8F4FD"), Color(hex: "B3D9F5")],
                       startPoint: .top, endPoint: .bottom)
    }
}

struct RainCloudPet: View {
    let size: CGFloat; let happiness: Double
    @State private var dropOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Cloud body (darker)
            ZStack {
                Ellipse()
                    .fill(cloudGrad).frame(width: size * 0.65, height: size * 0.38)
                Circle().fill(cloudGrad).frame(width: size * 0.36).offset(x: -size * 0.14, y: -size * 0.13)
                Circle().fill(cloudGrad).frame(width: size * 0.3).offset(x: size * 0.14, y: -size * 0.13)
                Circle().fill(cloudGrad).frame(width: size * 0.24).offset(x: -size * 0.28, y: -size * 0.02)
            }

            // Grumpy eyebrows
            HStack(spacing: size * 0.14) {
                Capsule().fill(Color(hex: "546E7A")).frame(width: size * 0.1, height: size * 0.02)
                    .rotationEffect(.degrees(8))
                Capsule().fill(Color(hex: "546E7A")).frame(width: size * 0.1, height: size * 0.02)
                    .rotationEffect(.degrees(-8))
            }
            .offset(y: -size * 0.03)

            PetEyes(size: size, happiness: happiness, color: Color(hex: "455A64"))
                .offset(y: size * 0.05)

            // Rain drops
            HStack(spacing: size * 0.12) {
                ForEach(0..<3, id: \.self) { i in
                    RainDrop(size: size, delay: Double(i) * 0.3)
                }
            }
            .offset(y: size * 0.36)
        }
        .frame(width: size, height: size)
    }
    private var cloudGrad: LinearGradient {
        LinearGradient(colors: [Color(hex: "90A4AE"), Color(hex: "607D8B")],
                       startPoint: .top, endPoint: .bottom)
    }
}

private struct RainDrop: View {
    let size: CGFloat; let delay: Double
    @State private var falling = false

    var body: some View {
        Capsule()
            .fill(Color(hex: "64B5F6").opacity(0.8))
            .frame(width: size * 0.04, height: size * 0.12)
            .offset(y: falling ? size * 0.06 : 0)
            .opacity(falling ? 0 : 1)
            .animation(.easeIn(duration: 0.7).delay(delay).repeatForever(autoreverses: false), value: falling)
            .onAppear { falling = true }
    }
}

struct StormPet: View {
    let size: CGFloat; let happiness: Double
    @State private var flashBolt = false

    var body: some View {
        ZStack {
            // Dark storm cloud
            ZStack {
                Ellipse()
                    .fill(stormGrad).frame(width: size * 0.7, height: size * 0.4)
                Circle().fill(stormGrad).frame(width: size * 0.38).offset(x: -size * 0.15, y: -size * 0.14)
                Circle().fill(stormGrad).frame(width: size * 0.32).offset(x: size * 0.15, y: -size * 0.14)
                Circle().fill(stormGrad).frame(width: size * 0.26).offset(x: -size * 0.3, y: -size * 0.02)
                Circle().fill(stormGrad).frame(width: size * 0.24).offset(x: size * 0.3, y: -size * 0.02)
            }

            // Electric eyes
            HStack(spacing: size * 0.12) {
                ForEach(0..<2, id: \.self) { _ in
                    Circle()
                        .fill(Color(hex: "FFEB3B"))
                        .frame(width: size * 0.08)
                        .shadow(color: Color(hex: "FFEB3B").opacity(0.8), radius: 4)
                }
            }
            .offset(y: size * 0.04)

            // Lightning bolt
            LightningBolt(size: size)
                .offset(y: size * 0.24)
                .opacity(flashBolt ? 1 : 0.6)
                .animation(.easeInOut(duration: 0.25).repeatForever(autoreverses: true), value: flashBolt)

            // Rain drops
            HStack(spacing: size * 0.1) {
                ForEach(0..<4, id: \.self) { i in
                    RainDrop(size: size, delay: Double(i) * 0.2)
                }
            }
            .offset(x: -size * 0.05, y: size * 0.42)
        }
        .frame(width: size, height: size)
        .onAppear { flashBolt = true }
    }
    private var stormGrad: LinearGradient {
        LinearGradient(colors: [Color(hex: "546E7A"), Color(hex: "263238")],
                       startPoint: .top, endPoint: .bottom)
    }
}

private struct LightningBolt: View {
    let size: CGFloat
    var body: some View {
        Path { p in
            p.move(to: CGPoint(x: size * 0.04, y: 0))
            p.addLine(to: CGPoint(x: -size * 0.02, y: size * 0.1))
            p.addLine(to: CGPoint(x: size * 0.02, y: size * 0.1))
            p.addLine(to: CGPoint(x: -size * 0.05, y: size * 0.22))
        }
        .stroke(Color(hex: "FFEB3B"), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        .shadow(color: Color(hex: "FFEB3B").opacity(0.7), radius: 4)
    }
}

struct RainbowPet: View {
    let size: CGFloat; let happiness: Double
    @State private var shimmer = false

    private let rainbowColors: [Color] = [
        Color(hex: "FF5252"), Color(hex: "FF9800"),
        Color(hex: "FFEB3B"), Color(hex: "4CAF50"),
        Color(hex: "2196F3"), Color(hex: "9C27B0")
    ]

    var body: some View {
        ZStack {
            // Rainbow arcs
            ForEach(Array(rainbowColors.enumerated()), id: \.offset) { i, color in
                let arcSize = size * (0.82 - CGFloat(i) * 0.1)
                Path { p in
                    p.addArc(center: CGPoint(x: 0, y: size * 0.12),
                             radius: arcSize * 0.5,
                             startAngle: .degrees(180),
                             endAngle: .degrees(0),
                             clockwise: true)
                }
                .stroke(color.opacity(shimmer ? 0.9 : 0.7), lineWidth: 3.5)
            }

            // Cloud base
            ZStack {
                Ellipse()
                    .fill(cloudGrad).frame(width: size * 0.62, height: size * 0.36)
                Circle().fill(cloudGrad).frame(width: size * 0.34).offset(x: -size * 0.13, y: -size * 0.13)
                Circle().fill(cloudGrad).frame(width: size * 0.28).offset(x: size * 0.13, y: -size * 0.13)
                Circle().fill(cloudGrad).frame(width: size * 0.22).offset(x: -size * 0.26)
            }
            .offset(y: size * 0.16)

            // Happy glowing face
            PetEyes(size: size, happiness: 1.0, color: Color(hex: "5C8FA8"))
                .offset(y: size * 0.18)

            Path { p in
                p.addArc(center: .zero, radius: size * 0.07,
                         startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
            }
            .stroke(Color(hex: "5C8FA8"), lineWidth: 2)
            .offset(y: size * 0.27)

            // Sparkles
            ForEach([(-0.32, -0.15), (0.3, -0.2), (-0.25, 0.1), (0.28, 0.08)], id: \.0) { x, y in
                Text("✦")
                    .font(.system(size: size * 0.1))
                    .foregroundStyle(.yellow)
                    .opacity(shimmer ? 1 : 0.3)
                    .offset(x: x * size, y: y * size)
                    .animation(.easeInOut(duration: 1.0 + Double.random(in: 0...0.5)).repeatForever(autoreverses: true),
                               value: shimmer)
            }
        }
        .frame(width: size, height: size)
        .onAppear { shimmer = true }
    }
    private var cloudGrad: LinearGradient {
        LinearGradient(colors: [Color.white, Color(hex: "E3F2FD")],
                       startPoint: .top, endPoint: .bottom)
    }
}
