//
//  PerformanceMonitor.swift
//  PerformanceMonitor
//
//  Created by Alejandro Diaz on 5/03/24.
//

import Foundation
import MachO

public class PerformanceMonitor {
    private var cpuUsageInfo: [Double] = []
    private var memoryUsageInfo: [Double] = []
    private var gpuUsageInfo: [Double] = []
    
    public func monitorDevice() {
        cpuUsageInfo.append(getCurrentCPUUsage())
        memoryUsageInfo.append(getCurrentMemoryUsage())
    }
    
    func getCurrentCPUUsage() -> Double {
        var totalUsageOfCPU: Double = 0.0
        var threadsList = UnsafeMutablePointer<thread_act_t>(bitPattern: 0)
        var threadsCount = mach_msg_type_number_t(0)

        let threadsResult = withUnsafeMutablePointer(to: &threadsList) {
            return $0.withMemoryRebound(to: thread_act_array_t?.self, capacity: 1) {
                task_threads(mach_task_self_, $0, &threadsCount)
            }
        }
        
        if threadsResult == KERN_SUCCESS {
            for index in 0..<Int(threadsCount) {
                var threadInfo = thread_basic_info()
                var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
                
                let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                        thread_info(threadsList![index], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
                    }
                }
                
                if infoResult == KERN_SUCCESS {
                    let threadBasicInfo = threadInfo as thread_basic_info
                    if threadBasicInfo.flags & TH_FLAGS_IDLE == 0 {
                        totalUsageOfCPU += (Double(threadBasicInfo.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0)
                    }
                }
            }
            
            // Deallocate the memory allocated by task_threads
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threadsList), vm_size_t(threadsCount * UInt32(MemoryLayout<thread_act_t>.stride)))
        }
        
        return totalUsageOfCPU
    }
    
    private func getCurrentMemoryUsage() -> Double {
        var info = task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            // Resident size is in info.resident_size; convert to MB
            return Double(info.resident_size) / 1024 / 1024
        } else {
            print("Error with task_info(): \(kerr)")
            return 0.0
        }
    }
    
    private func getCurrentGPUUsage() -> Double {
        // This is a placeholder. Actual GPU monitoring is significantly limited on iOS.
        // You might want to look into specific metrics or indirect ways to gauge GPU usage.
        return 0.0
    }
    
    public func getStatistics() -> (cpu: (min: Double, max: Double, average: Double, percentile95: Double), memory: (min: Double, max: Double, average: Double, percentile95: Double), gpu: (min: Double, max: Double, average: Double, percentile95: Double)) {
        return (cpu: calculateStatistics(for: cpuUsageInfo),
                memory: calculateStatistics(for: memoryUsageInfo),
                gpu: calculateStatistics(for: gpuUsageInfo))
    }
    
    public func getRawData() -> (cpu: [Double], memory: [Double], gpu: [Double]) {
        return (cpu: cpuUsageInfo, memory: memoryUsageInfo, gpu: gpuUsageInfo)
    }
    
    private func calculateStatistics(for data: [Double]) -> (min: Double, max: Double, average: Double, percentile95: Double) {
        let sortedData = data.sorted()
        let min = sortedData.first ?? 0.0
        let max = sortedData.last ?? 0.0
        let avg = data.isEmpty ? 0.0 : data.reduce(0, +) / Double(data.count)
        
        let percentileIndex = Int(ceil(0.95 * Double(sortedData.count))) - 1
        let safeIndex = Swift.min(percentileIndex, sortedData.count - 1) // Ensure the index is not beyond the array length
        let finalIndex = Swift.max(0, safeIndex) // Ensure the index is not negative
        let percentile95 = percentileIndex >= 0 ? sortedData[finalIndex] : 0.0
        
        return (min, max, avg, percentile95)
    }
}

