import SwiftUI

struct QuestionView: View {
    @Binding var quizModel: QuizModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("問題 \(quizModel.currentQuestionIndex + 1) / \(quizModel.allQuestions.count)")
                .font(.headline)
            Spacer()
            
            if let currentQuestion = quizModel.currentQuestion {
                switch currentQuestion {
                case let q as TF:
                    TFView(question: q, userAnswer: Binding(
                        get: { quizModel.userAnswers[quizModel.currentQuestionIndex] as? Bool ?? nil },
                        set: { quizModel.userAnswers[quizModel.currentQuestionIndex] = $0 }
                    ))
                case let q as MC:
                    MCView(question: q, userAnswer: Binding(
                        get: { quizModel.userAnswers[quizModel.currentQuestionIndex] as? String ?? "" },
                        set: { quizModel.userAnswers[quizModel.currentQuestionIndex] = $0 }
                    ))
                case let q as BK:
                    BKView(question: q, userAnswer: Binding(
                        get: { quizModel.userAnswers[quizModel.currentQuestionIndex] as? String ?? "" },
                        set: { quizModel.userAnswers[quizModel.currentQuestionIndex] = $0 }
                    ))
                default:
                    Text("未知題型")
                }
            }
            
            Spacer()
            HStack(spacing: 20) {
                Button(action: quizModel.previousPage) {
                    Text(quizModel.currentQuestionIndex == 0 ? "返回" : "上一題")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                }
                Button(action: quizModel.nextPage) {
                    Text(quizModel.currentQuestionIndex + 1 == quizModel.allQuestions.count ? "交卷" : "下一題")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
        }
    }
}

struct TFView: View {
    let question: TF
    @Binding var userAnswer: Bool?
    
    var body: some View {
        VStack(spacing: 20) {
            Text(question.question)
                .font(.title3)
                .multilineTextAlignment(.center)
            
            HStack {
                Button(action: { userAnswer = true }) {
                    Text("True")
                        .padding()
                        .frame(minWidth: 75)
                        .background(userAnswer == true ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: { userAnswer = false }) {
                    Text("False")
                        .padding()
                        .frame(minWidth: 75)
                        .background(userAnswer == false ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
    }
}

struct MCView: View {
    let question: MC
    @Binding var userAnswer: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text(question.question)
                .font(.title3)
                .multilineTextAlignment(.center)
            
            ForEach(question.options, id: \.self) { option in
                Button(action: { userAnswer = option }) {
                    HStack {
                        Text(option)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(userAnswer == option ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
    }
}

struct BKView: View {
    let question: BK
    @Binding var userAnswer: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text(question.question)
                .font(.title3)
                .multilineTextAlignment(.center)
            
            TextField("Your answer", text: $userAnswer)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}
