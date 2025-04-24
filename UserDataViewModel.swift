//
//  UserDataViewModel.swift
//  Moneymind
//
//  Created by Micah Wisniewski on 4/9/25.
//
import Foundation

struct ServerResponse: Codable {
    let success: Bool
    let expenses: Expense?
    let income: Income?
}

class UserDataViewModel: ObservableObject {
    @Published var expenses: Expense?
    @Published var errorMessage: String = ""
    @Published var income: Income?
    @Published var isSaving: Bool = false
    @Published var netTotal: Double?
    @Published var totalIncome: Double?
    @Published var totalExpenses: Double?
    @Published var incomeMonth: Int?
    @Published var expensesMonth: Int?
    @Published var incomeTrendData: [MonthlyIncome]?

    
    
    func fetchExpenses(username: String) {
        guard let url = URL(string: "http://localhost:8080/getExpenses.php") else {
            self.errorMessage = "Invalid URL"
            return
        }
        
        let requestData: [String: Any] = ["username": username]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestData) else {
            self.errorMessage = "Failed to encode request data"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self.errorMessage = "Network error: \(error?.localizedDescription ?? "Unknown error")"
                }
                return
            }
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON Response: \(jsonString)")
            }
            do {
                // Decode the outer dictionary first
                print("blahblahblah")
                let decodedResponse = try JSONDecoder().decode(ServerResponse.self, from: data)
                print("decodedResponse:", decodedResponse.expenses)
                
                DispatchQueue.main.async {
                    if decodedResponse.success {
                        self.expenses = decodedResponse.expenses
                    } else {
                        self.errorMessage = "No expenses found"
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to decode response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    func updateExpenses(username: String, updatedExpenses: Expense) {
        guard let url = URL(string: "http://localhost:8080/updateExpenses.php") else {
            self.errorMessage = "Invalid URL"
            return
        }
        
        let requestData: [String: Any] = [
            "username": username,
            "expenses": [
                "rent": updatedExpenses.rent,
                "groceries": updatedExpenses.groceries,
                "utilities": updatedExpenses.utilities,
                "insurance": updatedExpenses.insurance,
                "gas": updatedExpenses.gas,
                "miscellaneous": updatedExpenses.miscellaneous
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestData) else {
            self.errorMessage = "Failed to encode update request data"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self.errorMessage = "Network error: \(error?.localizedDescription ?? "Unknown error")"
                }
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                //print("Raw JSON Response: \(jsonString)")
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode([String: Bool].self, from: data)
                DispatchQueue.main.async {
                    if let success = decodedResponse["success"], success {
                        self.fetchExpenses(username: username) // Refresh expenses after update
                    } else {
                        self.errorMessage = "Failed to update expenses"
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    //self.errorMessage = "Failed to decode update response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    func getIncome(username: String) {
        guard let url = URL(string: "http://localhost:8080/getIncome.php") else {
            self.errorMessage = "Invalid URL"
            return
        }
        
        let requestData: [String: Any] = ["username": username]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestData) else {
            self.errorMessage = "Failed to encode request data"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self.errorMessage = "Network error: \(error?.localizedDescription ?? "Unknown error")"
                }
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON Response: \(jsonString)")
            }

            
            do {
                let decodedResponse = try JSONDecoder().decode(ServerResponse.self, from: data)
                
                DispatchQueue.main.async {
                    if decodedResponse.success {
                        self.income = decodedResponse.income
                    } else {
                        self.errorMessage = "No income data found"
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to decode response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    func updateIncome(username: String, updatedIncome: Income) {
        DispatchQueue.main.async {
            self.income = updatedIncome  // ✅ Ensure local state updates before sending request
        }
        
        isSaving = true
        
        guard let url = URL(string: "http://localhost:8080/updateIncome.php") else {
            self.errorMessage = "Invalid URL"
            self.isSaving = false
            return
        }
        
        let requestData: [String: Any] = [
            "username": username,
            "income": [
                "job": updatedIncome.job,
                "real_estate": updatedIncome.realEstate,
                "investments": updatedIncome.investments
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestData, options: .prettyPrinted) else {
            self.errorMessage = "Failed to encode update request data"
            self.isSaving = false
            return
        }
        
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("Final JSON Request Before Sending:\n\(jsonString)")  // ✅ Debugging
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                self.isSaving = false
                DispatchQueue.main.async {
                    self.errorMessage = "Network error: \(error?.localizedDescription ?? "Unknown error")"
                }
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON Response: \(jsonString)")
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode([String: Bool].self, from: data)
                print("Decoded Response: \(decodedResponse)") // ✅ Debugging
                
                DispatchQueue.main.async {
                    self.isSaving = false
                    if let success = decodedResponse["success"], success {
                        self.getIncome(username: username) // ✅ Force UI refresh
                    } else {
                        self.errorMessage = "Failed to update income"
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isSaving = false
                    self.errorMessage = "Failed to decode update response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    
    func fetchNetTotal(username: String) {
        guard let url = URL(string: "http://localhost:8080/getNetTotal.php") else {
            self.errorMessage = "Invalid URL"
            return
        }

        let requestData: [String: Any] = ["username": username]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestData) else {
            self.errorMessage = "Failed to encode request data"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self.errorMessage = "Network error: \(error?.localizedDescription ?? "Unknown error")"
                    print("Network error: \(error?.localizedDescription ?? "Unknown error")")

                }
                return
            }

            do {
                let responseString = String(data: data, encoding: .utf8) ?? "No response string"
                print("Raw response: \(responseString)")

                let decoded = try JSONDecoder().decode(NetTotalResponse.self, from: data)
                DispatchQueue.main.async {
                    print("Decoded net total: \(decoded)")
                    self.netTotal = decoded.net_total
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to decode net total: \(error.localizedDescription)"
                    print("Decoding error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
//    func fetchIncomeTotal(username: String) {
//        guard let url = URL(string: "http://localhost:8080/get_total_income.php") else {
//            self.errorMessage = "Invalid URL"
//            return
//        }
//
//        let requestData: [String: Any] = ["username": username]
//        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestData) else {
//            self.errorMessage = "Failed to encode request data"
//            return
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.httpBody = jsonData
//
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data, error == nil else {
//                DispatchQueue.main.async {
//                    self.errorMessage = "Network error: \(error?.localizedDescription ?? "Unknown error")"
//                    print("Network error: \(error?.localizedDescription ?? "Unknown error")")
//
//                }
//                return
//            }
//
//            do {
//                let responseString = String(data: data, encoding: .utf8) ?? "No response string"
//                print("Raw response: \(responseString)")
//
//                let decoded = try JSONDecoder().decode(MonthlyIncomeResponse.self, from: data)
//                DispatchQueue.main.async {
//                    print("Decoded net total: \(decoded)")
//                    self.totalIncome = decoded.total_income
//                    self.incomeMonth = decoded.month
//                }
//            } catch {
//                DispatchQueue.main.async {
//                    self.errorMessage = "Failed to decode net total: \(error.localizedDescription)"
//                    print("Decoding error: \(error.localizedDescription)")
//                }
//            }
//        }.resume()
//    }
    
    func fetchIncomeTotal(username: String) {
        guard let url = URL(string: "http://localhost:8080/get_total_income.php") else {
            self.errorMessage = "Invalid URL"
            return
        }

        let requestData: [String: Any] = ["username": username]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestData) else {
            self.errorMessage = "Failed to encode request data"
            print("Error: Failed to encode request data for income total")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    print("Network error: \(error.localizedDescription)")
                }
                return
            }

            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self.errorMessage = "Network error: \(error?.localizedDescription ?? "Unknown error")"
                    print("no data for income total")
                }
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw JSON Response Income: \(responseString)")
            }


            do {
                let decoded = try JSONDecoder().decode(MonthlyIncomeResponse.self, from: data)
                DispatchQueue.main.async {
                    if decoded.success {
                        self.incomeTrendData = decoded.data
                        print("Decoded Income Data: \(decoded.data)")

                    } else {
                        self.errorMessage = "No income data found"
                        print("Error: No income data found")

                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to decode response: \(error.localizedDescription)"
                    print("Decoding error for Income: \(error.localizedDescription)")

                }
            }
        }.resume()
    }
    
    
    func fetchExpensesTotal(username: String) {
        guard let url = URL(string: "http://localhost:8080/get_total_expenses.php") else {
            self.errorMessage = "Invalid URL"
            return
        }

        let requestData: [String: Any] = ["username": username]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestData) else {
            self.errorMessage = "Failed to encode request data"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self.errorMessage = "Network error: \(error?.localizedDescription ?? "Unknown error")"
                    print("Network error: \(error?.localizedDescription ?? "Unknown error")")

                }
                return
            }

            do {
                let responseString = String(data: data, encoding: .utf8) ?? "No response string"
                print("Raw response: \(responseString)")

                let decoded = try JSONDecoder().decode(MonthlyExpensesResponse.self, from: data)
                DispatchQueue.main.async {
                    print("Decoded net total: \(decoded)")
                    self.totalExpenses = decoded.total_expenses
                    self.expensesMonth = decoded.month
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to decode net total: \(error.localizedDescription)"
                    print("Decoding error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }


}



struct UpdateResponse: Codable {
    let success: Bool
    let message: String
}

struct NetTotalResponse: Decodable {
    let success: Bool
    let net_total: Double
}

//struct MonthlyIncomeResponse: Decodable {
//    let success: Bool
//    let month: Int
//    let total_income: Double
//}
struct MonthlyIncomeResponse: Decodable {
    let success: Bool
    let data: [MonthlyIncome]
}

struct MonthlyIncome: Decodable {
    let month: Int
    let total_income: Double
}

struct MonthlyExpensesResponse: Decodable {
    let success: Bool
    let month: Int
    let total_expenses: Double
}


