import SwiftUI

enum MenuOption: String, CaseIterable {
    case home = "首頁"
    case chat = "對話"
    case stats = "統計"
    case settings = "設置"
}

struct SideMenuView: View {
    @Binding var showMenu: Bool
    @Binding var selectedOption: MenuOption
    
    var body: some View {
        List {     
            ForEach(MenuOption.allCases, id: \.self) { option in
                Button(action: {
                    selectedOption = option
                    showMenu = false
                }) {
                    HStack {
                        Image(systemName: iconName(for: option)) // 使用不同圖標
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text(option.rawValue)
                            .font(.headline)
                    }
                    .padding(.vertical, 10)
                    .alignmentGuide(.listRowSeparatorLeading, computeValue: { dimension in
                        return 0
                    })
                }
            }
        }
        .listStyle(.inset)
        .background(Color.white)
        .shadow(radius: 5)
    }
    
    // 根據選項返回圖標名稱
    func iconName(for option: MenuOption) -> String {
        switch option {
        case .home: return "house"
        case .chat: return "bubble.left.and.bubble.right"
        case .stats: return "chart.bar"
        case .settings: return "gear"
        }
    }
}

struct ContentView: View {
    @State private var showMenu = false
    @State private var selectedOption: MenuOption = .settings // 當前選擇的頁面
    @State private var showAlert = false
    @StateObject private var groq = Groq()
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .leading) {
                // 主視圖內容
                MainView(selectedOption: selectedOption)
                    .disabled(showMenu) // 如果菜單打開，禁用主視圖
                
                // 側邊菜單
                GeometryReader { geometry in
                    let screenWidth = geometry.size.width
                    let quarterWidth = screenWidth / 4
                    let menuWidth = quarterWidth > 256 ? quarterWidth : screenWidth

                    SideMenuView(showMenu: $showMenu, selectedOption: $selectedOption)
                        .frame(width: menuWidth)
                        .offset(x: showMenu ? 0 : -menuWidth)
                        .opacity(showMenu ? 1 : 0)
                        .animation(.easeInOut(duration: 0.3), value: showMenu)
                }
            }
            // 工具列按鈕
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if !groq.isSetup {
                            showAlert = true
                        } else {
                            withAnimation {
                                showMenu.toggle()
                            }
                        }
                    }) {
                        Image(systemName: "line.horizontal.3")
                            .font(.title)
                    }
                }
            }
            .alert("Groq API", isPresented: $showAlert) {
                Button("前往 GroqCloud", action: {
                    if let url = URL(string: "https://console.groq.com/keys") {
                        UIApplication.shared.open(url)
                    }
                })
                Button("我知道了", role: .cancel, action: {})
            } message: {
                Text("1. 前往 GroqCloud 取得 API Key。\n2. 在設置中輸入 API Key。\n3. 選擇要使用的大語言模型。")
            }
        }
        .environmentObject(groq)
        .onAppear {
            Task {
                await groq.fetchModels()
                if groq.isSetup {
                    selectedOption = .home
                }
            }
        }
    }
}

struct MainView: View {
    let selectedOption: MenuOption // 根據選項顯示不同內容
    
    var body: some View {
        VStack {
            switch selectedOption {
            case .home:
                ArticleListView()
            case .chat:
                ChatView()
            case .stats:
                ChartView()
            case .settings:
                GroqFormView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGray6))
        .animation(.easeInOut, value: selectedOption) // 平滑動畫
    }
}
