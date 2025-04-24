//
//  UserData.swift
//  Moneymind
//
//  Created by Micah Wisniewski on 4/9/25.
//
import Foundation

struct User: Codable {
    var id: Int
    var username: String
    var email: String
    var balance: Double
    var income: Income
    var expenses: Expense
    
}
struct Name: Codable {
    var first: String
    var last: String
}

struct Expense: Codable, Equatable {
    var rent: Double
    var groceries: Double
    var utilities: Double
    var insurance: Double
    var gas: Double
    var miscellaneous: Double
    
    
    var total: Double {
            rent + groceries + utilities + insurance + gas + miscellaneous
        }

    
    static func ==(lhs: Expense, rhs: Expense) -> Bool {
        return lhs.rent == rhs.rent &&
               lhs.groceries == rhs.groceries &&
               lhs.utilities == rhs.utilities &&
               lhs.insurance == rhs.insurance &&
               lhs.gas == rhs.gas &&
               lhs.miscellaneous == rhs.miscellaneous
    }


    init(rent: Double, groceries: Double, utilities: Double, insurance: Double, gas: Double, miscellaneous: Double) {
        self.rent = rent
        self.groceries = groceries
        self.utilities = utilities
        self.insurance = insurance
        self.gas = gas
        self.miscellaneous = miscellaneous
    }

    func withUpdatedRent(_ newRent: Double) -> Expense {
        return Expense(rent: newRent, groceries: groceries, utilities: utilities, insurance: insurance, gas: gas, miscellaneous: miscellaneous)
    }

    func withUpdatedGroceries(_ newGroceries: Double) -> Expense {
        return Expense(rent: rent, groceries: newGroceries, utilities: utilities, insurance: insurance, gas: gas, miscellaneous: miscellaneous)
    }

    func withUpdatedUtilities(_ newUtilities: Double) -> Expense {
        return Expense(rent: rent, groceries: groceries, utilities: newUtilities, insurance: insurance, gas: gas, miscellaneous: miscellaneous)
    }

    func withUpdatedInsurance(_ newInsurance: Double) -> Expense {
        return Expense(rent: rent, groceries: groceries, utilities: utilities, insurance: newInsurance, gas: gas, miscellaneous: miscellaneous)
    }

    func withUpdatedGas(_ newGas: Double) -> Expense {
        return Expense(rent: rent, groceries: groceries, utilities: utilities, insurance: insurance, gas: newGas, miscellaneous: miscellaneous)
    }

    func withUpdatedMiscellaneous(_ newMiscellaneous: Double) -> Expense {
        return Expense(rent: rent, groceries: groceries, utilities: utilities, insurance: insurance, gas: gas, miscellaneous: newMiscellaneous)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        print("decoding")
        do {
            // Convert possible string values into doubles
            rent = Double(try container.decode(String.self, forKey: .rent)) ?? 0.0
            groceries = Double(try container.decode(String.self, forKey: .groceries)) ?? 0.0
            utilities = Double(try container.decode(String.self, forKey: .utilities)) ?? 0.0
            insurance = Double(try container.decode(String.self, forKey: .insurance)) ?? 0.0
            gas = Double(try container.decode(String.self, forKey: .gas)) ?? 0.0
            miscellaneous = Double(try container.decode(String.self, forKey: .miscellaneous)) ?? 0.0
            print("rent:", type(of: rent))
            print(rent, groceries, utilities, insurance, gas, miscellaneous)
        }catch {
            print("Decoding failed for Expense struct: \(error)")
            throw error  // Re-throw the error so you see it in SwiftUI logs
        }


    }

}





struct Income: Codable, Equatable {
    var job: Double
    var realEstate: Double
    var investments: Double
    
    var total: Double {
            job + realEstate + investments
        }
    
    static func ==(lhs: Income, rhs: Income) -> Bool {
        return lhs.job == rhs.job &&
        lhs.realEstate == rhs.realEstate &&
        lhs.investments == rhs.investments
    }
    
    init(job: Double, realEstate: Double, investments: Double) {
        self.job = job
        self.realEstate = realEstate
        self.investments = investments
    }

    func withUpdatedJob(_ newValue: Double) -> Income {
        return Income(job: newValue, realEstate: realEstate, investments: investments)
    }

    func withUpdatedRealEstate(_ newValue: Double) -> Income {
        return Income(job: job, realEstate: newValue, investments: investments)
    }

    func withUpdatedInvestments(_ newValue: Double) -> Income {
        return Income(job: job, realEstate: realEstate, investments: newValue)
    }
    
    enum CodingKeys: String, CodingKey {
        case job = "Job"
        case realEstate = "RealEstate"
        case investments = "Investments"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Try to decode each field as a String, and convert it to Double
        job = Double(try container.decode(String.self, forKey: .job).trimmingCharacters(in: .whitespaces)) ?? 0.0
        realEstate = Double(try container.decode(String.self, forKey: .realEstate).trimmingCharacters(in: .whitespaces)) ?? 0.0
        investments = Double(try container.decode(String.self, forKey: .investments).trimmingCharacters(in: .whitespaces)) ?? 0.0
        
        // Optionally, you can throw an error here if all values default to 0.0, as that might indicate an invalid response
//        if job == 0.0 && realEstate == 0.0 && investments == 0.0 {
//            throw DecodingError.dataCorruptedError(forKey: .job, in: container, debugDescription: "Invalid income data received")
//        }
    }
}

