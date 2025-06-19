//
//  DBSCAN.swift
//  scAIper
//
//  Created by Dominik Hommer on 08.04.25.
//

import CoreGraphics

/// A lightweight 1D implementation of the DBSCAN clustering algorithm.
///
/// This version operates on one-dimensional data (i.e., `[CGFloat]`) and is useful
/// for clustering values such as positions or coordinates.
///
/// DBSCAN is a density-based clustering algorithm that groups together points
/// that are closely packed together and marks points in low-density regions as outliers.
struct DBSCAN {
    /// Maximum distance between two points to be considered neighbors.
    let eps: CGFloat
    
    /// Minimum number of neighbors (including the point itself) required to form a cluster.
    let minSamples: Int
    
    /// Applies the DBSCAN algorithm to a one-dimensional dataset.
    ///
    /// - Parameter data: An array of `CGFloat` values to cluster.
    /// - Returns: An array of cluster labels. Each element corresponds to a data point:
    ///   - Non-negative integers indicate cluster membership.
    ///   - `-1` indicates a noise point (not part of any cluster).
    func fit(data: [CGFloat]) -> [Int] {
        var labels = Array(repeating: -1, count: data.count)
        var visited = Array(repeating: false, count: data.count)
        var clusterId = 0
        
        /// Finds all points in the dataset within `eps` of the point at the given index.
        ///
        /// - Parameter index: Index of the point to query.
        /// - Returns: A list of indices that are neighbors of the given point.
        func regionQuery(index: Int) -> [Int] {
            let point = data[index]
            var neighbors: [Int] = []
            for (j, value) in data.enumerated() {
                if abs(value - point) <= eps {
                    neighbors.append(j)
                }
            }
            return neighbors
        }
        
        for i in 0..<data.count {
            if visited[i] { continue }
            visited[i] = true
            
            let neighbors = regionQuery(index: i)
            if neighbors.count < minSamples {
                labels[i] = -1 // Mark as noise
            } else {
                labels[i] = clusterId
                var seedSet = neighbors
                var indexInSeed = 0
                
                // Expand cluster
                while indexInSeed < seedSet.count {
                    let current = seedSet[indexInSeed]
                    if !visited[current] {
                        visited[current] = true
                        let currentNeighbors = regionQuery(index: current)
                        if currentNeighbors.count >= minSamples {
                            for n in currentNeighbors where !seedSet.contains(n) {
                                seedSet.append(n)
                            }
                        }
                    }
                    if labels[current] == -1 {
                        labels[current] = clusterId
                    }
                    indexInSeed += 1
                }
                clusterId += 1
            }
        }
        return labels
    }
}

