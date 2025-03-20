//
//  ExpenseOverviewView.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.03.25.
//


import SwiftUI
import Charts

struct ExpenseOverviewView: View {
    @State private var expenses: [Expense] = [
        Expense(category: "Miete", amount: 850),
        Expense(category: "Handyvertrag", amount: 30),
        Expense(category: "Streaming-Dienste", amount: 15),
        Expense(category: "Versicherung", amount: 60),
        Expense(category: "Strom", amount: 45)
    ]

    var totalExpense: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        VStack {
            Text("Monatliche Ausgaben")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            // Kreisdiagramm für Ausgaben
            Chart {
                ForEach(expenses) { expense in
                    SectorMark(angle: .value("Kosten", expense.amount), innerRadius: .ratio(0.5))
                        .foregroundStyle(by: .value("Kategorie", expense.category))
                }
            }
            .frame(height: 300)
            .padding()

            // Liste der Ausgaben
            List {
                ForEach(expenses) { expense in
                    HStack {
                        Text(expense.category)
                        Spacer()
                        Text("€\(expense.amount, specifier: "%.2f")")
                            .fontWeight(.bold)
                    }
                }
            }
        }
        .padding()
    }
}

// Modell für Ausgaben
struct Expense: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
}

#Preview {
    ExpenseOverviewView()
}
