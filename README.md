# scAIper 

**scAIper** ist eine SwiftUI-App zur automatisierten Dokumentanalyse mit integrierter OCR, Tabellenextraktion und KI-gestützter Auswertung von Verträgen, Rechnungen und Gehaltsabrechnungen. Die App ermöglicht es, strukturierte Daten aus gescannten Dokumenten zu extrahieren und diese mit Hilfe eines eingebauten Chatbots zu analysieren.

## 📄 Dokumentation

Die vollständige Entwickler- und Benutzer­dokumentation ist verfügbar unter:

👉 [https://dominikhommer.github.io/scAIper/documentation/scaiper](https://dominikhommer.github.io/scAIper/documentation/scaiper)


### Funktionen

- **Digitalisierung von Dokumenten:** Scanne deine Papierdokumente und verwalte sie direkt in der App.
- **OCR mit präziser Positionierung:** Extrahiert Text aus gescannten Bildern und platziert ihn exakt an der richtigen Stelle im generierten PDF.
- **Schlüsselwort-Extraktion:** Erkennt automatisch wichtige Informationen wie Rechnungsnummern, Beträge, Daten und Gehaltsangaben.
- **Chunking:** Zerlegt unstrukturierte oder halbstrukturierte Texte in sinnvolle Abschnitte zur einfacheren Analyse.
- **Tabellenrekonstruktion:** Stellt tabellarische Strukturen aus gescannten Dokumentfragmenten wieder her.
- **KI-Chatbot:** Ermöglicht natürliche Sprachabfragen zu den Inhalten der Dokumente.
- **Embeddings und Ähnlichkeitssuche:** Nutzt ML-Modelle zur semantischen Einbettung und zum Vergleich ähnlicher Inhalte.
- **Unterstützung mehrerer Dokumenttypen:** Rechnungen, Lohnzettel, Verträge usw.

### Voraussetzungen

- **Xcode** (empfohlen: aktuelle stabile Version)
- **iOS 18.3** oder neuer als Deployment-Target
- **API-Schlüssel:**

  - Ein kostenloser API-Key für GroqCloud
  - HuggingFace API-Key für Embeddings und Ähnlichkeitssuche
  - **Diese Schlüssel müssen in einer Datei `key.xcconfig` im Projekt konfiguriert werden.**
    Beispiel `key.xcconfig`:
    ```xcconfig
    GROQ_API_KEY=dein_groq_api_key
    HF_API_KEY=dein_huggingface_api_key
    ```

    #### Einbindung in Xcode:
    1. Füge die Datei `key.xcconfig` zum Projekt hinzu.
    2. Öffne dein Projekt in Xcode.
    3. Gehe zu den **Projekteinstellungen** → Tab **Info** → Bereich **Configurations**.
    4. Weise `key.xcconfig` der Debug- und/oder Release-Konfiguration zu.
    5. Greife im Swift-Code auf die Schlüssel zu über:
       ```swift
       let groqKey = ProcessInfo.processInfo.environment["GROQ_API_KEY"]
       ```

### Einrichtung und Ausführung

- Mit `Cmd + R` in Xcode bauen und starten.
- Test auf dem iOS-Simulator oder einem echten Gerät.
- Beim ersten Start auf einem echten Gerät:

  - iPhone per USB-C anschließen und Entwickleraccount auf dem Gerät unter **Einstellungen -> Allgemein -> VPN & Geräteverwaltung** vertrauen.
  - Sicherstellen, dass sich Gerät und Mac im selben Netzwerk befinden (für drahtloses Debugging).



