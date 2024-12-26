import SwiftUI

struct TF: Codable {
    let question: String
    let answer: Bool
}

struct MC: Codable {
    let question: String
    let options: [String]
    let answer: Int
}

struct BK: Codable {
    let question: String
    let answer: String
}

struct Result: Codable, Identifiable {
    var id = UUID()
    let question: String
    let answer: String
    let myAnswer: String
    let isCorrect: Bool
}

@Observable class QuizModel {
    var tfs: [TF]
    var mcs: [MC]
    var bks: [BK]
    var results: [Result] = []
    var showingStart = true
    var showingResult = false
    var currentQuestionIndex = 0
    var userAnswers: [Int: Any] = [:]
    
    var allQuestions: [Any] {
        return tfs + mcs + bks
    }
    var currentQuestion: Any? {
        return currentQuestionIndex < allQuestions.count ? allQuestions[currentQuestionIndex] : nil
    }
    var correctAnswers: Int {
        return results.filter { $0.isCorrect }.count
    }
    
    init(tfs: [TF], mcs: [MC], bks: [BK]) {
        self.tfs = tfs
        self.mcs = mcs
        self.bks = bks
    }
    
    func previousPage() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
        } else {
            resetQuiz()
        }
    }
    
    func nextPage() {
        if currentQuestionIndex < allQuestions.count - 1 {
            currentQuestionIndex += 1
        } else {
            submitQuiz()
        }
    }
    
    func checkAnswers() {
        results = []
        
        for (index, topic) in allQuestions.enumerated() {
            let question: String
            let answer: String
            let isCorrect: Bool
            let userAnswer = (userAnswers[index] as? String) ?? (userAnswers[index] as? Bool).map { "\($0)" } ?? ""
            
            switch topic {
            case let t as TF:
                question = t.question
                answer = "\(t.answer)"
                isCorrect = userAnswer == answer
            case let t as MC:
                question = t.question
                answer = t.options[t.answer - 1]
                isCorrect = userAnswer == answer
            case let t as BK:
                question = t.question
                answer = t.answer
                isCorrect = areSentencesSimilar(sentence1: userAnswer.lowercased(), sentence2: answer.lowercased())
            default:
                question = ""
                answer = ""
                isCorrect = false
            }
            
            let result = Result(
                question: question,
                answer: answer,
                myAnswer: userAnswer,
                isCorrect: isCorrect
            )
            results.append(result)
        }
    }
    
    func resetQuiz() {
        showingStart = true
        showingResult = false
        currentQuestionIndex = 0
        userAnswers = [:]
    }
    
    func submitQuiz() {
        checkAnswers()
        showingResult = true
    }
}

struct QuizView: View {
    @State var quizModel: QuizModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Group {
                if quizModel.showingStart {
                    StartView(quizModel: $quizModel)
                } else if quizModel.showingResult {
                    ResultView(quizModel: $quizModel)
                } else {
                    QuestionView(quizModel: $quizModel)
                }    
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("返回", action: { dismiss() })
                }
                if !quizModel.showingStart, !quizModel.showingResult {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("送出", action: quizModel.submitQuiz)
                    }
                }
            }
        }
    }
}

struct StartView: View {
    @Binding var quizModel: QuizModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("準備好開始測驗了嗎？")
                .font(.title)
                .fontWeight(.bold)
            
            Text("總共 \(quizModel.allQuestions.count) 題")
                .font(.headline)
            
            Button(action: {
                quizModel.showingStart = false
            }) {
                Text("開始測驗")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(minWidth: 200)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
    }
}

struct ResultView: View {
    @Binding var quizModel: QuizModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("測驗結束！")
                .font(.title)
                .fontWeight(.bold)
            
            Text("你答對了 \(quizModel.correctAnswers) 題，共 \(quizModel.allQuestions.count) 題")
                .font(.headline)
            
            ScrollView {
                VStack(spacing: 15) {
                    ForEach(Array(quizModel.results.enumerated()), id: \.element.id) { index, result in
                        ResultCard(result: result, questionNumber: index + 1)
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 5)
            
            Button(action: quizModel.resetQuiz) {
                Text("重新測驗")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(minWidth: 200)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
    }
}

struct ResultCard: View {
    let result: Result
    let questionNumber: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("題目\(questionNumber): \(result.question)\n")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Text("你的答案: ")
                Text(result.myAnswer)
                    .foregroundColor(result.isCorrect ? .green : .red)
                    .fontWeight(.bold)
            }
            
            HStack {
                Text("標準答案: ")
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(result.answer)
                        .foregroundColor(.green)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}
