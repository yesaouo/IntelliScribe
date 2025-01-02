import SwiftUI
import SwiftData

@Model
class Message {
    var sender: String
    var content: String
    var timestamp: Date

    init(sender: String, content: String, timestamp: Date = Date()) {
        self.sender = sender
        self.content = content
        self.timestamp = timestamp
    }
}

struct ChatView: View {
    @Query private var messages: [Message]
    @Environment(\.modelContext) private var context
    @State private var inputText: String = "" // 使用者輸入的訊息
    @EnvironmentObject var groq: Groq
    @State private var selectedArticle: Article?
    @State private var showArticlePickerView = false
    @Query private var articles: [Article]
    @AppStorage("CHAT_SELECTED_TITLE") var selectedTitle: String?

    init() {
        _messages = Query(sort: \Message.timestamp, order: .forward)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack {
                    if messages.isEmpty {
                        Spacer()
                        
                        Text("歡迎來到聊天室！")
                            .font(.title)
                            .foregroundColor(.gray)
                        Text("選擇一篇文章或是直接開始對話")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Spacer()
                    } else {
                        // 顯示對話紀錄
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(messages) { message in
                                    HStack(alignment: .top) {
                                        if message.sender == "用戶" {
                                            Spacer() // 用戶訊息靠右
                                        }
                                        VStack(alignment: .leading, spacing: 4) {
                                            if message.sender != "用戶" {
                                                Text("\(message.sender):")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            Text(message.content)
                                                .padding(8)
                                                .background(message.sender == "用戶" ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                                                .cornerRadius(8)
                                        }
                                        if message.sender != "用戶" {
                                            Spacer() // 電腦訊息靠左
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                    }

                    // 輸入訊息
                    HStack {
                        TextField("輸入訊息...", text: $inputText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(minHeight: 36)
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .padding(8)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                        .disabled(inputText.isEmpty)
                    }
                    .padding()
                }
            }
            .toolbar {
                ToolbarItem() {
                    Button(action: { showArticlePickerView = true }) {
                        Image(systemName: "document.badge.ellipsis")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("重置") {
                        resetChat()
                    }
                    .disabled(messages.isEmpty)
                }
            }
            .navigationTitle(selectedArticle?.title ?? "聊天室")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let selectedTitle {
                    selectedArticle = articles.first { $0.title == selectedTitle }
                }
            }
            .sheet(isPresented: $showArticlePickerView) {
                ArticlePickerView(selectedArticle: $selectedArticle)
            }
        }
    }

    // 傳送訊息
    private func sendMessage() {
        Task {
            let outputText = await groq.fetchChat(formatChat(inputText))
            let userMessage = Message(sender: "用戶", content: inputText)
            context.insert(userMessage)
            let botReply = Message(sender: groq.selectedModel ?? "電腦", content: outputText)
            context.insert(botReply)
            inputText = ""
        }
    }

    // 重置聊天室
    private func resetChat() {
        selectedTitle = nil
        selectedArticle = nil
        for message in messages {
            context.delete(message)
        }
    }

    private func formatChat(_ userContent: String) -> [[String: String]] {
        var formattedMessages = messages.map { message in
            let role = (message.sender == "用戶") ? "user" : "assistant"
            return ["role": role, "content": message.content]
        }
        formattedMessages.append(["role": "user", "content": userContent])
        if let selectedArticle {
            formattedMessages.insert(["role": "system", "content": selectedArticle.content], at: 0)
        }
        return formattedMessages
    }
}
