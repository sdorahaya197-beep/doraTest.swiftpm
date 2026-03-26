import SwiftUI
import SwiftData

struct RaceMemoView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Race.date, order: .reverse) private var races: [Race]
    @State private var selectedRace: Race?
    @State private var showAddHorse = false

    var body: some View {
        NavigationStack {
            List {
                // レース選択
                Section {
                    Picker("レース", selection: $selectedRace) {
                        Text("-- 選択してください --").tag(nil as Race?)
                        ForEach(races) { race in
                            Text(race.displayName).tag(race as Race?)
                        }
                    }
                }

                if let race = selectedRace {
                    Section("レース情報") {
                        RaceInfoRows(race: race)
                    }
                    Section("出走馬") {
                        ForEach(race.horses.sorted(by: { $0.horseNumber < $1.horseNumber || ($0.horseNumber == $1.horseNumber && $0.createdAt < $1.createdAt) })) { horse in
                            HorseRow(horse: horse)
                        }
                        .onDelete { indexSet in
                            let sorted = race.horses.sorted(by: { $0.horseNumber < $1.horseNumber || ($0.horseNumber == $1.horseNumber && $0.createdAt < $1.createdAt) })
                            for i in indexSet { modelContext.delete(sorted[i]) }
                        }
                        Button { showAddHorse = true } label: {
                            Label("馬を追加", systemImage: "plus")
                        }
                    }
                } else {
                    Section {
                        Text("右上の「＋」で新規レースを作成してください")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("出走馬メモ帳")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { addNewRace() } label: { Image(systemName: "plus") }
                }
                if selectedRace != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(role: .destructive) {
                            if let race = selectedRace { deleteRace(race) }
                        } label: { Image(systemName: "trash") }
                        .tint(.red)
                    }
                }
            }
            .sheet(isPresented: $showAddHorse) {
                if let race = selectedRace { AddHorseSheet(race: race) }
            }
            .onAppear {
                if selectedRace == nil { selectedRace = races.first }
            }
            .onChange(of: races) { _, newRaces in
                if selectedRace == nil || !newRaces.contains(where: { $0.id == selectedRace?.id }) {
                    selectedRace = newRaces.first
                }
            }
        }
    }

    func addNewRace() {
        let race = Race()
        modelContext.insert(race)
        selectedRace = race
    }

    func deleteRace(_ race: Race) {
        selectedRace = nil
        modelContext.delete(race)
    }
}

// MARK: - レース情報フォーム
struct RaceInfoRows: View {
    @Bindable var race: Race

    var body: some View {
        // レース番号
        HStack {
            Text("レース番号")
                .foregroundStyle(.secondary)
            Spacer()
            Button { if race.raceNumber > 0 { race.raceNumber -= 1 } } label: {
                Image(systemName: "minus.circle")
            }
            .buttonStyle(.plain)
            Text(race.raceNumber > 0 ? "第\(race.raceNumber)R" : "未設定")
                .frame(width: 64)
                .multilineTextAlignment(.center)
                .monospacedDigit()
            Button { if race.raceNumber < 12 { race.raceNumber += 1 } } label: {
                Image(systemName: "plus.circle")
            }
            .buttonStyle(.plain)
        }

        // レース名
        TextField("レース名（例: 日本ダービー）", text: $race.name)

        // 競馬場
        VStack(alignment: .leading, spacing: 8) {
            TextField("競馬場", text: $race.venue)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(jraVenues, id: \.self) { v in
                        Button(v) { race.venue = v }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .tint(race.venue == v ? .blue : .secondary)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(.vertical, 4)

        // 日付
        VStack(alignment: .leading, spacing: 8) {
            DatePicker("日付", selection: $race.date, displayedComponents: .date)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(weekendDates(), id: \.self) { date in
                        Button(shortDateStr(date)) { race.date = date }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .tint(Calendar.current.isDate(race.date, inSameDayAs: date) ? .blue : .secondary)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(.vertical, 4)
    }

    func weekendDates() -> [Date] {
        var result: [Date] = []
        let cal = Calendar.current
        for i in 0...21 {
            if let d = cal.date(byAdding: .day, value: i, to: .now) {
                let wd = cal.component(.weekday, from: d)
                if wd == 7 || wd == 1 { result.append(d) }
                if result.count == 4 { break }
            }
        }
        return result
    }

    func shortDateStr(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "M/d(E)"
        f.locale = Locale(identifier: "ja_JP")
        return f.string(from: date)
    }
}

// MARK: - 馬の行
struct HorseRow: View {
    @Bindable var horse: Horse

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                // 馬番バッジ
                if horse.horseNumber > 0 {
                    Text("\(horse.horseNumber)")
                        .font(.caption.bold())
                        .frame(width: 24, height: 24)
                        .background(frameColor(horse.horseNumber))
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                }
                Picker("印", selection: $horse.mark) {
                    ForEach(horseMark, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented)
                TextField("馬名", text: $horse.name)
                    .font(.headline)
            }
            HStack {
                TextField("メモ", text: $horse.memo)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("着順", text: $horse.result)
                    .font(.subheadline.bold())
                    .foregroundStyle(.orange)
                    .frame(width: 60)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.vertical, 2)
    }

    func frameColor(_ number: Int) -> Color {
        let colors: [Color] = [.white, .black, .red, .blue, .yellow, .green, .orange, .pink]
        let frame = (number - 1) / 2
        return frame < colors.count ? colors[frame] : .gray
    }
}

// MARK: - 馬追加シート
struct AddHorseSheet: View {
    @Environment(\.dismiss) private var dismiss
    let race: Race

    @State private var name = ""
    @State private var mark = "▲"
    @State private var memo = ""
    @State private var result = ""
    @State private var horseNumber = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    // 馬番
                    HStack {
                        Text("馬番")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button { if horseNumber > 0 { horseNumber -= 1 } } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.plain)
                        Text(horseNumber > 0 ? "\(horseNumber)番" : "未設定")
                            .frame(width: 56)
                            .multilineTextAlignment(.center)
                            .monospacedDigit()
                        Button { if horseNumber < 18 { horseNumber += 1 } } label: {
                            Image(systemName: "plus.circle")
                        }
                        .buttonStyle(.plain)
                    }
                    TextField("馬名", text: $name)
                    Picker("予想印", selection: $mark) {
                        ForEach(horseMark, id: \.self) { Text($0).tag($0) }
                    }
                }
                Section("メモ・結果") {
                    TextField("メモ", text: $memo, axis: .vertical)
                        .lineLimit(3)
                    TextField("着順（例: 1着）", text: $result)
                }
            }
            .navigationTitle("馬を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        race.horses.append(
                            Horse(name: name, mark: mark, memo: memo, result: result, horseNumber: horseNumber)
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
