//
//  FinancialAnalysisViewModel.swift
//  scAIper
//
//  Created by Dominik Hommer on 19.06.25.
//

import SwiftUI

/// ViewModel responsible for calculating and formatting financial data
/// based on the scanned document metadata.
final class FinancialAnalysisViewModel: ObservableObject {
    
    /// List of metadata entries for documents.
    @Published var metadataList: [DocumentMetadata] = []

    /// A `DateFormatter` used for formatting date displays.
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        return f
    }()

    /// Loads metadata from the shared DocumentMetadataManager.
    func loadMetadata() {
        metadataList = DocumentMetadataManager.shared.loadMetadata()
    }

    /// Calculates the total sum of the latest invoices per document.
    var totalInvoiceAmount: Double {
        let invoices = metadataList.filter {
            $0.documentType == .rechnung && !($0.keywords?["Gesamtbetrag"] ?? "").isEmpty
        }
        let latestPerFile = Dictionary(grouping: invoices, by: \.fileURL)
            .compactMap { $0.value.max(by: { $0.lastModified < $1.lastModified }) }

        return latestPerFile
            .compactMap { $0.keywords?["Gesamtbetrag"] }
            .map(parseCurrency)
            .reduce(0, +)
    }

    /// Retrieves the most recent net salary from payslip metadata.
    var latestNetSalary: Double? {
        let payslips = metadataList.filter {
            $0.documentType == .lohnzettel && !($0.keywords?["Nettolohn"] ?? "").isEmpty
        }
        let latestPerFile = Dictionary(grouping: payslips, by: \.fileURL)
            .compactMap { $0.value.max(by: { $0.lastModified < $1.lastModified }) }
        guard let latest = latestPerFile.max(by: { $0.lastModified < $1.lastModified }),
              let nettoString = latest.keywords?["Nettolohn"] else {
            return nil
        }
        return parseCurrency(nettoString)
    }

    /// Computes the remaining amount after subtracting invoice total from net salary.
    var netAfterExpenses: Double? {
        guard let net = latestNetSalary else { return nil }
        return net - totalInvoiceAmount
    }

    /// Generates a view section summarizing individual invoice entries.
    var rechnungSection: some View {
        let invoiceEntries = metadataList.filter {
            $0.documentType == .rechnung && !($0.keywords?["Gesamtbetrag"] ?? "").isEmpty
        }
        let latestInvoices = Dictionary(grouping: invoiceEntries, by: \.fileURL)
            .compactMap { $0.value.max(by: { $0.lastModified < $1.lastModified }) }
            .sorted(by: { $0.lastModified > $1.lastModified })

        return Group {
            if latestInvoices.isEmpty {
                Text("Keine Rechnungen gefunden.").foregroundColor(.secondary)
            } else {
                Text("Einzelne Rechnungen").font(.headline)

                ForEach(latestInvoices, id: \.fileURL) { inv in
                    let rawNumber = inv.keywords?["Rechnungsnummer"] ?? "-"
                    let rawDate = inv.keywords?["Rechnungsdatum"] ?? ""
                    let dateText = rawDate.isEmpty
                    ? self.dateFormatter.string(from: inv.lastModified)
                        : rawDate
                    let amount = self.parseCurrency(inv.keywords?["Gesamtbetrag"] ?? "0")

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Rech.nr.: \(rawNumber)")
                            Text("Datum: \(dateText)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(amount, format: .currency(code: "EUR"))
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    /// Generates a view section summarizing the latest payslip entries.
    var lohnzettelSection: some View {
        let payslipEntries = metadataList.filter {
            $0.documentType == .lohnzettel && !($0.keywords?["Zeitraum"] ?? "").isEmpty
        }
        let latestPayslips = Dictionary(grouping: payslipEntries, by: \.fileURL)
            .compactMap { $0.value.max(by: { $0.lastModified < $1.lastModified }) }
            .sorted(by: { $0.lastModified > $1.lastModified })

        return Group {
            if latestPayslips.isEmpty {
                Text("Keine Lohnzettel gefunden.").foregroundColor(.secondary)
            } else {
                Text("Lohnzettel (neueste 3)").font(.headline)

                ForEach(latestPayslips.prefix(3), id: \.fileURL) { slip in
                    let period = slip.keywords?["Zeitraum"] ?? "-"
                    let brutto = slip.keywords?["Bruttolohn"] ?? "-"
                    let nett = self.parseCurrency(slip.keywords?["Nettolohn"] ?? "0")

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Zeitraum: \(period)")
                            Text("Brutto: \(brutto)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(nett, format: .currency(code: "EUR"))
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    /// Parses a localized currency string and returns its numeric `Double` value.
    /// - Parameter str: A string containing a currency amount.
    /// - Returns: A `Double` representation of the currency value.
    private func parseCurrency(_ str: String) -> Double {
        let filtered = str.filter { "0123456789,.".contains($0) }
        let noThousands = filtered.replacingOccurrences(of: ".", with: "")
        let normalized = noThousands.replacingOccurrences(of: ",", with: ".")
        return Double(normalized) ?? 0
    }
}

