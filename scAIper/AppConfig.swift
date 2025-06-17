//
//  AppConfig.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.06.25.
//

import Foundation

struct AppConfig {
    
    // – OpenAI / Groq Chat Endpoints & Modelle
    
    struct Chat {
        static let endpoint = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
        
        // Model für Document Check (ja/nein)
        static let docCheckModel = "meta-llama/llama-4-maverick-17b-128e-instruct"
        
        // Model für freie Chat-Komplettierung
        static let completionModel = "meta-llama/llama-4-maverick-17b-128e-instruct"
        
        // Groq API-Key aus Info.plist
        static var apiKey: String {
            Bundle.main.infoDictionary?["GROQ_API_KEY"] as? String ?? ""
        }
    }
    
    // – Chunking LLM
    
    struct Chunking {
        static let model = "meta-llama/llama-4-maverick-17b-128e-instruct"
        static let endpoint = Chat.endpoint
        
        static var apiKey: String {
            Bundle.main.infoDictionary?["GROQ_API_KEY"] as? String ?? ""
        }
    }
    
    struct Keywords {
        static let model = "meta-llama/llama-4-maverick-17b-128e-instruct"
        static let endpoint = Chat.endpoint
        
        static var apiKey: String {
            Bundle.main.infoDictionary?["GROQ_API_KEY"] as? String ?? ""
        }
    }
    
    // – HuggingFace Embeddings & Similarity
    
    struct HF {
        static let embeddingURL = URL(string:
            "https://router.huggingface.co/hf-inference/models/sentence-transformers/all-MiniLM-L6-v2/pipeline/feature-extraction"
        )!
        
        static let similarityURL = URL(string:
            "https://router.huggingface.co/hf-inference/models/sentence-transformers/all-MiniLM-L6-v2/pipeline/sentence-similarity"
        )!
        
        static var apiKey: String {
            Bundle.main.infoDictionary?["HUGGINGFACE_API_KEY"] as? String ?? ""
        }
    }
        
    struct Structure {
        static let endpoint = Chat.endpoint
        static let model = "meta-llama/llama-4-maverick-17b-128e-instruct"
        static var apiKey: String {
            Bundle.main.infoDictionary?["GROQ_API_KEY"] as? String ?? ""
        }
    }

}
