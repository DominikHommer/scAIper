//
//  FinancialAnalysisView.swift
//  scAIper
//
//  Created by Dominik Hommer on 06.06.25.
//

import SwiftUI

/// A view that provides a financial summary based on scanned document metadata.
/// Displays total invoice costs, latest net salary, and remaining income after expenses.
struct FinancialAnalysisView: View {

    /// The view model managing metadata and computed financial values.
    @StateObject private var viewModel = FinancialAnalysisViewModel()

    var body: some View {
        VStack(spacing: 20) {

            /// Financial summary section: total invoices, salary, and net result.
            Group {
                HStack {
                    Text("Gesamtkosten (Rechnungen):")
                    Spacer()
                    Text(viewModel.totalInvoiceAmount, format: .currency(code: "EUR"))
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Neuester Nettolohn:")
                    Spacer()
                    if let salary = viewModel.latestNetSalary {
                        Text(salary, format: .currency(code: "EUR"))
                            .fontWeight(.semibold)
                    } else {
                        Text("-").foregroundColor(.secondary)
                    }
                }

                Divider().padding(.vertical, 4)

                HStack {
                    Text("Netto nach Ausgaben:")
                        .fontWeight(.bold)
                    Spacer()
                    if let remaining = viewModel.netAfterExpenses {
                        Text(remaining, format: .currency(code: "EUR"))
                            .fontWeight(.bold)
                            .foregroundColor(remaining >= 0 ? .green : .red)
                    } else {
                        Text("-").foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)

            Divider().padding(.horizontal)

            /// Detailed breakdown of invoices and payslips.
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    viewModel.rechnungSection
                    Divider().padding(.vertical, 8)
                    viewModel.lohnzettelSection
                }
                .padding(.horizontal)
            }
            /// Enables pull-to-refresh to reload metadata and validate files.
            .refreshable {
                DocumentMetadataManager.shared.validateMetadata()
                viewModel.loadMetadata()
            }

            Spacer()
        }
        .padding(.bottom, 20)
        /// Loads metadata when the view appears.
        .onAppear {
            viewModel.loadMetadata()
        }
        .navigationTitle("Finanzanalyse")
    }
}


