import SwiftUI
import SwiftData

struct ContentView: View {
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
                    // レース情報
                    Section("レース情報") {
                        RaceInfoRows(race: race)
                    }

                    // 出走馬一覧
                    Section("出走馬") {
                        ForEach(race.horses.sorted(by: { $0.createdAt < $1.createdAt })) { horse in
                            HorseRow(horse: horse)
                        }
                        .onDelete { indexSet in
                            let sorted = race.horses.sorted(by: { $0.createdAt < $1.createdAt })
                            for i in indexSet {
                                modelContext.delete(sorted[i])
                            }
                        }

                        Button {
                            showAddHorse = true
                        } label: {
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
                    Button {
                        addNewRace()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                if selectedRace != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(role: .destructive) {
                            if let race = selectedRace {
                                deleteRace(race)
                            }
                        } label: {
                            Image(systemName: "trash")
                        }
                        .tint(.red)
                    }
                }
            }
            .sheet(isPresented: $showAddHorse) {
                if let race = selectedRace {
                    AddHorseSheet(race: race)
                }
            }
            .onAppear {
                if selectedRace == nil {
                    selectedRace = races.first
                }
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
        TextField("レース名（例: 日本ダービー）", text: $race.name)
        TextField("競馬場（例: 東京）", text: $race.venue)
        DatePicker("日付", selection: $race.date, displayedComponents: .date)
    }
}

// MARK: - 馬の行
struct HorseRow: View {
    @Bindable var horse: Horse

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
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
                    .font(.subheadline)
                    .foregroundStyle(.orange)
                    .frame(width: 60)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.vertical, 2)
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

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
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
                            Horse(name: name, mark: mark, memo: memo, result: result)
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
