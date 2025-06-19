# ``scAIper``

`scAIper` is an iOS app designed to scan, extract, and analyze documents such as invoices, contracts, payslips, and reports using advanced OCR and AI-based natural-language processing techniques.

@Metadata {
@PageImage(
purpose: icon,
source: "logo",
alt: "An icon representing the scAIper framework."
)
@PageColor(blue)
}

## Overview

The app transforms physical paper documents into digital blueprints by performing optical character recognition (OCR), extracting structured information, and allowing users to interact with the content via an AI-powered chatbot.

### Features
- **Digitalisation of Documents:** Scan your paper Documents and have it in the App
- **OCR with precise positioning:** Extracts text from scanned images and places it exactly at the correct position in a generated PDF.
- **Keyword extraction:** Automatically identifies key information such as invoice numbers, amounts, dates, and salary details.
- **Chunking:** Splits unstructured or semi-structured texts into meaningful chunks for easier analysis.
- **Table reconstruction:** Rebuilds tabular structures from scanned document fragments.
- **AI chatbot:** Enables natural language queries about document contents.
- **Embedding and similarity search:** Uses machine learning models to create semantic embeddings and perform similarity comparisons.
- **Multiple document types supported:** Invoices, payslips, contracts, etc.

### Requirements

- **Xcode** (latest stable version recommended)
- **iOS 18.3** or later as deployment target
- **API keys:**

  - A free API key for the GroqCloud
  - HuggingFace API key for embeddings and similarity search
  - **These keys must be configured in a `key.xcconfig` file in your project.**

### Setup and Running

- Build and run with `Cmd + R` in Xcode.
- Test on the iOS Simulator or a real device.
- For first run on a device:

  - Connect iPhone via USB-C and trust developer account, on the device, in **Settings -> General -> VPN & Device Management**.
  - Ensure device and Mac are on the same network for wireless debugging.
