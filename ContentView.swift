//
//  ContentView.swift
//  Moneymind
//
//  Created by Micah Wisniewski on 4/9/25.
//

import SwiftUI
import SwiftData
import Charts

struct LoginResponse: Codable {
    let success: Bool
    let message: String
}

struct LoginView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                Image("Moneymind-adjusted")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                    .padding()

                Text("Welcome to MoneyMind")
                    .padding()
                    .font(.system(size: 45, weight: .semibold))
                
                Text("Your financial planner!")
                    .padding()
                    .font(.system(size: 10, weight: .semibold))

                Spacer()
                
                TextField("Username", text: $username)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Password", text: $password)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                HStack {
                    Button(action: {
                        authViewModel.loginUser(username: username, password: password)
                    }) {
                        Text("Login")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(9)
                    }

                    NavigationLink(destination: SignUpView()) {
                        Text("New User")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(9)

                    }
                }
                // Display error message if it exists
                if !authViewModel.errorMessage.isEmpty {
                    Text(authViewModel.errorMessage)
                        .foregroundColor(.red)
                }
            }
            .padding()
            .navigationDestination(isPresented: $authViewModel.isLoggedIn) {
                HomeView(username: username)
            }
        }
    }
}


struct HomeView: View {
    @StateObject private var userDataVM = UserDataViewModel()
    @State private var showTransactions = false
    @State private var username: String
    @EnvironmentObject private var authViewModel: AuthViewModel

    

    init(username: String) {
        _username = State(initialValue: username)
    }
    
    var currentDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: Date())
    }


    var body: some View {
        NavigationStack {
            VStack(spacing: 5) {
                
                Text(currentDate)
                    .padding()
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.top, 1)

                Text("Welcome!")
                    .font(.title)

                if let income = userDataVM.income, let expenses = userDataVM.expenses {
                    DashboardView(viewModel: userDataVM)
                } else {
                    ProgressView("Loading Dashboard...")
                }

            }
            .padding()
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        NavigationLink(destination: UserData(username: username)) {
                            Text("View Expenses")
                        }
                        NavigationLink(destination: UserIncomeData(username: username)) {
                            Text("View Income")
                        }
                        Button(action: {
                            authViewModel.isLoggedIn = false
                            authViewModel.loggedInUsername = ""
                        }) {
                            Text("Logout")
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title)
                    }
                }
            }
            .onAppear {
                userDataVM.getIncome(username: username)
                userDataVM.fetchExpenses(username: username)
                userDataVM.fetchNetTotal(username: username)
                userDataVM.fetchIncomeTotal(username: username)
                userDataVM.fetchExpensesTotal(username: username)
            }
        }
        
    }
    
}
struct DashboardView: View {
    @ObservedObject var viewModel: UserDataViewModel

    var totalIncome: Double {
        viewModel.income?.total ?? 0
    }

    var totalExpenses: Double {
        viewModel.expenses?.total ?? 0
    }
    
    var body: some View {
        VStack {
            if let net = viewModel.netTotal {
                Text("Net Total: $\(net, specifier: "%.2f")")
                    .font(.title3)
                    .foregroundColor(net >= 0 ? .green : .red)
            } else {
                ProgressView("Calculating net total...")
            }
            
            Text("Expenses Breakdown")
                .font(.headline)
            
            PieChartView(data: [
                ("Rent", viewModel.expenses?.rent ?? 0),
                ("Groceries", viewModel.expenses?.groceries ?? 0),
                ("Utilities", viewModel.expenses?.utilities ?? 0),
                ("Insurance", viewModel.expenses?.insurance ?? 0),
                ("Gas", viewModel.expenses?.gas ?? 0),
                ("Misc", viewModel.expenses?.miscellaneous ?? 0)
            ])
            
            Text("Income Trend")
                .font(.headline)
            
            if let incomeData = viewModel.incomeTrendData {
                LineGraphView(
                    dataPoints: incomeData.map { $0.total_income },
                    months: incomeData.map { "Month \($0.month)" }
                )
            } else {
                ProgressView("Loading income trend...")
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct PieChartView: View {
    let data: [(String, Double)]

    var body: some View {
        HStack {
            
            ZStack {
                ForEach(0..<data.count, id: \.self) { index in
                    PieSlice(startAngle: angle(for: index), endAngle: angle(for: index + 1))
                        .fill(color(for: index))
                    //                LabelView(text: data[index].0, angle: angle(for: index), index: index)
                }
            }
            .frame(width: 200, height: 200)
            .padding()
            
            VStack(alignment: .leading) {
                ForEach(0..<data.count, id: \.self) { index in
                    HStack {
                        Circle()
                            .fill(color(for: index))
                            .frame(width: 10, height: 10)
                        Text(data[index].0)
                            .font(.caption)
                    }
                }
            }
            .padding(.leading)
        }
                        
            
    }

    private func angle(for index: Int) -> Angle {
        let total = data.map { $0.1 }.reduce(0, +)
        let sum = data.prefix(index).map { $0.1 }.reduce(0, +)
        return Angle(degrees: (sum / total) * 360)
    }

    private func color(for index: Int) -> Color {
        let colors: [Color] = [.red, .green, .blue, .orange, .purple, .brown]
        return colors[index % colors.count]
    }
}
struct LabelView: View {
    var text: String
    var angle: Angle
    var index: Int

    var body: some View {
        GeometryReader { geometry in
            let radius = min(geometry.size.width, geometry.size.height) / 2
            let offset = radius / 1.5
            let angleInRadians = CGFloat(angle.degrees) * .pi / 180
            let labelX = cos(angleInRadians) * offset + geometry.size.width / 2
            let labelY = sin(angleInRadians) * offset + geometry.size.height / 2
            
            Text(text)
                .font(.caption)
                .foregroundColor(.white)
                .position(x: labelX, y: labelY)
        }
        .frame(width: 200, height: 200)
    }
}

struct PieSlice: Shape {
    var startAngle: Angle
    var endAngle: Angle

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()

        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)

        return path
    }
}

extension Color {
    static var random: Color {
        Color(hue: .random(in: 0...1), saturation: 0.8, brightness: 0.9)
    }
}

struct LineGraphView: View {
    let dataPoints: [Double]
    let months: [String]

    var body: some View {
        VStack {
            if dataPoints.isEmpty {
                Text("No data available")
                    .foregroundColor(.gray)
            } else {
                GeometryReader { geometry in
                    HStack {
                        // Y-axis labels
                        VStack {
                            let maxValue = dataPoints.max() ?? 1
                            let numberOfTicks = 5
                            ForEach(0..<numberOfTicks) { i in
                                Spacer()
                                Text("\(Int(maxValue - (maxValue / Double(numberOfTicks - 1) * Double(i))))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .frame(height: geometry.size.height / CGFloat(numberOfTicks), alignment: .top)
                            }
                        }
                        .frame(width: 40) // Reserve space for Y-axis labels

                        // Graph
                        ZStack {
                            Path { path in
                                guard dataPoints.count > 1 else { return }
                                let width = geometry.size.width - 40
                                let height = geometry.size.height
                                let maxValue = dataPoints.max() ?? 1

                                for index in dataPoints.indices {
                                    let x = width * CGFloat(index) / CGFloat(dataPoints.count - 1)
                                    let y = height * (1 - CGFloat(dataPoints[index] / maxValue))
                                    if index == 0 {
                                        path.move(to: CGPoint(x: x, y: y))
                                    } else {
                                        path.addLine(to: CGPoint(x: x, y: y))
                                    }
                                }
                            }
                            .stroke(Color.blue, lineWidth: 2)
                        }
                    }
                }
                .frame(height: 200)

                // X-axis labels
                HStack {
                    Spacer().frame(width: 40)
                    ForEach(months, id: \.self) { month in
                        Text(month)
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding()
    }
}

struct SignUpView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var email = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var errorMessage = ""

    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        VStack {
            Text("Create an Account")
                .font(.title)
                .padding()

            TextField("First Name", text: $firstName)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Last Name", text: $lastName)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Email", text: $email)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Username", text: $username)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            SecureField("Password", text: $password)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button(action: {
//                print("yadadadad") //debugging so I know where i am
                authViewModel.createUser(username: username, password: password, email: email, firstName: firstName, lastName: lastName)

            }) {
                Text("Create Account")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(9)
            }
            .navigationDestination(isPresented: $authViewModel.isLoggedIn) {
                HomeView(username: username) // Navigate to HomeView if logged in
            }
            

            if !authViewModel.errorMessage.isEmpty {
                Text(authViewModel.errorMessage)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
}


struct EditableIncomeRow: View {
    let title: String
    let value: Double
    var onCommit: (Double) -> Void

    @State private var textValue: String

    init(title: String, value: Double, onCommit: @escaping (Double) -> Void) {
        self.title = title
        self.value = value
        self.onCommit = onCommit
        self._textValue = State(initialValue: String(format: "%.2f", value))
    }

    var body: some View {
        HStack {
            Text(title)
            TextField("", text: $textValue, onCommit: {
                if let newValue = Double(textValue) {
                    onCommit(newValue)
                } else {
                    textValue = String(format: "%.2f", value) // Reset if invalid input
                }
            })
            .keyboardType(.decimalPad)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .frame(width: 100)
        }
    }
}

struct IncomeRow: View {
    let label: String
    @Binding var value: Double

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("Amount", value: $value, format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
                .keyboardType(.decimalPad)
        }
    }
}

struct UserIncomeData: View {
    @StateObject private var userDataVM = UserDataViewModel()
    let username: String
    @State private var modifiedIncome: Income? = nil


    var body: some View {
        VStack {
            Text("Your Income")
                .font(.title)
                .padding()

            if !userDataVM.errorMessage.isEmpty {
//                Text(userDataVM.errorMessage)
//                    .foregroundColor(.red)
            }
            
            if let income = userDataVM.income {
                List {
                    EditableIncomeRow(title: "Job", value: income.job) { newValue in
                        modifiedIncome = (modifiedIncome ?? income).withUpdatedJob(newValue)
                    }
                    EditableIncomeRow(title: "Real Estate", value: income.realEstate) { newValue in
                        modifiedIncome = (modifiedIncome ?? income).withUpdatedRealEstate(newValue)
                    }
                    EditableIncomeRow(title: "Investments", value: income.investments) { newValue in
                        modifiedIncome = (modifiedIncome ?? income).withUpdatedInvestments(newValue)
                    }
                    

                }
            }

            else {
                Text("No income data available.")
                    .foregroundColor(.gray)
            }
            
            if userDataVM.isSaving {
                ProgressView("Saving...") // Shows a loading spinner
            }

            // Update Income Button
            Button(action: {
                if let updatedIncome = modifiedIncome {
                    userDataVM.updateIncome(username: username, updatedIncome: updatedIncome)
                    modifiedIncome = nil // Reset after update
                } else {
                    userDataVM.errorMessage = "No changes to update."
                }
            }) {
                Text("Update Income")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
        .onAppear {
            userDataVM.getIncome(username: username)
        }
        .onChange(of: userDataVM.income) { newIncome in
            if let currentIncome = newIncome {
                modifiedIncome = currentIncome
            }
        }
    }
}


extension Optional: Equatable where Wrapped: Equatable {
    public static func == (lhs: Wrapped?, rhs: Wrapped?) -> Bool {
        switch (lhs, rhs) {
        case let (lhs?, rhs?):
            return lhs == rhs
        case (nil, nil):
            return true
        case (_, _):
            return false
        }
    }
}

struct UserData: View {
    @StateObject private var userDataVM = UserDataViewModel()
    let username: String
    @State private var modifiedExpenses: Expense?

    var body: some View {
        VStack {
            Text("Your Expenses")
                .font(.title)
                .padding()

            if !userDataVM.errorMessage.isEmpty {
                Text(userDataVM.errorMessage)
                    .foregroundColor(.red)
            }

            if let expenses = userDataVM.expenses {
                List {
                    EditableExpenseRow(title: "Rent", value: modifiedExpenses?.rent ?? expenses.rent) { newValue in
                        modifiedExpenses?.rent = newValue
                    }
                    EditableExpenseRow(title: "Groceries", value: modifiedExpenses?.groceries ?? expenses.groceries) { newValue in
                        modifiedExpenses?.groceries = newValue
                    }
                    EditableExpenseRow(title: "Utilities", value: modifiedExpenses?.utilities ?? expenses.utilities) { newValue in
                        modifiedExpenses?.utilities = newValue
                    }
                    EditableExpenseRow(title: "Insurance", value: modifiedExpenses?.insurance ?? expenses.insurance) { newValue in
                        modifiedExpenses?.insurance = newValue
                    }
                    EditableExpenseRow(title: "Gas", value: modifiedExpenses?.gas ?? expenses.gas) { newValue in
                        modifiedExpenses?.gas = newValue
                    }
                    EditableExpenseRow(title: "Miscellaneous", value: modifiedExpenses?.miscellaneous ?? expenses.miscellaneous) { newValue in
                        modifiedExpenses?.miscellaneous = newValue
                    }
                }
            } else {
                Text("No expenses data available.")
                    .foregroundColor(.gray)
            }

            Button(action: {
                if let updatedExpenses = modifiedExpenses {
                    userDataVM.updateExpenses(username: username, updatedExpenses: updatedExpenses)
                    modifiedExpenses = nil
                } else {
                    userDataVM.errorMessage = "No changes to update."
                }
            }) {
                Text("Update Expenses")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
        .onAppear {
            userDataVM.fetchExpenses(username: username)
        }
        .onChange(of: userDataVM.expenses) { newExpenses in
            if let currentExpenses = newExpenses {
                modifiedExpenses = currentExpenses
            }
        }
    }
}

struct EditableExpenseRow: View {
    let title: String
    let value: Double
    var onCommit: (Double) -> Void

    @State private var textValue: String

    init(title: String, value: Double, onCommit: @escaping (Double) -> Void) {
        self.title = title
        self.value = value
        self.onCommit = onCommit
        self._textValue = State(initialValue: String(format: "%.2f", value))
    }

    var body: some View {
        HStack {
            Text(title)
            TextField("", text: $textValue, onCommit: {
                if let newValue = Double(textValue) {
                    onCommit(newValue)
                } else {
                    textValue = String(format: "%.2f", value)
                }
            })
            .keyboardType(.decimalPad)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .frame(width: 100)
        }
    }
}


struct ExpenseRow: View {
    let label: String
    @Binding var value: Double

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("Amount", value: $value, format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
                .keyboardType(.decimalPad)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            if authViewModel.isLoggedIn {
                HomeView(username: authViewModel.loggedInUsername)
                    .environmentObject(authViewModel)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
    }
}


#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
