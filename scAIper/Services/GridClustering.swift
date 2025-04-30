//
//  GridClustering.swift
//  scAIper
//
//  Created by Dominik Hommer on 09.04.25.
//


import UIKit

struct GridClustering {
    
    // Berechnet den Silhouettenwert für ein Cluster-Ergebnis.
    static func computeSilhouette(values: [CGFloat], labels: [Int]) -> CGFloat {
        let n = values.count
        var silhouetteValues = [CGFloat]()
        
        for i in 0..<n {
            let labelI = labels[i]
            if labelI == -1 { continue }
            
            // a(i): Durchschnittliche Distanz zu allen anderen Punkten im selben Cluster.
            let sameClusterIndices = (0..<n).filter { $0 != i && labels[$0] == labelI }
            let a: CGFloat = sameClusterIndices.isEmpty ? 0 : sameClusterIndices.map { abs(values[i] - values[$0]) }.reduce(0, +) / CGFloat(sameClusterIndices.count)
            
            // b(i): Minimaler durchschnittlicher Abstand zu einem anderen Cluster.
            let otherClusterLabels = Set(labels.filter { $0 != labelI && $0 != -1 })
            var bValues = [CGFloat]()
            for other in otherClusterLabels {
                let indices = (0..<n).filter { labels[$0] == other }
                if !indices.isEmpty {
                    let avgDist = indices.map { abs(values[i] - values[$0]) }.reduce(0, +) / CGFloat(indices.count)
                    bValues.append(avgDist)
                }
            }
            let b = bValues.min() ?? 0
            let s: CGFloat = (max(a, b) > 0) ? ((b - a) / max(a, b)) : 0
            silhouetteValues.append(s)
        }
        if silhouetteValues.isEmpty {
            return 0
        }
        return silhouetteValues.reduce(0, +) / CGFloat(silhouetteValues.count)
    }
    
    // Bestimmt den besten eps-Wert für DBSCAN anhand des Silhouettenwertes.
    static func bestEpsViaSilhouette(for values: [CGFloat], epsCandidates: [CGFloat], minSamples: Int = 1) -> (bestEps: CGFloat, bestScore: CGFloat) {
        var bestEps: CGFloat = epsCandidates.first ?? 0
        var bestScore: CGFloat = -1
        let group = DispatchGroup()
        let lock = NSLock()
        
        for eps in epsCandidates {
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                let dbscanInstance = DBSCAN(eps: eps, minSamples: minSamples)
                let labels = dbscanInstance.fit(data: values)
                
                let validLabels = labels.filter { $0 != -1 }
                if Set(validLabels).count >= 2 {
                    let score = computeSilhouette(values: values, labels: labels)
                    lock.lock()
                    if score > bestScore {
                        bestScore = score
                        bestEps = eps
                    }
                    lock.unlock()
                }
                group.leave()
            }
        }
        
        group.wait()
        return (bestEps, bestScore)
    }
    
    // Erzeugt eine fortlaufende Zuordnung von Labeln.
    static func continuousLabelMapping(from labels: [Int]) -> [Int: Int] {
        let uniqueLabels = Array(Set(labels)).sorted()
        var mapping: [Int: Int] = [:]
        for (newIndex, label) in uniqueLabels.enumerated() {
            mapping[label] = newIndex
        }
        return mapping
    }
    
    // Gruppiert erkannte Elemente anhand eines Abstands-Kriteriums.
    static func groupElementsByRadius(elements: [(text: String, x: CGFloat, y: CGFloat)], radius: CGFloat = 0.02) -> [[(text: String, x: CGFloat, y: CGFloat)]] {
        var groups: [[(text: String, x: CGFloat, y: CGFloat)]] = []
        var usedIndices = Set<Int>()
        for (i, element1) in elements.enumerated() {
            if usedIndices.contains(i) { continue }
            var group: [(text: String, x: CGFloat, y: CGFloat)] = [element1]
            usedIndices.insert(i)
            for (j, element2) in elements.enumerated() {
                if usedIndices.contains(j) { continue }
                let distance = hypot(element1.x - element2.x, element1.y - element2.y)
                if distance <= radius {
                    group.append(element2)
                    usedIndices.insert(j)
                }
            }
            groups.append(group)
        }
        return groups
    }
}
