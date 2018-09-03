//
//  TreatmentSyncManager.swift
//  Brightscout
//
//  Created by Michael Pangburn on 8/14/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Foundation
import Oxygen


/// Denotes the completion of a PUT/POST/DELETE operation and its associated value.
internal struct OperationCompletion<Object: TimelineValue> {
    let operationDate: Date
    let object: Object
}

/// Manages objects with which a Nightscout service interacts,
/// taking into consideration the interval between PUT/POST/DELETE request successes and their reflections in GET requests.
internal protocol SyncManager {
    associatedtype Object: TimelineValue & NightscoutIdentifiable

    var _recentlyUploaded: Atomic<SortedArray<OperationCompletion<Object>>> { get }
    var _recentlyUpdated: Atomic<SortedArray<OperationCompletion<Object>>> { get }
    var _recentlyDeleted: Atomic<SortedArray<OperationCompletion<Object>>> { get }
}

extension SyncManager {
    /// The comparator use for recently uploaded, updated, and deleted objects.
    static var mostRecentObjectsFirst: SortedArray<OperationCompletion<Object>>.Comparator {
        return { $0.object.date > $1.object.date }
    }

    /// The estimated amount of time before PUT/POST/DELETE request successes are reflected in GET requests.
    var apiUpdateDelay: TimeInterval {
        return .minutes(5)
    }

    var recentlyUploaded: SortedArray<Object> {
        return SortedArray(sorted: _recentlyUploaded.value.map { $0.object }, areInIncreasingOrder: { $0.date > $1.date })
    }

    var recentlyUpdated: SortedArray<Object> {
        return SortedArray(sorted: _recentlyUpdated.value.map { $0.object }, areInIncreasingOrder: { $0.date > $1.date })
    }

    var recentlyDeleted: SortedArray<Object> {
        return SortedArray(sorted: _recentlyDeleted.value.map { $0.object }, areInIncreasingOrder: { $0.date > $1.date })
    }

    /// Note: `objects` must be sorted in descending order by date.
    func applyUpdates(to objects: inout SortedArray<Object>, insertingAllNewerUploads: Bool) {
        guard let spannedInterval = objects.spannedDateInterval else {
            objects = recentlyUploaded
            return
        }

        // We'll use the extended date interval for uploads, updates, and deletions,
        // because it's fathomable that a user would upload a treatment and immediately update or delete it.
        let extendedDateInterval = DateInterval(
            start: spannedInterval.start,
            end: insertingAllNewerUploads ? .distantFuture : spannedInterval.end
        )

        let pertinentUploads = recentlyUploaded.clamped(to: extendedDateInterval)
        for upload in pertinentUploads where !objects.contains(upload) {
            objects.insert(upload)
        }

        // When applying updates, we have to consider that a treatment's date may have changed, which makes this challenging.
        // We don't know if a date changed, so we'll do a scan to remove each updated treatment,
        // then do the insertions only for the updates that fall in the date interval.
        let recentlyUpdated = self.recentlyUpdated
        recentlyUpdated.forEach { objects.remove($0) }

        let pertinentUpdates = recentlyUpdated.clamped(to: extendedDateInterval)
        for update in pertinentUpdates {
            objects.insert(update)
        }

        let pertinentDeletions = recentlyDeleted.clamped(to: extendedDateInterval)
        pertinentDeletions.forEach { objects.remove($0) }
    }

    /// Note: `objects` must be sorted in descending order by date.
    func updateWithFetchedObjects(_ objects: [Object]) {
        let sortedObjects = SortedArray(sorted: objects, areInIncreasingOrder: { $0.date > $1.date })
        _recentlyUploaded.modify { recentlyUploaded in
            // If we find a recently uploaded treatment in the fetched treatments, remove it from the cache.
            guard let spannedDateInterval = recentlyUploaded.spannedValueInterval() else {
                return
            }
            let relevantObjects = sortedObjects.clamped(to: spannedDateInterval)
            for object in relevantObjects {
                // TODO: removeAll(where:) in Swift 4.2
                if let uploadedIndex = recentlyUploaded.index(where: { $0.object.id == object.id }) {
                    recentlyUploaded.remove(at: uploadedIndex)
                }
            }
        }

        _recentlyUpdated.modify { recentlyUpdated in
            // If we find a recently updated treatment in the fetched treatments and it's updated already, remove it from the cache.
            // TODO: This may not even been possible here because we'd need to differentiate between the fetched treatment and updated one,
            // which is challenging because the server may add some fields that make it subtlely different;
            // in addition, the current implementation of Equatable for NightscoutTreatment only tests id, which is insufficient here;
            // (but has benefits elsewhere).
        }
    }

    func updateWithUploadedObjects(_ objects: Set<Object>) {
        _recentlyUploaded.modify { recentlyUploaded in
            let now = Date()
            objects.forEach { recentlyUploaded.insert(.init(operationDate: now, object: $0)) }
        }
    }

    func updateWithUpdatedObjects(_ objects: Set<Object>) {
        _recentlyUpdated.modify { recentlyUpdated in
            let now = Date()
            objects.forEach { recentlyUpdated.insert(.init(operationDate: now, object: $0)) }
        }
    }

    func updateWithDeletedObjects(_ objects: Set<Object>) {
        _recentlyDeleted.modify { recentlyDeleted in
            let now = Date()
            objects.forEach { recentlyDeleted.insert(.init(operationDate: now, object: $0)) }
        }
    }

    func clearOldOperations() {
        clearOperations(olderThan: Date() - apiUpdateDelay)
    }

    func clearOperations(olderThan oldestDateToKeep: Date) {
        let removeOldOperations: (inout SortedArray<OperationCompletion<Object>>) -> Void = { operations in
            operations = operations.sortedFilter { $0.operationDate > oldestDateToKeep }
        }
        _recentlyUploaded.modify(with: removeOldOperations)
        _recentlyUpdated.modify(with: removeOldOperations)
        _recentlyDeleted.modify(with: removeOldOperations)
    }

    func clearCache() {
        _recentlyUploaded.modify { $0.removeAll() }
        _recentlyUpdated.modify { $0.removeAll() }
        _recentlyDeleted.modify { $0.removeAll() }
    }
}

// Assumes elements are sorted by date with the most recent elements first.
private extension SortedArray where Element: TimelineValue {
    var spannedDateInterval: DateInterval? {
        guard let newest = first, let oldest = last else {
            return nil
        }
        return DateInterval(start: oldest.date, end: newest.date)
    }

    func clamped(to interval: DateInterval) -> SortedArray<Element> {
        let withoutNewerElements = drop(while: { $0.date > interval.end })
        guard !withoutNewerElements.isEmpty else {
            return SortedArray(sorted: [], areInIncreasingOrder: areInIncreasingOrder)
        }
        // TODO: would be nice to have a dropLast(while:)
        var lowerBoundIndex = withoutNewerElements.index(before: withoutNewerElements.endIndex)
        while lowerBoundIndex != withoutNewerElements.startIndex, withoutNewerElements[lowerBoundIndex].date < interval.start {
            formIndex(before: &lowerBoundIndex)
        }
        let clamped = withoutNewerElements[...lowerBoundIndex]
        return SortedArray(sorted: clamped, areInIncreasingOrder: areInIncreasingOrder)
    }
}

// Assumes elements are sorted by object date with the most recent objects first.
private extension SortedArray {
    func spannedValueInterval<T>() -> DateInterval? where Element == OperationCompletion<T> {
        guard let newest = first, let oldest = last else {
            return nil
        }
        return DateInterval(start: oldest.object.date, end: newest.object.date)
    }
}
