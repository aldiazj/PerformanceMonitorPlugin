//
//  PerformanceMonitorBridging.swift
//  PerformanceMonitor
//
//  Created by Alejandro Diaz on 5/03/24.
//

import Foundation

var performanceMonitor: PerformanceMonitor?

@_cdecl("monitorDevice")
public func monitorDevice()
{
    performanceMonitor?.monitorDevice()
}

@_cdecl("startTracking")
public func startTracking()
{
    performanceMonitor = PerformanceMonitor()
}

@_cdecl("stopTracking")
public func stopTracking() -> UnsafeMutablePointer<CChar>? {
    guard let monitor = performanceMonitor else {
        return nil
    }

    let rawData = monitor.getRawData()
    let statisticsData = monitor.getStatistics()

    // Prepare the raw data
    let cpuData = rawData.cpu.map { NSNumber(value: $0) }
    let memoryData = rawData.memory.map { NSNumber(value: $0) }
    let gpuData = rawData.gpu.map { NSNumber(value: $0) }

    print("Raw CPU Data: \(cpuData)")
    print("Raw Memory Data: \(memoryData)")
    print("Raw GPU Data: \(gpuData)")

    // Prepare the statistics data
    let cpuStatistics = [
        "min": NSNumber(value: statisticsData.cpu.min),
        "max": NSNumber(value: statisticsData.cpu.max),
        "average": NSNumber(value: statisticsData.cpu.average),
        "percentile95": NSNumber(value: statisticsData.cpu.percentile95)
    ]

    let memoryStatistics = [
        "min": NSNumber(value: statisticsData.memory.min),
        "max": NSNumber(value: statisticsData.memory.max),
        "average": NSNumber(value: statisticsData.memory.average),
        "percentile95": NSNumber(value: statisticsData.memory.percentile95)
    ]

    let gpuStatistics = [
        "min": NSNumber(value: statisticsData.gpu.min),
        "max": NSNumber(value: statisticsData.gpu.max),
        "average": NSNumber(value: statisticsData.gpu.average),
        "percentile95": NSNumber(value: statisticsData.gpu.percentile95)
    ]

    print("CPU Statistics: \(cpuStatistics)")
    print("Memory Statistics: \(memoryStatistics)")
    print("GPU Statistics: \(gpuStatistics)")

    // Combine all data into a single dictionary
    let combinedData: [String: Any] = [
        "rawData": [
            "cpu": cpuData,
            "memory": memoryData,
            "gpu": gpuData
        ],
        "statistics": [
            "cpu": cpuStatistics,
            "memory": memoryStatistics,
            "gpu": gpuStatistics
        ]
    ]

    do {
        let jsonData = try JSONSerialization.data(withJSONObject: combinedData, options: [])
        let jsonString = String(data: jsonData, encoding: .utf8)!

        let cString = strdup(jsonString)
        return UnsafeMutablePointer<CChar>(cString)
    } catch {
        print("Error serializing combined data to JSON: \(error)")
        return nil
    }
}

