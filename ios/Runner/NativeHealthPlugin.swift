import Flutter
import UIKit
import HealthKit

class NativeHealthPlugin: NSObject {

    private let store = HKHealthStore()

    private static var _channel: FlutterMethodChannel?
    private static var _instance: NativeHealthPlugin?



    @objc static func setup(messenger: FlutterBinaryMessenger) {
        guard _channel == nil else { return }
        let ch = FlutterMethodChannel(
            name: "com.healife.app/native_health",
            binaryMessenger: messenger
        )
        let instance = NativeHealthPlugin()
        ch.setMethodCallHandler { call, result in
            instance.handle(call, result: result)
        }
        _channel = ch
        _instance = instance
        NSLog("[NativeHealth] channel registered ✓")
    }



    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard HKHealthStore.isHealthDataAvailable() else {
            result(FlutterError(code: "UNAVAILABLE", message: "HealthKit not available", details: nil))
            return
        }
        switch call.method {
        case "ping":
            result("pong")
        case "requestPermissions":
            requestPermissions(result: result)
        case "getWalkingMetrics":
            let args = call.arguments as? [String: Any]
            getWalkingMetrics(dateString: args?["date"] as? String ?? "", result: result)
        case "getAudioMetrics":
            let args = call.arguments as? [String: Any]
            getAudioMetrics(dateString: args?["date"] as? String ?? "", result: result)
        case "getWalkingMetricsRange":
            let args = call.arguments as? [String: Any]
            getWalkingMetricsRange(startString: args?["start"] as? String ?? "", result: result)
        case "getAudioMetricsRange":
            let args = call.arguments as? [String: Any]
            getAudioMetricsRange(startString: args?["start"] as? String ?? "", result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }



    private func requestPermissions(result: @escaping FlutterResult) {
        var types: Set<HKObjectType> = []
        let ids: [HKQuantityTypeIdentifier] = [
            .walkingStepLength,
            .walkingAsymmetryPercentage,
            .walkingDoubleSupportPercentage,
            .headphoneAudioExposure,
        ]
        for id in ids {
            if let t = HKQuantityType.quantityType(forIdentifier: id) { types.insert(t) }
        }
        if #available(iOS 15, *) {
            if let t = HKQuantityType.quantityType(forIdentifier: .appleWalkingSteadiness) {
                types.insert(t)
            }
        }
        store.requestAuthorization(toShare: nil, read: types) { ok, err in
            NSLog("[NativeHealth] requestAuthorization ok=\(ok) err=\(String(describing: err))")
            DispatchQueue.main.async { result(ok) }
        }
    }






    private func getWalkingMetrics(dateString: String, result: @escaping FlutterResult) {
        let (start, end) = dayRange(for: dateString)

        let group = DispatchGroup()
        var out: [String: Double] = [:]
        let lock = NSLock()

        func add(_ key: String, _ value: Double?) {
            NSLog("[NativeHealth] \(key) = \(String(describing: value))")
            if let v = value { lock.withLock { out[key] = v } }
        }

        let dayPred = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let weekPred = HKQuery.predicateForSamples(
            withStart: Calendar.current.date(byAdding: .day, value: -7, to: end)!,
            end: end, options: .strictStartDate
        )

        func queryWithFallback(
            _ id: HKQuantityTypeIdentifier,
            unit: HKUnit,
            scale: Double = 1.0,
            key: String
        ) {
            group.enter()
            queryAvg(id, unit: unit, predicate: dayPred) { v in
                if let v = v {
                    add(key, v * scale); group.leave()
                } else {

                    self.queryAvg(id, unit: unit, predicate: weekPred) { v2 in
                        add(key, v2.map { $0 * scale }); group.leave()
                    }
                }
            }
        }

        queryWithFallback(.walkingStepLength, unit: .meter(), key: "step_length_m")
        queryWithFallback(.walkingAsymmetryPercentage, unit: .percent(), scale: 100, key: "asymmetry_pct")
        queryWithFallback(.walkingDoubleSupportPercentage, unit: .percent(), scale: 100, key: "double_support_pct")

        if #available(iOS 15, *) {
            queryWithFallback(.appleWalkingSteadiness, unit: .percent(), scale: 100, key: "steadiness_pct")
        }

        group.notify(queue: .main) { result(out) }
    }



    private func getAudioMetrics(dateString: String, result: @escaping FlutterResult) {
        let (start, end) = dayRange(for: dateString)
        let dayPred = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let weekPred = HKQuery.predicateForSamples(
            withStart: Calendar.current.date(byAdding: .day, value: -7, to: end)!,
            end: end, options: .strictStartDate
        )
        let dbUnit = HKUnit.decibelAWeightedSoundPressureLevel()

        var out: [String: Double] = [:]
        let lock = NSLock()

        queryAvg(.headphoneAudioExposure, unit: dbUnit, predicate: dayPred) { v in
            if let v = v {
                NSLog("[NativeHealth] headphone_db = \(v)")
                lock.withLock { out["headphone_db"] = v }
                DispatchQueue.main.async { result(out) }
            } else {
                self.queryAvg(.headphoneAudioExposure, unit: dbUnit, predicate: weekPred) { v2 in
                    NSLog("[NativeHealth] headphone_db (fallback) = \(String(describing: v2))")
                    if let v2 = v2 { lock.withLock { out["headphone_db"] = v2 } }
                    DispatchQueue.main.async { result(out) }
                }
            }
        }
    }



    private func queryAvg(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        predicate: NSPredicate,
        completion: @escaping (Double?) -> Void
    ) {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
            completion(nil); return
        }
        let q = HKStatisticsQuery(
            quantityType: type,
            quantitySamplePredicate: predicate,
            options: .discreteAverage
        ) { _, stats, error in
            if let error = error {
                NSLog("[NativeHealth] error \(identifier.rawValue): \(error.localizedDescription)")
            }
            completion(stats?.averageQuantity()?.doubleValue(for: unit))
        }
        store.execute(q)
    }



    private func getWalkingMetricsRange(startString: String, result: @escaping FlutterResult) {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withFullDate]
        guard let s = fmt.date(from: startString) else { result([:]); return }

        let cal  = Calendar.current
        let anchor = cal.startOfDay(for: s)
        let rangeEnd = min(cal.date(byAdding: .day, value: 7, to: anchor)!, Date())

        let group = DispatchGroup()
        var out: [String: [[String: Any]]] = [:]
        let lock = NSLock()

        func queryCollection(_ id: HKQuantityTypeIdentifier, unit: HKUnit, key: String, scale: Double = 1.0) {
            guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return }
            let pred = HKQuery.predicateForSamples(withStart: anchor, end: rangeEnd, options: [])
            group.enter()
            let q = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: pred,
                options: [.discreteAverage, .discreteMin, .discreteMax],
                anchorDate: anchor,
                intervalComponents: DateComponents(day: 1)
            )
            q.initialResultsHandler = { _, collection, _ in
                var pts: [[String: Any]] = []
                collection?.enumerateStatistics(from: anchor, to: rangeEnd) { stats, _ in
                    guard let avg = stats.averageQuantity()?.doubleValue(for: unit) else { return }
                    let minV = stats.minimumQuantity()?.doubleValue(for: unit) ?? avg
                    let maxV = stats.maximumQuantity()?.doubleValue(for: unit) ?? avg
                    pts.append([
                        "date": fmt.string(from: stats.startDate),
                        "avg": avg * scale,
                        "min": minV * scale,
                        "max": maxV * scale,
                    ])
                }
                lock.withLock { out[key] = pts }
                group.leave()
            }
            self.store.execute(q)
        }

        queryCollection(.walkingStepLength,             unit: .meter(),   key: "step_length_m")
        queryCollection(.walkingAsymmetryPercentage,    unit: .percent(), key: "asymmetry_pct",    scale: 100)
        queryCollection(.walkingDoubleSupportPercentage,unit: .percent(), key: "double_support_pct",scale: 100)
        if #available(iOS 15, *) {
            queryCollection(.appleWalkingSteadiness,    unit: .percent(), key: "steadiness_pct",   scale: 100)
        }

        group.notify(queue: .main) { result(out) }
    }

    private func getAudioMetricsRange(startString: String, result: @escaping FlutterResult) {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withFullDate]
        guard let s = fmt.date(from: startString) else { result([:]); return }

        let cal     = Calendar.current
        let anchor  = cal.startOfDay(for: s)
        let rangeEnd = min(cal.date(byAdding: .day, value: 7, to: anchor)!, Date())
        let dbUnit  = HKUnit.decibelAWeightedSoundPressureLevel()

        guard let type = HKQuantityType.quantityType(forIdentifier: .headphoneAudioExposure) else {
            result([:]); return
        }
        let pred = HKQuery.predicateForSamples(withStart: anchor, end: rangeEnd, options: [])
        let q = HKStatisticsCollectionQuery(
            quantityType: type,
            quantitySamplePredicate: pred,
            options: [.discreteAverage, .discreteMin, .discreteMax],
            anchorDate: anchor,
            intervalComponents: DateComponents(day: 1)
        )
        q.initialResultsHandler = { _, collection, _ in
            var pts: [[String: Any]] = []
            collection?.enumerateStatistics(from: anchor, to: rangeEnd) { stats, _ in
                guard let avg = stats.averageQuantity()?.doubleValue(for: dbUnit) else { return }
                let minV = stats.minimumQuantity()?.doubleValue(for: dbUnit) ?? avg
                let maxV = stats.maximumQuantity()?.doubleValue(for: dbUnit) ?? avg
                pts.append([
                    "date": fmt.string(from: stats.startDate),
                    "avg": avg,
                    "min": minV,
                    "max": maxV,
                ])
            }
            DispatchQueue.main.async { result(["headphone_db": pts]) }
        }
        self.store.execute(q)
    }

    private func dayRange(for dateString: String) -> (Date, Date) {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withFullDate]
        let date = fmt.date(from: dateString) ?? Date()
        let start = Calendar.current.startOfDay(for: date)
        let endRaw = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        return (start, min(endRaw, Date()))
    }
}

private extension NSLock {
    func withLock(_ block: () -> Void) { lock(); block(); unlock() }
}
