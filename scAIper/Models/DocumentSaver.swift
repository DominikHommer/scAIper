//
//  DocumentSaver.swift
//  scAIper
//
//  Created by Dominik Hommer on 21.03.25.
//


import Foundation
import UIKit

struct DocumentSaver {
    
    static func saveDocument(documentText: String, fileName: String, selectedCategory: String, fileSuffix: String) {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        print("Documents-Verzeichnis: \(documentsURL)")
        
        let categoryURL = documentsURL.appendingPathComponent(selectedCategory)
        if !fileManager.fileExists(atPath: categoryURL.path) {
            do {
                try fileManager.createDirectory(at: categoryURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Fehler beim Erstellen des Ordners: \(error)")
                return
            }
        }
        
        switch fileSuffix {
        case ".txt":
            let fileURL = categoryURL.appendingPathComponent("\(fileName).txt")
            do {
                try documentText.write(to: fileURL, atomically: true, encoding: .utf8)
                print("Dokument (.txt) gespeichert unter \(fileURL)")
            } catch {
                print("Fehler beim Speichern des Textdokuments: \(error)")
            }
            
        case ".pdf":
            let fileURL = categoryURL.appendingPathComponent("\(fileName).pdf")
            
            // A4-Format in Punkten
            let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
            // Erstelle einen PDF-Renderer mit den Seitenrändern
            let pdfRenderer = UIGraphicsPDFRenderer(bounds: pageRect)
            
            // Definiere den Text und seine Attribute
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12)
            ]
            let attributedText = NSAttributedString(string: documentText, attributes: textAttributes)
            
            // Erstelle einen CoreText-Framesetter, um den Text zu layouten
            let framesetter = CTFramesetterCreateWithAttributedString(attributedText)
            
            // Definiere den Textrahmen – hier mit Rändern und etwas Platz für die Seitenzahl am unteren Rand
            let margin: CGFloat = 20
            let availableHeightForText = pageRect.height - 2 * margin - 20  // 20 Punkte Reserve für die Seitenzahl
            let textRect = CGRect(x: margin, y: margin, width: pageRect.width - 2 * margin, height: availableHeightForText)
            
            // Ausgangsposition im Text
            var currentRange = CFRange(location: 0, length: 0)
            let totalLength = attributedText.length
            var pageNumber = 1
            
            do {
                try pdfRenderer.writePDF(to: fileURL, withActions: { context in
                    // Solange noch Text übrig ist
                    while currentRange.location < totalLength {
                        context.beginPage()
                        
                        // Erstelle einen Pfad für den Textrahmen
                        let path = CGMutablePath()
                        path.addRect(textRect)
                        
                        let frame = CTFramesetterCreateFrame(framesetter, currentRange, path, nil)
                        let cgContext = context.cgContext

                        cgContext.textMatrix = .identity
                        cgContext.translateBy(x: 0, y: pageRect.height)
                        cgContext.scaleBy(x: 1.0, y: -1.0)
                        
                        CTFrameDraw(frame, cgContext)
                        
                        cgContext.scaleBy(x: 1.0, y: -1.0)
                        cgContext.translateBy(x: 0, y: -pageRect.height)
                        
                        let pageNumberText = "Seite \(pageNumber)"
                        let paragraphStyle = NSMutableParagraphStyle()
                        paragraphStyle.alignment = .center
                        let pageNumberAttributes: [NSAttributedString.Key: Any] = [
                            .font: UIFont.systemFont(ofSize: 10),
                            .paragraphStyle: paragraphStyle
                        ]
                        let pageNumberString = NSAttributedString(string: pageNumberText, attributes: pageNumberAttributes)
                        let pageNumberSize = pageNumberString.size()
                        let pageNumberRect = CGRect(
                            x: (pageRect.width - pageNumberSize.width) / 2,
                            y: pageRect.height - margin - pageNumberSize.height,
                            width: pageNumberSize.width,
                            height: pageNumberSize.height
                        )
                        pageNumberString.draw(in: pageNumberRect)
                        let visibleRange = CTFrameGetVisibleStringRange(frame)
                        currentRange.location += visibleRange.length
                        pageNumber += 1
                    }
                })
                print("PDF-Dokument mit \(pageNumber - 1) Seiten gespeichert unter \(fileURL)")
            } catch {
                print("Fehler beim Speichern des PDF-Dokuments: \(error)")
            }
            
        case ".csv": //dummy 
            let fileURL = categoryURL.appendingPathComponent("\(fileName).csv")
            do {
                try documentText.write(to: fileURL, atomically: true, encoding: .utf8)
                print("CSV-Dokument gespeichert unter \(fileURL)")
            } catch {
                print("Fehler beim Speichern des CSV-Dokuments: \(error)")
            }
            
        default:
            print("Unbekanntes Dateiformat")
        }
    }
}
