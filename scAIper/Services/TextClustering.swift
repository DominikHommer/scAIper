//
//  TextClustering.swift
//  scAIper
//
//  Created by Dominik Hommer on 20.03.25.
//


import Vision
import UIKit

extension OCRManager {
    
    static func clusterObservations(
        _ observations: [VNRecognizedTextObservation],
        imageSize: CGSize,
        distanceThreshold: CGFloat,
        overlapRatioThreshold: CGFloat
    ) -> [[VNRecognizedTextObservation]] {
        
        var unvisited = observations
        var clusters: [[VNRecognizedTextObservation]] = []
        
        while let currentObs = unvisited.first {
            var queue = [currentObs]
            var cluster: [VNRecognizedTextObservation] = []
            unvisited.removeAll { $0 == currentObs }
            
            while !queue.isEmpty {
                let obs = queue.removeFirst()
                cluster.append(obs)
                
                // Nachbarn suchen
                let neighbors = unvisited.filter {
                    isConnected(
                        obs,
                        $0,
                        imageSize: imageSize,
                        distanceThreshold: distanceThreshold,
                        overlapRatioThreshold: overlapRatioThreshold
                    )
                }
                
                for neighbor in neighbors {
                    queue.append(neighbor)
                    unvisited.removeAll { $0 == neighbor }
                }
            }
            clusters.append(cluster)
        }
        
        return clusters
    }
    
    private static func isConnected(
        _ obsA: VNRecognizedTextObservation,
        _ obsB: VNRecognizedTextObservation,
        imageSize: CGSize,
        distanceThreshold: CGFloat,
        overlapRatioThreshold: CGFloat
    ) -> Bool {
        let rectA = rectForObservation(obsA, in: imageSize)
        let rectB = rectForObservation(obsB, in: imageSize)
        
        let centerA = CGPoint(x: rectA.midX, y: rectA.midY)
        let centerB = CGPoint(x: rectB.midX, y: rectB.midY)
        let distance = hypot(centerA.x - centerB.x, centerA.y - centerB.y)
        
        if distance < distanceThreshold {
            return true
        }
        
        let intersection = rectA.intersection(rectB)
        if intersection.isNull || intersection.isEmpty {
            return false
        }
        
        let intersectionArea = intersection.width * intersection.height
        let areaA = rectA.width * rectA.height
        let areaB = rectB.width * rectB.height
        let minArea = min(areaA, areaB)
        let overlapRatio = intersectionArea / minArea
        
        return overlapRatio >= overlapRatioThreshold
    }
    
    static func buildOutputString(
        from clusters: [[VNRecognizedTextObservation]]
    ) -> String {
        var result = ""
        for (index, cluster) in clusters.enumerated() {
            let recognizedStrings = cluster.compactMap {
                $0.topCandidates(1).first?.string
            }
            result += "Struktur #\(index + 1):\n"
            result += recognizedStrings.joined(separator: "\n")
            result += "\n\n"
        }
        return result
    }
    
    private static func rectForObservation(
        _ obs: VNRecognizedTextObservation,
        in size: CGSize
    ) -> CGRect {
        let box = obs.boundingBox
        let x = box.origin.x * size.width
        let y = (1.0 - box.origin.y - box.height) * size.height
        let w = box.width * size.width
        let h = box.height * size.height
        return CGRect(x: x, y: y, width: w, height: h)
    }
}
