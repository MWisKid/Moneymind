//
//  AuthViewModel.swift
//  Moneymind
//
//  Created by Micah Wisniewski on 4/9/25.
//

import Foundation

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var errorMessage = ""
    @Published var loggedInUsername: String = ""


    
    // Add a method to create a new user
    func createUser(username: String, password: String, email: String, firstName: String, lastName: String) {
        guard let url = URL(string: "http://localhost:8080/api.php") else {
            self.errorMessage = "Invalid URL"
            return
        }
        
        let requestData: [String: Any] = [
            "action": "register",
            "username": username,
            "password": password,
            "email": email,
            "first_name": firstName,
            "last_name": lastName
        ]
        
        print("Sending registration data: \(requestData)")

        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestData) else {
            self.errorMessage = "Failed to encode request data"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // 🐛 DEBUG: print the raw request body
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("Request JSON String: \(jsonString)")
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                print("Network error: \(error.localizedDescription)")
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
            }

            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Raw Response: \(responseString)")
            }
            
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self.errorMessage = "Network error"
                }
                return
            }
            
            // Check the response to see if the user was created successfully
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    self.loggedInUsername = username
                    self.isLoggedIn = true
                }
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to create user"
                }
            }
        }.resume()
    }
    
    //func registerUser(username: String, password: String, email: String, firstName: String, lastName: String) {
    //    guard let url = URL(string: "http://your-server-ip/moneymind/registerUser.php") else {
    //        self.errorMessage = "Invalid URL"
    //        return
    //    }
    //
    //    let requestData: [String: Any] = [
    //        "username": username,
    //        "password": password,
    //        "email": email,
    //        "first_name": firstName,
    //        "last_name": lastName
    //    ]
    //
    //    guard let jsonData = try? JSONSerialization.data(withJSONObject: requestData) else {
    //        self.errorMessage = "Failed to encode request data"
    //        return
    //    }
    //
    //    var request = URLRequest(url: url)
    //    request.httpMethod = "POST"
    //    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    //    request.httpBody = jsonData
    //
    //    URLSession.shared.dataTask(with: request) { data, response, error in
    //        guard let data = data, error == nil else {
    //            DispatchQueue.main.async {
    //                self.errorMessage = "Network error"
    //            }
    //            return
    //        }
    //
    //        do {
    //            let decodedResponse = try JSONDecoder().decode(User.self, from: data)
    //            DispatchQueue.main.async {
    //                self.user = decodedResponse
    //            }
    //        } catch {
    //            DispatchQueue.main.async {
    //                self.errorMessage = "Failed to decode response: \(error.localizedDescription)"
    //            }
    //        }
    //    }.resume()
    //}

    
    // Existing loginUser method
    func loginUser(username: String, password: String) {
        guard let url = URL(string: "http://localhost:8080/api.php") else {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid URL"
            }
            return
        }

        let body: [String: Any] = ["action": "login", "username": username, "password": password]
        let jsonData = try? JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self.errorMessage = "Network error"
                }
                return
            }

            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw response: \(responseString)")
                do {
                                let response = try JSONDecoder().decode(LoginResponse.self, from: data)
                                DispatchQueue.main.async {
                                    if response.success {
                                        self.loggedInUsername = username
                                        self.isLoggedIn = true
                                        print("Login successful! Navigating...")
                                    } else {
                                        self.errorMessage = response.message
                                    }
                                }
                            } catch {
                                DispatchQueue.main.async {
                                    self.errorMessage = "Failed to parse response: \(error.localizedDescription)"
                                    print("Error decoding JSON: \(error)")
                                }
                            }
            }
        }.resume()
    }

}
//func registerUser(username: String, password: String, email: String, firstName: String, lastName: String) {
//    guard let url = URL(string: "http://your-server-ip/moneymind/registerUser.php") else {
//        self.errorMessage = "Invalid URL"
//        return
//    }
//
//    let requestData: [String: Any] = [
//        "username": username,
//        "password": password,
//        "email": email,
//        "first_name": firstName,
//        "last_name": lastName
//    ]
//
//    guard let jsonData = try? JSONSerialization.data(withJSONObject: requestData) else {
//        self.errorMessage = "Failed to encode request data"
//        return
//    }
//
//    var request = URLRequest(url: url)
//    request.httpMethod = "POST"
//    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//    request.httpBody = jsonData
//
//    URLSession.shared.dataTask(with: request) { data, response, error in
//        guard let data = data, error == nil else {
//            DispatchQueue.main.async {
//                self.errorMessage = "Network error"
//            }
//            return
//        }
//
//        do {
//            let decodedResponse = try JSONDecoder().decode(User.self, from: data)
//            DispatchQueue.main.async {
//                self.user = decodedResponse
//            }
//        } catch {
//            DispatchQueue.main.async {
//                self.errorMessage = "Failed to decode response: \(error.localizedDescription)"
//            }
//        }
//    }.resume()
//}
//class UserDataViewModel: ObservableObject {
//    @Published var user: User?
//    @Published var errorMessage: String = ""
//
//    func fetchUserData(username: String) {
//        guard let url = URL(string: "http://your-server-ip/moneymind/getUserData.php") else {
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
//                    self.errorMessage = "Network error"
//                }
//                return
//            }
//
//            do {
//                let decodedResponse = try JSONDecoder().decode(User.self, from: data)
//                DispatchQueue.main.async {
//                    self.user = decodedResponse
//                }
//            } catch {
//                DispatchQueue.main.async {
//                    self.errorMessage = "Failed to decode response: \(error.localizedDescription)"
//                }
//            }
//        }.resume()
//    }
//}
