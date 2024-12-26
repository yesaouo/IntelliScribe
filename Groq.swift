import SwiftUI

enum Assistant: String {
    case title = "writing headlines"
    case keywords = "extracting comma-separated keywords"
}

enum Question: String {
    case tf = """
        Based on the following article, generate True/False questions in JSON format. Each question should include:
        - A "question" field with the question text.
        - An "answer" field with the correct answer (true or false).
        Output the questions as a JSON array. Do not include any text outside the JSON array. Generate at least 5 questions.
    """
    case mc = """
        Based on the following article, generate multiple-choice questions with 4 answer options in JSON format. Each question should include:
        - A "question" field with the question text.
        - An "options" field as an array containing 4 answer choices.
        - An "answer" field indicating the correct answer from the options, using the numbers 1, 2, 3, or 4 to specify the answer.
        Output the questions as a JSON array. Do not include any text outside the JSON array. Generate at least 5 questions.
    """
    case bk = """
        Based on the following article, generate fill-in-the-blank questions in JSON format. Each question should include:
        - A "question" field with the question text, where the blank is indicated by a pair of underscores (e.g., "The capital of France is __").
        - An "answer" field with the correct answer.
        Output the questions as a JSON array. Do not include any text outside the JSON array. Generate at least 5 questions.
    """
    case qa = """
        Based on the following article, generate short answer questions in JSON format. Each question should include:
        - A "question" field with the question text.
        - An "answer" field with the correct answer.
        Output the questions as a JSON array. Do not include any text outside the JSON array. Generate at least 5 questions.
    """
}

class Groq: ObservableObject {
    @AppStorage("GROQ_API_KEY") var apiKey: String?
    @AppStorage("GROQ_SELECTED_MODEL") var selectedModel: String?
    @Published var models: [String] = []
    let defaultModel = "llama-3.1-8b-instant"
    var isSetup: Bool {
        apiKey != nil && !models.isEmpty && selectedModel != nil
    }
    
    func fetchModels() async {
        models = []
        
        guard let key = apiKey,
              let url = URL(string: "https://api.groq.com/openai/v1/models") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Failed to fetch models")
                return
            }
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let modelData = json["data"] as? [[String: Any]] {
                models = modelData.compactMap { $0["id"] as? String }
                if selectedModel == nil, models.contains(defaultModel) {
                    selectedModel = defaultModel
                }
                if let selectedModel, !models.contains(selectedModel) {
                    self.selectedModel = nil
                }
            }
        } catch {
            print("Error fetching models: \(error)")
        }
    }

    func fetchChat(_ chat: [[String: String]]) async -> String {
        guard let key = apiKey,
              let model = selectedModel,
              let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else { return "" }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "messages": chat,
            "model": model,
            "temperature": 0.2,
            "max_tokens": 2048,
            "stream": false
        ]
        
        do {
            let requestBody = try JSONSerialization.data(withJSONObject: body)
            request.httpBody = requestBody
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Failed to fetch chat")
                return ""
            }
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                return content
            }
        } catch {
            print("Error fetching chat: \(error)")
        }
        return ""
    }
    
    func fetchReply(_ userContent: String, assistant: Assistant) async -> String {
        guard let key = apiKey,
              let model = selectedModel,
              let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else { return "" }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "messages": [
                ["role": "system", "content": "You are a helpful assistant specialized in \(assistant.rawValue). You are to the point and only give the answer in isolation without any chat-based fluff."],
                ["role": "user", "content": "I have the following document: \(userContent)"]
            ],
            "model": model,
            "temperature": 0.2,
            "max_tokens": 2048,
            "stream": false
        ]
        
        do {
            let requestBody = try JSONSerialization.data(withJSONObject: body)
            request.httpBody = requestBody
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Failed to fetch reply")
                return ""
            }
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                return content
            }
        } catch {
            print("Error fetching reply: \(error)")
        }
        return ""
    }

    func fetchQuestions(_ userContent: String, question: Question) async -> String {
        guard let key = apiKey,
              let model = selectedModel,
              let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else { return "" }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "messages": [
                ["role": "system", "content": question.rawValue],
                ["role": "user", "content": userContent]
            ],
            "model": model,
            "temperature": 0.2,
            "max_tokens": 2048,
            "stream": false
        ]
        
        do {
            let requestBody = try JSONSerialization.data(withJSONObject: body)
            request.httpBody = requestBody
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Failed to fetch questions")
                return ""
            }
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                return content
            }
        } catch {
            print("Error fetching questions: \(error)")
        }
        return ""
    }
}

struct GroqFormView: View {
    @EnvironmentObject var groq: Groq
    @Environment(\.presentationMode) var presentationMode
    @State private var apiKey: String = ""
    @State private var selectedModel: String = ""
    @State private var isLoading: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("API Key")) {
                    HStack {
                        SecureField("Enter your Groq API Key", text: $apiKey)
                        Button(action: submitAPIKey) {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .foregroundColor(apiKey.isEmpty ? .gray : .blue)
                                .accessibilityLabel("Submit API Key")
                        }
                        .disabled(apiKey.isEmpty)
                    }
                }
                
                if !isLoading, !groq.models.isEmpty {
                    Section(header: Text("Available Models")) {
                        Picker("Select Model", selection: $selectedModel) {
                            ForEach(groq.models, id: \.self) { model in
                                Text(model)
                            }
                        }
                        .pickerStyle(DefaultPickerStyle())
                        .onChange(of: selectedModel) { oldValue, newValue in
                            groq.selectedModel = newValue
                        }
                    }
                }
            }
            .navigationTitle("設置")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if isLoading {
                    ProgressView("Loading models...")
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if groq.models.isEmpty {
                    ContentUnavailableView(
                        "No Models Available",
                        systemImage: "exclamationmark.circle",
                        description: Text("Please verify your API Key or try again later.")
                    )
                }
            }
            .onAppear {
                apiKey = groq.apiKey ?? ""
                selectedModel = groq.selectedModel ?? ""
            }
        }
    }
    
    private func submitAPIKey() {
        groq.apiKey = apiKey
        isLoading = true
        Task {
            await groq.fetchModels()
            selectedModel = groq.selectedModel ?? ""
            isLoading = false
        }
    }
}
