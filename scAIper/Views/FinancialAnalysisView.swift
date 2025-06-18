//
//  FinancialAnalysisView.swift
//  scAIper
//
//  Created by Dominik Hommer on 06.06.25.
//

import SwiftUI

struct FinancialAnalysisView: View {
    @State private var metadataList: [DocumentMetadata] = []

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        return f
    }()

    private func parseCurrency(_ str: String) -> Double {
        let filtered = str.filter { "0123456789,.".contains($0) }
        let noThousands = filtered.replacingOccurrences(of: ".", with: "")
        let normalized = noThousands.replacingOccurrences(of: ",", with: ".")
        if let val = Double(normalized) {
            return val
        } else {
            print("Failed to parse currency from string: '\(str)' filtered as: '\(filtered)', normalized as: '\(normalized)'")
            return 0
        }
    }

    private var totalInvoiceAmount: Double {
        let invoices = metadataList.filter {
            $0.documentType == .rechnung &&
            ($0.keywords?["Gesamtbetrag"] ?? "").isEmpty == false
        }
        let latestPerFile = Dictionary(grouping: invoices, by: \.fileURL)
            .compactMap { $0.value.max(by: { $0.lastModified < $1.lastModified }) }

        return latestPerFile
            .compactMap { $0.keywords?["Gesamtbetrag"] }
            .map(parseCurrency)
            .reduce(0, +)
    }

    private var latestNetSalary: Double? {
        let payslips = metadataList.filter {
            $0.documentType == .lohnzettel &&
            ($0.keywords?["Nettolohn"] ?? "").isEmpty == false
        }
        let latestPerFile = Dictionary(grouping: payslips, by: \.fileURL)
            .compactMap { $0.value.max(by: { $0.lastModified < $1.lastModified }) }
        guard
            let latest = latestPerFile.max(by: { $0.lastModified < $1.lastModified }),
            let nettoString = latest.keywords?["Nettolohn"]
        else {
            return nil
        }
        return parseCurrency(nettoString)
    }

    private var netAfterExpenses: Double? {
        guard let net = latestNetSalary else { return nil }
        return net - totalInvoiceAmount
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    // Einzelne Rechnungen (neueste pro Datei)
                    let invoiceEntries = metadataList.filter {
                        $0.documentType == .rechnung &&
                        ($0.keywords?["Gesamtbetrag"] ?? "").isEmpty == false
                    }
                    let latestInvoices = Dictionary(grouping: invoiceEntries, by: \.fileURL)
                        .compactMap { $0.value.max(by: { $0.lastModified < $1.lastModified }) }
                        .sorted(by: { $0.lastModified > $1.lastModified })

                    if latestInvoices.isEmpty {
                        Text("Keine Rechnungen gefunden.")
                            .foregroundColor(.secondary)
                    } else {
                        Text("Einzelne Rechnungen")
                            .font(.headline)

                        ForEach(latestInvoices, id: \.fileURL) { inv in
                            let rawNumber = inv.keywords?["Rechnungsnummer"] ?? ""
                            let numberText = rawNumber.isEmpty ? "-" : rawNumber

                            let rawDate = inv.keywords?["Rechnungsdatum"] ?? ""
                            let dateText = rawDate.isEmpty
                                ? dateFormatter.string(from: inv.lastModified)
                                : rawDate

                            let amount = parseCurrency(inv.keywords?["Gesamtbetrag"] ?? "0")

                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Rech.nr.: \(numberText)")
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

                    // Übersicht Rechnungen unter den Einträgen
                    Divider().padding(.vertical, 8)
                    HStack {
                        Text("Gesamtkosten (Rechnungen):")
                            .fontWeight(.bold)
                        Spacer()
                        Text(totalInvoiceAmount, format: .currency(code: "EUR"))
                            .fontWeight(.bold)
                    }
                    Divider().padding(.vertical, 8)

                    // Lohnzettel (neueste 3 pro Datei)
                    let payslipEntries = metadataList.filter {
                        $0.documentType == .lohnzettel &&
                        ($0.keywords?["Zeitraum"] ?? "").isEmpty == false
                    }
                    let latestPayslips = Dictionary(grouping: payslipEntries, by: \.fileURL)
                        .compactMap { $0.value.max(by: { $0.lastModified < $1.lastModified }) }
                        .sorted(by: { $0.lastModified > $1.lastModified })

                    if latestPayslips.isEmpty {
                        Text("Keine Lohnzettel gefunden.")
                            .foregroundColor(.secondary)
                    } else {
                        Text("Lohnzettel (neueste 3)")
                            .font(.headline)

                        ForEach(latestPayslips.prefix(3), id: \.fileURL) { slip in
                            let period = slip.keywords?["Zeitraum"] ?? "-"
                            let brutto = slip.keywords?["Bruttolohn"] ?? "-"
                            let nett = parseCurrency(slip.keywords?["Nettolohn"] ?? "0")

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

                    // Übersicht Lohnzettel unter den Einträgen
                    Divider().padding(.vertical, 8)
                    HStack {
                        Text("Neuester Nettolohn:")
                            .fontWeight(.bold)
                        Spacer()
                        if let salary = latestNetSalary {
                            Text(salary, format: .currency(code: "EUR"))
                                .fontWeight(.bold)
                        } else {
                            Text("-").foregroundColor(.secondary)
                        }
                    }
                    Divider().padding(.vertical, 8)
                    HStack {
                        Text("Netto nach Ausgaben:")
                            .fontWeight(.bold)
                        Spacer()
                        if let remaining = netAfterExpenses {
                            Text(remaining, format: .currency(code: "EUR"))
                                .fontWeight(.bold)
                                .foregroundColor(remaining >= 0 ? .green : .red)
                        } else {
                            Text("-").foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 20)
            .onAppear {
                metadataList = DocumentMetadataManager.shared.loadMetadata()
            }
            .navigationTitle("Finanzanalyse")
        }
    }
}
