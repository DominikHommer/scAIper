//
//  DBSCAN.swift
//  scAIper
//
//  Created by Dominik Hommer on 08.04.25.
//


import CoreGraphics

struct DBSCAN {
    let eps: CGFloat
    let minSamples: Int

    /// Führt DBSCAN auf einem eindimensionalen Array von Werten (z. B. normierte x‑ oder y‑Koordinaten) aus.
    /// - Parameter data: Die zu clusternden Daten.
    /// - Returns: Ein Array von Cluster‑Labels (Integer). Werte -1 kennzeichnen Rauschen.
    func fit(data: [CGFloat]) -> [Int] {
        var labels = Array(repeating: -1, count: data.count)
        var visited = Array(repeating: false, count: data.count)
        var clusterId = 0
        
        // Berechnet den Nachbarschaftsbereich für den Punkt an der Position "index"
        // Für 1D‑Daten entspricht dies dem absoluten Unterschied.
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
        
        // Iteriere über alle Punkte
        for i in 0..<data.count {
            if visited[i] { continue }
            visited[i] = true
            
            let neighbors = regionQuery(index: i)
            if neighbors.count < minSamples {
                // Markiere als Rauschen
                labels[i] = -1
            } else {
                // Beginne einen neuen Cluster
                labels[i] = clusterId
                var seedSet = neighbors
                var indexInSeed = 0
                while indexInSeed < seedSet.count {
                    let current = seedSet[indexInSeed]
                    if !visited[current] {
                        visited[current] = true
                        let currentNeighbors = regionQuery(index: current)
                        if currentNeighbors.count >= minSamples {
                            // Füge neue Nachbarn hinzu, falls noch nicht in seedSet vorhanden
                            for n in currentNeighbors where !seedSet.contains(n) {
                                seedSet.append(n)
                            }
                        }
                    }
                    if labels[current] == -1 {
                        // Falls der Punkt zuvor als Rauschen klassifiziert wurde, ordne ihn jetzt dem Cluster zu.
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
