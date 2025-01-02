import SwiftUI
import TipKit

struct APIKeyTip: Tip {
    var title: Text {
        Text("設置您的 API Key")
    }
    var message: Text? {
        Text("""
        請輸入您的 Groq API Key 以啟用 AI 功能。
        完成輸入後，記得點擊右側的刷新按鈕提交。
        如果您尚未擁有 API Key，請點擊下方按鈕前往獲取。
        """)
    }
    var image: Image? {
        Image(systemName: "key")
    }
    var actions: [Action] {
        [
            Action(id: "goto-groqcloud", title: "前往 GroqCloud") {
                if let url = URL(string: "https://console.groq.com/keys") {
                    UIApplication.shared.open(url)
                }
            }
        ]
    }
}

struct SelectModelTip: Tip {
    var title: Text {
        Text("選擇合適的模型")
    }
    var message: Text? {
        Text("""
        - 3B 以下模型最省資源，但不建議使用於非英文內容。
        - 11B 以上模型非常強大，但可能較快達到使用上限。
        - 預設的 8B 模型性能與成本表現平衡，建議使用。
        """)
    }
}
