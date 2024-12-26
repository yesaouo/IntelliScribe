import SwiftUI
import SwiftData

@Model
final class Label {
    var name: String
    var articles = [Article]()
    
    init(name: String) {
        self.name = name
    }
}

struct LabelList: View {
    @Query private var labels: [Label]
    @Query private var articles: [Article]
    @State private var newLabel: Label?
    @State private var showAddAlert = false
    @State private var showDeleteAlert = false
    @State private var newLabelName = ""
    @State private var labelToDelete: Label? // 用於記錄要刪除的標籤
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Binding var selectedLabel: Label?

    init(textFilter: String = "", selectedLabel: Binding<Label?>) {
        let predicate = #Predicate<Label> { label in
            textFilter.isEmpty || label.name.localizedStandardContains(textFilter)
        }
        _labels = Query(filter: predicate, sort: \Label.name)
        _selectedLabel = selectedLabel
    }

    var body: some View {
        Group {
            if !labels.isEmpty {
                List {
                    ForEach(labels) { label in
                        Button(label.name) {
                            selectedLabel = label
                            dismiss()
                        }
                    }
                    .onDelete(perform: confirmDeleteLabels(indexes:))
                }
            } else {
                ContentUnavailableView("Add Labels", systemImage: "text.badge.plus")
            }
        }
        .navigationTitle("標籤")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem {
                Button("Add Label", systemImage: "plus", action: { showAddAlert = true })
            }
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .alert("Add New Label", isPresented: $showAddAlert) {
            TextField("Label Name", text: $newLabelName)
            Button("Add", action: addLabel).disabled(newLabelName.isEmpty)
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete Label", isPresented: $showDeleteAlert) {
            Button("移除標籤", action: removeLabelOnly)
            Button("移除標籤與內容", action: removeLabelAndArticles)
            Button("取消", role: .cancel, action: { labelToDelete = nil })
        } message: {
            if let label = labelToDelete {
                Text("確定要移除標籤 \(label.name) 嗎？")
            } else {
                Text("")
            }
        }
    }

    // 新增類別
    private func addLabel() {
        guard !newLabelName.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        let newItem = Label(name: newLabelName)
        context.insert(newItem)
        newLabel = newItem
        newLabelName = ""
    }

    // 確認刪除標籤
    private func confirmDeleteLabels(indexes: IndexSet) {
        if let index = indexes.first {
            labelToDelete = labels[index]
            showDeleteAlert = true
        }
    }

    // 只刪除標籤
    private func removeLabelOnly() {
        guard let label = labelToDelete else { return }
        context.delete(label)
        labelToDelete = nil
    }

    // 刪除標籤及相關文章
    private func removeLabelAndArticles() {
        guard let label = labelToDelete else { return }
        
        // 找出所有與該標籤相關的文章
        let relatedArticles = articles.filter { $0.label == label }
        for article in relatedArticles {
            context.delete(article)
        }
        
        // 刪除標籤
        context.delete(label)
        labelToDelete = nil
    }
}

struct LabelListView: View {
    @State private var searchText = ""
    @Binding var selectedLabel: Label?

    var body: some View {
        NavigationStack {
            LabelList(textFilter: searchText, selectedLabel: $selectedLabel)
                .searchable(text: $searchText)
        }
    }
}
