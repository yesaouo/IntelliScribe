import SwiftUI
import SwiftData
import Translation

@Model
final class Article {
    var label: Label?
    var content: String
    var title: String
    var keywords: [String]
    var tfString: String
    var mcString: String
    var bkString: String
    var createdAt: Date

    var tf: [TF] {
        do {
            return try JSONDecoder().decode([TF].self, from: tfString.data(using: .utf8)!)
        } catch {
            return []
        }
    }
    var mc: [MC] {
        do {
            return try JSONDecoder().decode([MC].self, from: mcString.data(using: .utf8)!)
        } catch {
            return []
        }
    }
    var bk: [BK] {
        do {
            return try JSONDecoder().decode([BK].self, from: bkString.data(using: .utf8)!)
        } catch {
            return []
        }
    }
    
    init(label: Label? = nil, 
         content: String = "",
         title: String = "",
         keywords: [String] = [],
         tfString: String = "",
         mcString: String = "",
         bkString: String = "",
         createdAt: Date = Date()) {
        self.label = label
        self.content = content
        self.title = title
        self.keywords = keywords
        self.tfString = tfString
        self.mcString = mcString
        self.bkString = bkString
        self.createdAt = createdAt
    }
}


struct ArticleList: View {
    @Query private var articles: [Article]
    @State private var newArticle: Article?
    @Environment(\.modelContext) private var context

    init(selectedLabel: String? = nil, textFilter: String = "") {
        let predicate = #Predicate<Article> { article in
            (selectedLabel == nil || article.label?.name == selectedLabel) &&
            (textFilter.isEmpty || article.title.localizedStandardContains(textFilter) || article.content.localizedStandardContains(textFilter))
        }
        _articles = Query(filter: predicate, sort: \Article.createdAt, order: .reverse)
    }

    var body: some View {
        Group {
            if !articles.isEmpty {
                List {
                    ForEach(articles) { article in
                        NavigationLink {
                            ArticleDetail(article: article)
                        } label: {
                            Text(article.title)
                                .lineLimit(1)
                        }
                    }
                    .onDelete(perform: deleteArticles(indexes:))
                }
            } else {
                ContentUnavailableView("Add Articles", systemImage: "text.badge.plus")
            }
        }
        .toolbar {
            ToolbarItem {
                Button("Add Article", systemImage: "plus", action: addArticle)
            }
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .sheet(item: $newArticle) { article in
            NavigationStack {
                ArticleDetail(article: article, isNew: true)
            }
            .interactiveDismissDisabled() // 禁止未儲存時的關閉
        }
    }

    // 新增文章
    private func addArticle() {
        let newItem = Article()
        context.insert(newItem)
        newArticle = newItem
    }

    // 刪除文章
    private func deleteArticles(indexes: IndexSet) {
        for index in indexes {
            context.delete(articles[index])
        }
    }
}

struct ArticleDetail: View {
    @Query private var labels: [Label]
    @Bindable var article: Article
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let isNew: Bool
    @State private var showLabelListView = false
    @EnvironmentObject var groq: Groq
    @State private var showTranslation = false
    @State private var isSaving = false
    @State private var showQuizView = false

    init(article: Article, isNew: Bool = false) {
        self.article = article
        self.isNew = isNew
    }

    var body: some View {
        Group {
            if isSaving {
                ProgressView("Asking LLMs...")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Form {
                    // Picker for selecting a label
                    Picker(selection: $article.label) {
                        Text("None")
                            .tag(nil as Label?)
                        ForEach(labels) { label in
                            Text(label.name)
                                .tag(label as Label?)
                        }
                    } label: {
                        HStack {
                            Text("Label")
                            Button(action: { showLabelListView = true }) {
                                Image(systemName: "pencil")
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    // Conditional display for article content
                    if isNew {
                        TextField("Content", text: $article.content, axis: .vertical)
                    } else {
                        Section(header: HStack {
                            Text("Content")
                            Spacer()
                            Button(action: { showTranslation.toggle() }) {
                                Image(systemName: "translate")
                            }
                        }) {
                            Text(try! AttributedString(markdown: formatContent(content: article.content, keywords: article.keywords)))
                                .foregroundColor(.primary)
                                .translationPresentation(isPresented: $showTranslation, text: article.content)
                        }

                        Button(action: { showQuizView = true }) {
                            HStack {
                                Spacer()
                                Text("開始測驗")
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(isNew ? "New Article" : article.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isNew {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        isSaving = true
                        Task {
                            let title = await groq.fetchReply(article.content, assistant: .title)
                            article.title = title.isEmpty ? "Untitled" : title.removeOuterQuotes()
                            
                            let keywords = await groq.fetchReply(article.content, assistant: .keywords)
                            article.keywords = keywords.components(separatedBy: ", ")

                            article.tfString = await groq.fetchQuestions(article.content, question: .tf)
                            article.mcString = await groq.fetchQuestions(article.content, question: .mc)
                            article.bkString = await groq.fetchQuestions(article.content, question: .bk)

                            article.createdAt = Date()
                            isSaving = false
                            dismiss()
                        }
                    }
                    .disabled(article.content.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        context.delete(article)
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showLabelListView) {
            LabelListView(selectedLabel: $article.label)
        }
        .fullScreenCover(isPresented: $showQuizView) {
            QuizView(quizModel: QuizModel(tfs: article.tf, mcs: article.mc, bks: article.bk))
        }
    }
}

struct ArticleListView: View {
    @Query private var labels: [Label]
    @State private var selectedLabel: Label? // 追踪當前選中的標籤
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !labels.isEmpty {
                    // 標籤選擇 ScrollView
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(labels) { label in
                                Text(label.name)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedLabel == label ? Color.accentColor : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedLabel == label ? .white : .primary)
                                    .cornerRadius(15)
                                    .onTapGesture {
                                        toggleLabelSelection(label)
                                    }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }

                // 篩選後的文章列表
                ArticleList(selectedLabel: selectedLabel?.name, textFilter: searchText)
                    .searchable(text: $searchText)
            }
            .navigationTitle("首頁")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // 點擊已選標籤可取消選中
    private func toggleLabelSelection(_ label: Label) {
        if selectedLabel == label {
            selectedLabel = nil // 取消選擇
        } else {
            selectedLabel = label
        }
    }
}

extension String {
    func removeOuterQuotes() -> String {
        guard self.hasPrefix("\""), self.hasSuffix("\"") else {
            return self
        }
        return String(self.dropFirst().dropLast())
    }
}

func formatContent(content: String, keywords: [String]) -> String {
    let formattedContent = NSMutableString(string: content)
    
    for keyword in keywords {
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: keyword))\\b" // 精確匹配整個字詞
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        
        let range = NSRange(location: 0, length: formattedContent.length)
        regex.replaceMatches(in: formattedContent, options: [], range: range, withTemplate: "[\(keyword)](https://www.google.com/search?q=\(keyword.replacingOccurrences(of: " ", with: "+")))")
    }
    
    return formattedContent as String
}

struct ArticlePicker: View {
    @Query private var articles: [Article]
    @Binding var selectedArticle: Article?
    @AppStorage("CHAT_SELECTED_TITLE") var selectedTitle: String?

    init(selectedLabel: String? = nil, selectedArticle: Binding<Article?>) {
        self._selectedArticle = selectedArticle
        let predicate = #Predicate<Article> { article in
            selectedLabel == nil || article.label?.name == selectedLabel
        }
        _articles = Query(filter: predicate, sort: \Article.createdAt, order: .reverse)
    }

    var body: some View {
        Picker("Article", selection: $selectedArticle) {
            Text("None").tag(nil as Article?)
            ForEach(articles) { article in
                Text(article.title)
                    .lineLimit(1)
                    .tag(article as Article?)
            }
        }
        .pickerStyle(.inline)
        .onChange(of: selectedArticle) { oldValue, newValue in
            selectedTitle = newValue?.title
        }
    }
}

struct ArticlePickerView: View {
    @Query private var labels: [Label]
    @State private var selectedLabel: Label?
    @Binding var selectedArticle: Article?
    
    var body: some View {
        Form {
            Picker("類別", selection: $selectedLabel) {
                Text("全部").tag(nil as Label?)
                ForEach(labels) { label in
                    Text(label.name).tag(label as Label?)
                }
            }
            .pickerStyle(MenuPickerStyle())

            ArticlePicker(selectedLabel: selectedLabel?.name, selectedArticle: $selectedArticle)
        }
    }
}
