import CDyld

extension SharedCache {
  var imageCount: Int {
    Int(guts.pointee.imagesCount)
  }

  var firstImage: UnsafePointer<dyld_cache_image_info> {
    (base + Int(guts.pointee.imagesOffset)).bindMemory(to: dyld_cache_image_info.self, capacity: imageCount)
  }

  public var images: some RandomAccessCollection<SharedCache.Image> {
    UnsafeBufferPointer<dyld_cache_image_info>(start: firstImage, count: imageCount)
      .map { SharedCache.Image(info: $0, within: self) }
  }
}
