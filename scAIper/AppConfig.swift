//
//  AppConfig.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.06.25.
//

import Foundation

/// Central configuration struct holding API endpoints, model names, and API keys
/// for various AI services used throughout the app.
struct AppConfig {
    
    // MARK: - OpenAI / Groq Chat Endpoints & Models
    
    struct Chat {
        /// Endpoint URL for Groq OpenAI-compatible chat completions API
        static let endpoint = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
        
        /// Model identifier used specifically for document check tasks (yes/no questions)
        static let docCheckModel = "meta-llama/llama-4-maverick-17b-128e-instruct"
        
        /// Model identifier used for free-form chat completions
        static let completionModel = "meta-llama/llama-4-maverick-17b-128e-instruct"
        
        /// Retrieves the Groq API key from the app's Info.plist file
        static var apiKey: String {
            Bundle.main.infoDictionary?["GROQ_API_KEY"] as? String ?? ""
        }
    }
    
    // MARK: - Chunking LLM Configuration
    
    struct Chunking {
        /// Model used for chunking long texts into meaningful segments
        static let model = "meta-llama/llama-4-maverick-17b-128e-instruct"
        /// Endpoint for chunking requests, reusing chat endpoint
        static let endpoint = Chat.endpoint
        
        /// API key for chunking service (Groq API key)
        static var apiKey: String {
            Bundle.main.infoDictionary?["GROQ_API_KEY"] as? String ?? ""
        }
    }
    
    // MARK: - Keyword Extraction Configuration
    
    struct Keywords {
        /// Model used for keyword extraction from OCR text
        static let model = "meta-llama/llama-4-maverick-17b-128e-instruct"
        /// Endpoint for keyword extraction requests, reusing chat endpoint
        static let endpoint = Chat.endpoint
        
        /// API key for keyword extraction service (Groq API key)
        static var apiKey: String {
            Bundle.main.infoDictionary?["GROQ_API_KEY"] as? String ?? ""
        }
    }
    
    // MARK: - HuggingFace Embeddings & Similarity Services
    
    struct HF {
        /// URL for HuggingFace embedding pipeline
        static let embeddingURL = URL(string:
            "https://router.huggingface.co/hf-inference/models/sentence-transformers/all-MiniLM-L6-v2/pipeline/feature-extraction"
        )!
        
        /// URL for HuggingFace sentence similarity pipeline
        static let similarityURL = URL(string:
            "https://router.huggingface.co/hf-inference/models/sentence-transformers/all-MiniLM-L6-v2/pipeline/sentence-similarity"
        )!
        
        /// API key for HuggingFace services
        static var apiKey: String {
            Bundle.main.infoDictionary?["HUGGINGFACE_API_KEY"] as? String ?? ""
        }
    }
    
    // MARK: - Structure LLM Configuration
    
    struct Structure {
        /// Endpoint URL for structural LLM requests (reuses chat endpoint)
        static let endpoint = Chat.endpoint
        /// Model identifier for structural LLM tasks (e.g., table structure reconstruction)
        static let model = "meta-llama/llama-4-maverick-17b-128e-instruct"
        
        /// API key for structural LLM service (Groq API key)
        static var apiKey: String {
            Bundle.main.infoDictionary?["GROQ_API_KEY"] as? String ?? ""
        }
    }
}

