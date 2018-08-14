//
//  NightscoutLogger.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/23/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation


/// A class that logs the failed operations of an observed `NightscoutDownloader` or `NightscoutUploader`
/// instance, including failed uploads, updates, deletions, and errors encountered.
open class NightscoutFailureLogger: _NightscoutObserver {
    /// The function used to write logs.
    public let write: (String) -> Void

    /// Creates a new logger with the given writing function.
    /// - Parameter write: The function used to log the events of the observed `NightscoutDownloader`
    ///                    or `NightscoutUploader` instance.
    /// - Parameter synchronizingWrites: Determines whether a DispatchQueue should be used to synchronize
    ///                                  writes to the output stream. The default value is `true`.
    /// - Returns: A new logger that logs the operations of the observed `NightscoutDownloader`
    ///            or `NightscoutUploader` instance using the given function.
    public init(write: @escaping (String) -> Void, synchronizingWrites: Bool = true) {
        if synchronizingWrites {
            let writingQueue = DispatchQueue(label: "com.mpangburn.nightscoutkit.loggingqueue")
            self.write = { log in writingQueue.sync { write(log) } }
        } else {
            self.write = write
        }
    }

    /// Creates a new logger targeting the given output stream.
    /// - Parameter outputStream: The output stream to which to direct logs.
    /// - Parameter synchronizingWrites: Determines whether a DispatchQueue should be used to synchronize
    ///                                  writes to the output stream. The default value is `true`.
    /// - Returns: A new logger targeting the given output stream.
    public convenience init(outputStream: TextOutputStream, synchronizingWrites: Bool = true) {
        var outputStream = outputStream
        self.init(write: { outputStream.write($0) }, synchronizingWrites: synchronizingWrites)
    }

    /// Creates a new logger targeting the given file handle.
    /// - Parameter fileHandle: The file handle to which to direct logs.
    /// - Returns: A new logger targeting the given file handle.
    public init(fileHandle: FileHandle) {
        self.write = { fileHandle.write(Data($0.utf8)) }
    }

    /// Creates a new logger utilizing `NSLog`.
    /// - Returns: A new logger utilizing `NSLog`.
    public class func nsLogger() -> Self {
        return self.init(write: { NSLog($0) })
    }

    // MARK: - NightscoutDownloaderObserver

    open override func downloader(_ downloader: NightscoutDownloader, didErrorWith error: NightscoutError) {
        logInvocation(downloader: downloader, additionalInfo: String(describing: error))
    }

    // MARK: - NightscoutUploaderObserver

    open override func uploader(_ uploader: NightscoutUploader, didErrorWith error: NightscoutError) {
        logInvocation(uploader: uploader, additionalInfo: String(describing: error))
    }

    open override func uploader(_ uploader: NightscoutUploader, didFailToUploadEntries entries: Set<NightscoutEntry>) {
        logInvocation(uploader: uploader, additionalInfo: newlineSeparatedDescriptions(of: entries))
    }

    open override func uploader(_ uploader: NightscoutUploader, didFailToUploadTreatments treatments: Set<NightscoutTreatment>) {
        logInvocation(uploader: uploader, additionalInfo: newlineSeparatedDescriptions(of: treatments))
    }

    open override func uploader(_ uploader: NightscoutUploader, didFailToUpdateTreatments treatments: Set<NightscoutTreatment>) {
        logInvocation(uploader: uploader, additionalInfo: newlineSeparatedDescriptions(of: treatments))
    }

    open override func uploader(_ uploader: NightscoutUploader, didFailToDeleteTreatments treatments: Set<NightscoutTreatment>) {
        logInvocation(uploader: uploader, additionalInfo: newlineSeparatedDescriptions(of: treatments))
    }

    open override func uploader(_ uploader: NightscoutUploader, didFailToUploadProfileRecords records: Set<NightscoutProfileRecord>) {
        logInvocation(uploader: uploader, additionalInfo: newlineSeparatedDescriptions(of: records))
    }

    open override func uploader(_ uploader: NightscoutUploader, didFailToUpdateProfileRecords records: Set<NightscoutProfileRecord>) {
        logInvocation(uploader: uploader, additionalInfo: newlineSeparatedDescriptions(of: records))
    }

    open override func uploader(_ uploader: NightscoutUploader, didFailToDeleteProfileRecords records: Set<NightscoutProfileRecord>) {
        logInvocation(uploader: uploader, additionalInfo: newlineSeparatedDescriptions(of: records))
    }
}

// MARK: - Logging Utilities

extension NightscoutFailureLogger {
    fileprivate func logInvocation(of function: StaticString = #function, downloader: NightscoutDownloader, additionalInfo: String?) {
        write("\(function) @ \(downloader.credentials.url)\(additionalInfo.map { ": \($0)" } ?? "")")
    }

    fileprivate func logInvocation(of function: StaticString = #function, uploader: NightscoutUploader, additionalInfo: String?) {
        write("\(function) @ \(uploader.credentials.url)\(additionalInfo.map { ": \($0)" } ?? "")")
    }

    fileprivate func newlineSeparatedDescriptions<S: Sequence>(of elements: S, includingLeadingNewline: Bool = true) -> String {
        let descriptions = elements.map(String.init(describing:)).joined(separator: "\n")
        return includingLeadingNewline ? "\n" + descriptions : descriptions
    }
}

/// A class that logs the operations of an observed `NightscoutDownloader` or `NighscoutUploader` instance.
open class NightscoutLogger: NightscoutFailureLogger {
    // MARK: - NightscoutDownloaderObserver

    open override func downloader(_ downloader: NightscoutDownloader, didFetchStatus status: NightscoutStatus) {
        logInvocation(downloader: downloader, additionalInfo: String(describing: status))
    }

    open override func downloader(_ downloader: NightscoutDownloader, didFetchEntries entries: [NightscoutEntry]) {
        logInvocation(downloader: downloader, additionalInfo: newlineSeparatedDescriptions(of: entries))
    }

    open override func downloader(_ downloader: NightscoutDownloader, didFetchTreatments treatments: [NightscoutTreatment]) {
        logInvocation(downloader: downloader, additionalInfo: newlineSeparatedDescriptions(of: treatments))
    }

    open override func downloader(_ downloader: NightscoutDownloader, didFetchProfileRecords records: [NightscoutProfileRecord]) {
        logInvocation(downloader: downloader, additionalInfo: newlineSeparatedDescriptions(of: records))
    }

    open override func downloader(_ downloader: NightscoutDownloader, didFetchDeviceStatuses deviceStatuses: [NightscoutDeviceStatus]) {
        logInvocation(downloader: downloader, additionalInfo: newlineSeparatedDescriptions(of: deviceStatuses))
    }

    // MARK: - NightscoutUploaderObserver

    open override func uploaderDidVerifyAuthorization(_ uploader: NightscoutUploader) {
        logInvocation(uploader: uploader, additionalInfo: nil)
    }

    open override func uploader(_ uploader: NightscoutUploader, didUploadEntries entries: Set<NightscoutEntry>) {
        logInvocation(uploader: uploader, additionalInfo: newlineSeparatedDescriptions(of: entries))
    }

    open override func uploader(_ uploader: NightscoutUploader, didUploadTreatments treatments: Set<NightscoutTreatment>) {
        logInvocation(uploader: uploader, additionalInfo: newlineSeparatedDescriptions(of: treatments))
    }

    open override func uploader(_ uploader: NightscoutUploader, didUpdateTreatments treatments: Set<NightscoutTreatment>) {
        logInvocation(uploader: uploader, additionalInfo: newlineSeparatedDescriptions(of: treatments))
    }

    open override func uploader(_ uploader: NightscoutUploader, didDeleteTreatments treatments: Set<NightscoutTreatment>) {
        logInvocation(uploader: uploader, additionalInfo: newlineSeparatedDescriptions(of: treatments))
    }

    open override func uploader(_ uploader: NightscoutUploader, didUploadProfileRecords records: Set<NightscoutProfileRecord>) {
        logInvocation(uploader: uploader, additionalInfo: newlineSeparatedDescriptions(of: records))
    }

    open override func uploader(_ uploader: NightscoutUploader, didUpdateProfileRecords records: Set<NightscoutProfileRecord>) {
        logInvocation(uploader: uploader, additionalInfo: newlineSeparatedDescriptions(of: records))
    }

    open override func uploader(_ uploader: NightscoutUploader, didDeleteProfileRecords records: Set<NightscoutProfileRecord>) {
        logInvocation(uploader: uploader, additionalInfo: newlineSeparatedDescriptions(of: records))
    }
}
