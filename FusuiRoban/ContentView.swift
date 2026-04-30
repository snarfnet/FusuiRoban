import SwiftUI
import CoreMotion
import CoreLocation

struct ContentView: View {
    @StateObject private var compass = CompassManager()
    @State private var birthYear: String = ""
    @State private var showBirthInput = false
    @State private var kua: Int? = nil

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex:"0d0a00"), Color(hex:"1a0f00"), Color(hex:"2d1500")],
                          startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("風水羅盤")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color(hex:"FFD700"))
                    .padding(.top, 50)
                    .shadow(color: Color(hex:"FF6600").opacity(0.8), radius: 8)

                Spacer()

                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(colors: [Color(hex:"FFD700"), Color(hex:"CC8800"), Color(hex:"FFD700")],
                                          startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 4)
                        .frame(width: 300, height: 300)

                    ForEach(0..<8, id: \.self) { i in
                        let angle = Double(i) * 45.0
                        let dir = directions[i]
                        VStack(spacing: 2) {
                            Text(dir.kanji)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(directionColor(i))
                            Text(dir.degree)
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex:"AA8833"))
                        }
                        .rotationEffect(.degrees(angle))
                        .offset(y: -120)
                        .rotationEffect(.degrees(-angle))
                    }

                    Circle()
                        .fill(Color(hex:"1a0f00"))
                        .frame(width: 200, height: 200)
                        .overlay(Circle().stroke(Color(hex:"FFD700").opacity(0.4), lineWidth: 1))

                    CompassNeedle()
                        .rotationEffect(.degrees(-compass.heading))

                    Circle()
                        .fill(Color(hex:"FFD700"))
                        .frame(width: 12, height: 12)
                }
                .rotationEffect(.degrees(compass.heading))
                .animation(.easeOut(duration: 0.3), value: compass.heading)

                Spacer().frame(height: 30)

                DirectionInfoCard(heading: compass.heading, kua: kua)

                Spacer().frame(height: 20)

                Button(action: { showBirthInput.toggle() }) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                        Text(kua == nil ? "生年を入力して吉方位を確認" : "本命卦: \(kua!) — タップして変更")
                    }
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex:"FFD700").opacity(0.8))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(hex:"FFD700").opacity(0.1))
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex:"FFD700").opacity(0.3), lineWidth: 1))
                }

                Spacer()

                BannerAdView(adUnitID: "ca-app-pub-9404799280370656/2230738824")
                    .frame(height: 50)
            }
        }
        .sheet(isPresented: $showBirthInput) {
            BirthYearInput(birthYear: $birthYear, kua: $kua, isPresented: $showBirthInput)
        }
    }

    let directions: [(kanji: String, degree: String)] = [
        (kanji: "北", degree: "0°"),
        (kanji: "北東", degree: "45°"),
        (kanji: "東", degree: "90°"),
        (kanji: "南東", degree: "135°"),
        (kanji: "南", degree: "180°"),
        (kanji: "南西", degree: "225°"),
        (kanji: "西", degree: "270°"),
        (kanji: "北西", degree: "315°"),
    ]

    func directionColor(_ i: Int) -> Color {
        switch i {
        case 0: return Color(hex:"6699FF")
        case 2: return Color(hex:"33CC66")
        case 4: return Color(hex:"FF4444")
        case 6: return Color(hex:"FFFFFF")
        default: return Color(hex:"FFD700")
        }
    }
}

struct DirectionData {
    let name: String; let element: String; let meaning: String
}

let directionData: [DirectionData] = [
    DirectionData(name: "北 (坎)", element: "水・黒", meaning: "事業運・知恵・忍耐"),
    DirectionData(name: "北東 (艮)", element: "土・白", meaning: "変化・転機・山の気"),
    DirectionData(name: "東 (震)", element: "木・青", meaning: "成長・発展・若さ"),
    DirectionData(name: "南東 (巽)", element: "木・緑", meaning: "財運・縁・風の気"),
    DirectionData(name: "南 (離)", element: "火・赤", meaning: "名誉・情熱・美"),
    DirectionData(name: "南西 (坤)", element: "土・黄", meaning: "家庭運・母・大地"),
    DirectionData(name: "西 (兌)", element: "金・白", meaning: "金運・喜び・収穫"),
    DirectionData(name: "北西 (乾)", element: "金・銀", meaning: "天・リーダー・権威"),
]

func kuaFortune(kua: Int, dirIndex: Int) -> String {
    let lucky: [Int: [Int]] = [
        1: [2, 3, 5, 6], 2: [0, 4, 6, 7], 3: [0, 1, 4, 7],
        4: [0, 3, 5, 6], 6: [1, 4, 5, 7], 7: [1, 2, 4, 6],
        8: [2, 3, 6, 7], 9: [0, 2, 3, 5]
    ]
    guard let dirs = lucky[kua] else { return "" }
    if dirs.contains(dirIndex) { return "✦ 吉方位！あなたに良い気が流れています" }
    return "✧ 凶方位。長時間の滞在は避けましょう"
}

struct DirectionInfoCard: View {
    let heading: Double
    let kua: Int?

    var currentIdx: Int { Int((heading + 22.5) / 45.0) % 8 }
    var current: DirectionData { directionData[currentIdx] }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                VStack {
                    Text(String(format: "%.0f°", heading))
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex:"FFD700"))
                    Text(current.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                Rectangle().fill(Color(hex:"FFD700").opacity(0.3)).frame(width: 1, height: 50)
                VStack(alignment: .leading, spacing: 4) {
                    Text(current.element)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex:"FF9900"))
                    Text(current.meaning)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex:"CCAA55"))
                        .lineLimit(2)
                }
            }
            if let k = kua {
                let info = kuaFortune(kua: k, dirIndex: currentIdx)
                if !info.isEmpty {
                    Text(info)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(info.contains("吉") ? Color(hex:"00FF88") : Color(hex:"FF6666"))
                        .padding(.horizontal, 16).padding(.vertical, 6)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color(hex:"1a0f00").opacity(0.8))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex:"FFD700").opacity(0.3), lineWidth: 1))
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
}

struct BirthYearInput: View {
    @Binding var birthYear: String
    @Binding var kua: Int?
    @Binding var isPresented: Bool

    var calcKua: Int? {
        guard let year = Int(birthYear), year > 1900 && year < 2100 else { return nil }
        var sum = (year % 100 / 10) + (year % 10)
        while sum >= 10 { sum = sum / 10 + sum % 10 }
        let k = 11 - sum
        return k == 5 ? 2 : (k > 9 ? k - 9 : k)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex:"0d0a00").ignoresSafeArea()
                VStack(spacing: 24) {
                    Text("生まれ年を入力")
                        .font(.title2).bold().foregroundColor(Color(hex:"FFD700"))
                    TextField("例: 1985", text: $birthYear)
                        .keyboardType(.numberPad)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex:"FFD700").opacity(0.4)))
                        .padding(.horizontal, 40)
                    if let k = calcKua {
                        Text("本命卦: \(k)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(Color(hex:"FFD700"))
                    }
                    Button("決定") {
                        kua = calcKua
                        isPresented = false
                    }
                    .font(.headline).foregroundColor(.black)
                    .padding(.horizontal, 40).padding(.vertical, 14)
                    .background(Color(hex:"FFD700"))
                    .cornerRadius(12)
                    Spacer()
                }
                .padding(.top, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") { isPresented = false }.foregroundColor(Color(hex:"FFD700"))
                }
            }
        }
    }
}

struct CompassNeedle: View {
    var body: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 0, y: -90))
                p.addLine(to: CGPoint(x: -8, y: 0))
                p.addLine(to: CGPoint(x: 8, y: 0))
                p.closeSubpath()
            }.fill(Color(hex:"FF3333"))
            Path { p in
                p.move(to: CGPoint(x: 0, y: 90))
                p.addLine(to: CGPoint(x: -8, y: 0))
                p.addLine(to: CGPoint(x: 8, y: 0))
                p.closeSubpath()
            }.fill(Color(hex:"CCCCCC"))
        }
    }
}

class CompassManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var heading: Double = 0
    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async {
            self.heading = newHeading.magneticHeading
        }
    }
}

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
