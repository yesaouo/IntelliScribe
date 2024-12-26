import SwiftUI
import SwiftData
import Charts

struct KeywordBarChart: View {
    @Query private var articles: [Article]
    @Binding var selectedLabelName: String?

    @State private var animatedKeywordCounts: [(name: String, frequency: Double)] = []

    private var filteredArticles: [Article] {
        if let labelName = selectedLabelName {
            return articles.filter { $0.label?.name == labelName }
        } else {
            return articles
        }
    }

    private var keywordCounts: [(name: String, frequency: Double)] {
        let keywords = filteredArticles.flatMap { $0.keywords }
        let totalKeywords = keywords.count
        guard totalKeywords > 0 else { return [] }
        
        let counts = keywords.reduce(into: [:]) { counts, keyword in
            counts[keyword, default: 0] += 1
        }
        return counts.map { (key: String, value: Int) -> (name: String, frequency: Double) in
                (name: key, frequency: Double(value) / Double(totalKeywords))
            }
            .sorted { $0.frequency > $1.frequency }
            .prefix(10)
            .map { $0 }
    }

    var body: some View {
        if keywordCounts.isEmpty {
            Text("無關鍵字可供顯示")
                .foregroundColor(.gray)
                .font(.subheadline)
                .padding()
        } else {
            Chart(animatedKeywordCounts, id: \.name) { item in
                BarMark(x: .value("頻率", item.frequency), y: .value("關鍵字", item.name))
            }
            .onAppear {
                animatedKeywordCounts = keywordCounts.map { ($0.name, 1) }
                withAnimation(.easeInOut(duration: 1.0)) {
                    animatedKeywordCounts = keywordCounts
                }
            }
            .padding()
        }
    }
}

struct ChartView: View {
    @State private var selectedLabelName: String? = nil
    @Query private var articles: [Article]
    @Query private var labels: [Label]

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("前10大關鍵字分析:")
                        .font(.headline)
                    Picker("篩選標籤", selection: $selectedLabelName) {
                        Text("全部")
                            .tag(nil as String?)
                        ForEach(labels) { label in
                            Text(label.name)
                                .tag(label.name as String?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                KeywordBarChart(selectedLabelName: $selectedLabelName)
                    .padding()
            }
            .navigationTitle("統計")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
