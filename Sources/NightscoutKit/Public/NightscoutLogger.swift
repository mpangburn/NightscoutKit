//
//  NightscoutLogger.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/23/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


private func printNewLine<T: TextOutputStream>(to outputStream: inout T) {
    print("", to: &outputStream)
}

/// A class that logs the failed operations of an observed `Nightscout` instance to an output stream,
/// including failed uploads, updates, deletions, and errors encountered.
open class NightscoutFailureLogger<Stream: TextOutputStream>: _NightscoutObserver {
    fileprivate let _outputStream: ThreadSafe<Stream>

    /// The output stream to which the operations of an observed `Nightscout` instance are logged.
    public var outputStream: Stream {
        return _outputStream.value
    }

    /// Creates a new logger.
    /// - Parameter outputStream: The output stream to which the operations of an observed `Nightscout` instance are logged.
    /// - Returns: A new logger that logs the operations of an observed `Nightscout` instance to the output stream.
    public init(outputStream: Stream) {
        self._outputStream = ThreadSafe(outputStream)
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    fileprivate var currentDateString: String {
        return dateFormatter.string(from: Date())
    }

    // MARK: - Logging

    open override func nightscout(_ nightscout: Nightscout, didFailToUploadEntries entries: Set<NightscoutEntry>) {
        _outputStream.atomically { stream in
            print("\(currentDateString): \(#function) @ \(nightscout.baseURL)", to: &stream)
            entries.forEach { print($0, to: &stream) }
            printNewLine(to: &stream)
        }
    }

    open override func nightscout(_ nightscout: Nightscout, didFailToUploadTreatments treatments: Set<NightscoutTreatment>) {
        _outputStream.atomically { stream in
            print("\(currentDateString): \(#function) @ \(nightscout.baseURL)", to: &stream)
            treatments.forEach { print($0, to: &stream) }
            printNewLine(to: &stream)
        }
    }

    open override func nightscout(_ nightscout: Nightscout, didFailToUpdateTreatments treatments: Set<NightscoutTreatment>) {
        _outputStream.atomically { stream in
            print("\(currentDateString): \(#function) @ \(nightscout.baseURL)", to: &stream)
            treatments.forEach { print($0, to: &stream) }
            printNewLine(to: &stream)
        }
    }

    open override func nightscout(_ nightscout: Nightscout, didFailToDeleteTreatments treatments: Set<NightscoutTreatment>) {
        _outputStream.atomically { stream in
            print("\(currentDateString): \(#function) @ \(nightscout.baseURL)", to: &stream)
            treatments.forEach { print($0, to: &stream) }
            printNewLine(to: &stream)
        }
    }

    open override func nightscout(_ nightscout: Nightscout, didFailToUploadProfileRecords records: Set<NightscoutProfileRecord>) {
        _outputStream.atomically { stream in
            print("\(currentDateString): \(#function) @ \(nightscout.baseURL)", to: &stream)
            records.forEach { print($0, to: &stream) }
            printNewLine(to: &stream)
        }
    }

    open override func nightscout(_ nightscout: Nightscout, didFailToUpdateProfileRecords records: Set<NightscoutProfileRecord>) {
        _outputStream.atomically { stream in
            print("\(currentDateString): \(#function) @ \(nightscout.baseURL)", to: &stream)
            records.forEach { print($0, to: &stream) }
            printNewLine(to: &stream)
        }
    }

    open override func nightscout(_ nightscout: Nightscout, didFailToDeleteProfileRecords records: Set<NightscoutProfileRecord>) {
        _outputStream.atomically { stream in
            print("\(currentDateString): \(#function) @ \(nightscout.baseURL)", to: &stream)
            records.forEach { print($0, to: &stream) }
            printNewLine(to: &stream)
        }
    }

    open override func nightscout(_ nightscout: Nightscout, didErrorWith error: NightscoutError) {
        _outputStream.atomically { stream in
            print("\(currentDateString): \(#function) @ \(nightscout.baseURL)", to: &stream)
            print(error, to: &stream)
            printNewLine(to: &stream)
        }
    }
}

/// A class that logs the operations of an observed `Nightscout` instance to an output stream.
open class NightscoutLogger<Stream: TextOutputStream>: NightscoutFailureLogger<Stream> {
    open override func nightscoutDidVerifyAuthorization(_ nightscout: Nightscout) {
        _outputStream.atomically { stream in
            print("\(currentDateString): \(#function) @ \(nightscout.baseURL)", to: &stream)
            printNewLine(to: &stream)
        }
    }

    open override func nightscout(_ nightscout: Nightscout, didFetchStatus status: NightscoutStatus) {
        _outputStream.atomically { stream in
            print("\(currentDateString): \(#function) @ \(nightscout.baseURL)", to: &stream)
            print(status, to: &stream)
            printNewLine(to: &stream)
        }
    }

    open override func nightscout(_ nightscout: Nightscout, didFetchEntries entries: [NightscoutEntry]) {
        _outputStream.atomically { stream in
            print("\(currentDateString): \(#function) @ \(nightscout.baseURL)", to: &stream)
            entries.forEach { print($0, to: &stream) }
            printNewLine(to: &stream)
        }
    }

    open override func nightscout(_ nightscout: Nightscout, didUploadEntries entries: Set<NightscoutEntry>) {
        _outputStream.atomically { stream in
            print("\(currentDateString): \(#function) @ \(nightscout.baseURL)", to: &stream)
            entries.forEach { print($0, to: &stream) }
            printNewLine(to: &stream)
        }
    }

    open override func nightscout(_ nightscout: Nightscout, didFetchTreatments treatments: [NightscoutTreatment]) {
        _outputStream.atomically { stream in
            print("\(currentDateString): \(#function) @ \(nightscout.baseURL)", to: &stream)
            treatments.forEach { print($0, to: &stream) }
            printNewLine(to: &stream)
        }
    }

    open override func nightscout(_ nightscout: Nightscout, didUploadTreatments treatments: Set<NightscoutTreatment>) {
        _outputStream.atomically { stream in
            print("\(currentDateString): \(#function) @ \(nightscout.baseURL)", to: &stream)
            treatments.forEach { print($0, to: &stream) }
            printNewLine(to: &stream)
        }
    }

    open override func nightscout(_ nightscout: Nightscout, didUpdateTreatments treatments: Set<NightscoutTreatment>) {
        _outputStream.atomically { stream in
            print("\(currentDateString): \(#function) @ \(nightscout.baseURL)", to: &stream)
            treatments.forEach { print($0, to: &stream) }
            printNewLine(to: &stream)
        }
    }

    open override func nightscout(_ nightscout: Nightscout, didDeleteTreatments treatments: Set<NightscoutTreatment>) {
        _outputStream.atomically { stream in
            print("\(currentDateString): \(#function) @ \(nightscout.baseURL)", to: &stream)
            treatments.forEach { print($0, to: &stream) }
            printNewLine(to: &stream)
        }
    }

    open override func nightscout(_ nightscout: Nightscout, didFetchProfileRecords records: [NightscoutProfileRecord]) {
        _outputStream.atomically { stream in
            print("\(currentDateString): \(#function) @ \(nightscout.baseURL)", to: &stream)
            records.forEach { print($0, to: &stream) }
            printNewLine(to: &stream)
        }
    }

    open override func nightscout(_ nightscout: Nightscout, didUploadProfileRecords records: Set<NightscoutProfileRecord>) {
        _outputStream.atomically { stream in
            print("\(currentDateString): \(#function) @ \(nightscout.baseURL)", to: &stream)
            records.forEach { print($0, to: &stream) }
            printNewLine(to: &stream)
        }
    }

    open override func nightscout(_ nightscout: Nightscout, didUpdateProfileRecords records: Set<NightscoutProfileRecord>) {
        _outputStream.atomically { stream in
            print("\(currentDateString): \(#function) @ \(nightscout.baseURL)", to: &stream)
            records.forEach { print($0, to: &stream) }
            printNewLine(to: &stream)
        }
    }

    open override func nightscout(_ nightscout: Nightscout, didDeleteProfileRecords records: Set<NightscoutProfileRecord>) {
        _outputStream.atomically { stream in
            print("\(currentDateString): \(#function) @ \(nightscout.baseURL)", to: &stream)
            records.forEach { print($0, to: &stream) }
            printNewLine(to: &stream)
        }
    }

    open override func nightscout(_ nightscout: Nightscout, didFetchDeviceStatuses deviceStatuses: [NightscoutDeviceStatus]) {
        _outputStream.atomically { stream in
            print("\(currentDateString): \(#function) @ \(nightscout.baseURL)", to: &stream)
            deviceStatuses.forEach { print($0, to: &stream) }
            printNewLine(to: &stream)
        }
    }
}

extension NightscoutFailureLogger where Stream == FileHandle {
    /// Creates a new `NightscoutLogger` that logs the operations of an observed `Nightscout` instance to standard output.
    public static func standardOutputLogger() -> Self {
        return .init(outputStream: .standardOutput)
    }
}

extension NightscoutFailureLogger where Stream: RangeReplaceableCollection {
    /// Clears all output written to the stream.
    public func clearOutputStream() {
        _outputStream.atomically { $0.removeAll() }
    }
}

extension FileHandle: TextOutputStream {
    public func write(_ string: String) {
        let data = string.data(using: .utf8)!
        write(data)
    }
}
