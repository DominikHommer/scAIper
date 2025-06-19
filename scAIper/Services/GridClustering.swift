//
//  GridClustering.swift
//  scAIper
//
//  Created by Dominik Hommer on 09.04.25.
//

import UIKit

/// A utility struct for clustering and analyzing grid-like data,
/// such as positions of elements in a document layout.
struct GridClustering {
    
    /// Computes the average silhouette score for a given clustering result.
    ///
    /// - Parameters:
    ///   - values: The one-dimensional coordinates (e.g., x or y positions) of the data points.
    ///   - labels: The cluster labels assigned to each point by a clustering algorithm.
    /// - Returns: The mean silhouette score (from -1 to 1), where higher values indicate better-defined clusters.
    static func computeSilhouette(values: [CGFloat], labels: [Int]) -> CGFloat {
        let n = values.count
        var silhouetteValues = [CGFloat]()
        
        for i in 0..<n {
            let labelI = labels[i]
            if labelI == -1 { continue }
            
            let sameClusterIndices = (0..<n).filter { $0 != i && labels[$0] == labelI }
            let a: CGFloat = sameClusterIndices.isEmpty ? 0 :
                sameClusterIndices.map { abs(values[i] - values[$0]) }.reduce(0, +) / CGFloat(sameClusterIndices.count)
            
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
    
    /// Finds the best `eps` value from a list of candidates by maximizing the silhouette score.
    ///
    /// - Parameters:
    ///   - values: The input data for clustering (e.g., x or y positions).
    ///   - epsCandidates: List of `eps` values to test.
    ///   - minSamples: Minimum number of points to form a cluster (default is 1).
    /// - Returns: A tuple containing the best `eps` and its associated silhouette score.
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
    
    /// Remaps original cluster labels to a continuous sequence of integers.
    ///
    /// - Parameter labels: Original cluster labels (e.g., may contain -1 for noise).
    /// - Returns: A dictionary mapping old labels to new continuous labels.
    static func continuousLabelMapping(from labels: [Int]) -> [Int: Int] {
        let uniqueLabels = Array(Set(labels)).sorted()
        var mapping: [Int: Int] = [:]
        for (newIndex, label) in uniqueLabels.enumerated() {
            mapping[label] = newIndex
        }
        return mapping
    }
    
    /// Groups nearby elements into clusters based on a given distance radius.
    ///
    /// - Parameters:
    ///   - elements: An array of tuples with `text`, `x`, and `y` properties (e.g., OCR-detected words).
    ///   - radius: The maximum distance within which points are grouped together.
    /// - Returns: A list of grouped elements.
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
