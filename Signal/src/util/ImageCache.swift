//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

import Foundation
import UIKit

class ImageCacheRecord: NSObject {
    var variations: [CGFloat: UIImage]
    init(variations: [CGFloat: UIImage]) {
        self.variations = variations
    }
}

/**
 * A two dimensional hash, allowing you to store variations under a single key.
 * This is useful because we generate multiple diameters of an image, but when we 
 * want to clear out the images for a key we want to clear out *all* variations.
 */
@objc
class ImageCache: NSObject {

    let backingCache: NSCache<AnyObject, ImageCacheRecord>

    override init() {
        self.backingCache = NSCache()
    }

    @objc func image(forKey key: AnyObject, diameter: CGFloat) -> UIImage? {
        guard let record = backingCache.object(forKey: key) else {
            return nil
        }
        return record.variations[diameter]
    }

    @objc func setImage(_ image: UIImage, forKey key: AnyObject, diameter: CGFloat) {
        if let existingRecord = backingCache.object(forKey: key) {
            existingRecord.variations[diameter] = image
            backingCache.setObject(existingRecord, forKey: key)
        } else {
            let newRecord = ImageCacheRecord(variations: [diameter: image])
            backingCache.setObject(newRecord, forKey: key)
        }
    }

    @objc func removeAllImages() {
        backingCache.removeAllObjects()
    }

    @objc func removeAllImages(forKey key: AnyObject) {
        backingCache.removeObject(forKey: key)
    }
}
