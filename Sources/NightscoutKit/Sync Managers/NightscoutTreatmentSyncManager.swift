//
//  NightscoutTreatmentSyncManager.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 8/14/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Oxygen


internal final class NightscoutTreatmentSyncManager: _NightscoutObserver, SyncManager {
    typealias Object = NightscoutTreatment

    var _recentlyUploaded = Atomic(SortedArray(areInIncreasingOrder: NightscoutTreatmentSyncManager.mostRecentObjectsFirst))
    var _recentlyUpdated = Atomic(SortedArray(areInIncreasingOrder: NightscoutTreatmentSyncManager.mostRecentObjectsFirst))
    var _recentlyDeleted = Atomic(SortedArray(areInIncreasingOrder: NightscoutTreatmentSyncManager.mostRecentObjectsFirst))

    override func downloader(_ downloader: NightscoutDownloader, didFetchTreatments treatments: [NightscoutTreatment]) {
        updateWithFetchedObjects(treatments)
        clearOldOperations()
    }

    override func uploader(_ uploader: NightscoutUploader, didUploadTreatments treatments: Set<NightscoutTreatment>) {
        updateWithUploadedObjects(treatments)
    }

    override func uploader(_ uploader: NightscoutUploader, didUpdateTreatments treatments: Set<NightscoutTreatment>) {
        updateWithUpdatedObjects(treatments)
    }

    override func uploader(_ uploader: NightscoutUploader, didDeleteTreatments treatments: Set<NightscoutTreatment>) {
        updateWithDeletedObjects(treatments)
    }
}
