//
//  NightscoutProfileRecordSyncManager.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 8/14/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Oxygen


internal final class NightscoutProfileRecordSyncManager: _NightscoutObserver, SyncManager {
    typealias Object = NightscoutProfileRecord

    var _recentlyUploaded = Atomic(SortedArray(areInIncreasingOrder: NightscoutProfileRecordSyncManager.mostRecentObjectsFirst))
    var _recentlyUpdated = Atomic(SortedArray(areInIncreasingOrder: NightscoutProfileRecordSyncManager.mostRecentObjectsFirst))
    var _recentlyDeleted = Atomic(SortedArray(areInIncreasingOrder: NightscoutProfileRecordSyncManager.mostRecentObjectsFirst))

    override func downloader(_ downloader: NightscoutDownloader, didFetchProfileRecords records: [NightscoutProfileRecord]) {
        updateWithFetchedObjects(records)
        clearOldOperations()
    }

    override func uploader(_ uploader: NightscoutUploader, didUploadProfileRecords records: Set<NightscoutProfileRecord>) {
        updateWithUploadedObjects(records)
    }

    override func uploader(_ uploader: NightscoutUploader, didUpdateProfileRecords records: Set<NightscoutProfileRecord>) {
        updateWithUpdatedObjects(records)
    }

    override func uploader(_ uploader: NightscoutUploader, didDeleteProfileRecords records: Set<NightscoutProfileRecord>) {
        updateWithDeletedObjects(records)
    }
}
