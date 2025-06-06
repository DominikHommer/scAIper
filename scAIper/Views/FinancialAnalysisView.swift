//  FinancialAnalysisView.swift
//  scAIper
//
//  Created by Dominik Hommer on 06.06.25.
//

import SwiftUI

struct FinancialAnalysisView: View {
    @State private var metadataList: [DocumentMetadata] = []
    
    // MARK: – Hilfsfunktion: Parst einen Währungs-String in Double
    private func parseCurrency(_ str: String) -> Double {
        let cleaned = str
            .replacingOccurrences(of: "[^0-9,\\.]", with: "", options: .regularExpression)
            .replacingOccurrences(of: ",", with: ".")
        return Double(cleaned) ?? 0
    }
    
    // MARK: – Gesamtbetrag aller Rechnungen, einmal pro fileURL
    private var totalInvoiceAmount: Double {
        // Filter: nur Rechnungen mit Schlüssel "Gesamtbetrag"
        let invoices = metadataList.filter {
            $0.documentType == .rechnung &&
            ($0.keywords?["Gesamtbetrag"] ?? "").isEmpty == false
        }
        let grouped = Dictionary(grouping: invoices, by: \.fileURL)
        let latestPerFile: [DocumentMetadata] = grouped.compactMap { (_, metas) in
            metas.max(by: { $0.lastModified < $1.lastModified })
        }
        // Summiere die Beträge
        return latestPerFile.compactMap { meta in
            meta.keywords?["Gesamtbetrag"]
        }
        .map { parseCurrency($0) }
        .reduce(0, +)
    }
    
    // MARK: – Neuester Nettolohn, einmal pro fileURL, dann global den neuesten wählen
    private var latestNetSalary: Double? {
        // Filter: nur Lohnzettel mit Schlüssel "Nettolohn"
        let payslips = metadataList.filter {
            $0.documentType == .lohnzettel &&
            ($0.keywords?["Nettolohn"] ?? "").isEmpty == false
        }
        // Gruppiere nach fileURL und nimm pro Gruppe den neuesten Eintrag
        let grouped = Dictionary(grouping: payslips, by: \.fileURL)
        let latestPerFile: [DocumentMetadata] = grouped.compactMap { (_, metas) in
            metas.max(by: { $0.lastModified < $1.lastModified })
        }
        // Aus diesen Einträgen wähle global den aktuellsten
        guard let latest = latestPerFile.max(by: { $0.lastModified < $1.lastModified }),
              let nettoString = latest.keywords?["Nettolohn"] else {
            return nil
        }
        return parseCurrency(nettoString)
    }
    
    // MARK: – Netto nach Ausgaben
    private var netAfterExpenses: Double? {
        guard let net = latestNetSalary else { return nil }
        return net - totalInvoiceAmount
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Finanzanalyse")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            // Gesamtkosten (Rechnungen)
            HStack {
                Text("Gesamtkosten (Rechnungen):")
                Spacer()
                Text(totalInvoiceAmount, format: .currency(code: "EUR"))
                    .fontWeight(.semibold)
            }
            .padding(.horizontal)
            
            // Neuester Nettolohn
            HStack {
                Text("Neuester Nettolohn:")
                Spacer()
                if let netSalary = latestNetSalary {
                    Text(netSalary, format: .currency(code: "EUR"))
                        .fontWeight(.semibold)
                } else {
                    Text("-")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            Divider()
                .padding(.horizontal)
            
            // Netto nach Ausgaben
            HStack {
                Text("Netto nach Ausgaben:")
                    .fontWeight(.bold)
                Spacer()
                if let remaining = netAfterExpenses {
                    Text(remaining, format: .currency(code: "EUR"))
                        .fontWeight(.bold)
                        .foregroundColor(remaining >= 0 ? .green : .red)
                } else {
                    Text("-")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            Divider()
                .padding(.horizontal)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // MARK: Einzelne Rechnungen (einmal pro fileURL, neueste)
                    let invoices = metadataList.filter {
                        $0.documentType == .rechnung &&
                        ($0.keywords?["Rechnungsnummer"] ?? "").isEmpty == false
                    }
                    let groupedInvoices = Dictionary(grouping: invoices, by: \.fileURL)
                    let latestInvoices = groupedInvoices.compactMap { (_, metas) in
                        metas.max(by: { $0.lastModified < $1.lastModified })
                    }
                    .sorted(by: { $0.lastModified > $1.lastModified })
                    
                    if !latestInvoices.isEmpty {
                        Text("Einzelne Rechnungen")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        ForEach(latestInvoices, id: \.fileURL) { invoice in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Rech.nr.: \(invoice.keywords?["Rechnungsnummer"] ?? "-")")
                                    Text("Datum: \(invoice.keywords?["Rechnungsdatum"] ?? "-")")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if let amtStr = invoice.keywords?["Gesamtbetrag"] {
                                    let amtVal = parseCurrency(amtStr)
                                    Text(amtVal, format: .currency(code: "EUR"))
                                        .fontWeight(.semibold)
                                } else {
                                    Text("-")
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    } else {
                        Text("Keine Rechnungen gefunden.")
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // MARK: Einzelne Lohnzettel (einmal pro fileURL, neueste 3)
                    let payslips = metadataList.filter {
                        $0.documentType == .lohnzettel &&
                        ($0.keywords?["Zeitraum"] ?? "").isEmpty == false
                    }
                    let groupedPayslips = Dictionary(grouping: payslips, by: \.fileURL)
                    let latestPayslips = groupedPayslips.compactMap { (_, metas) in
                        metas.max(by: { $0.lastModified < $1.lastModified })
                    }
                    .sorted(by: { $0.lastModified > $1.lastModified })
                    
                    if !latestPayslips.isEmpty {
                        Text("Lohnzettel (neueste 3)")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        ForEach(latestPayslips.prefix(3), id: \.fileURL) { slip in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Zeitraum: \(slip.keywords?["Zeitraum"] ?? "-")")
                                    Text("Brutto: \(slip.keywords?["Bruttolohn"] ?? "-")")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if let nettStr = slip.keywords?["Nettolohn"] {
                                    let nettVal = parseCurrency(nettStr)
                                    Text(nettVal, format: .currency(code: "EUR"))
                                        .fontWeight(.semibold)
                                } else {
                                    Text("-")
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    } else {
                        Text("Keine Lohnzettel gefunden.")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding(.bottom, 20)
        .onAppear {
            metadataList = DocumentMetadataManager.shared.loadMetadata()
        }
    }
}


