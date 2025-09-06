public import CDyld
import Foundation

public struct SharedCache {
  /// Where the header of the shared cache is reachable.
  @_spi(Guts)
  public var guts: UnsafePointer<dyld_cache_header>

  /**
   * Indicates the offset to add when dereferencing interior (within cache) pointers.
   *
   * Let's say that the first `dyld_cache_image_info` in the cache states that
   * an image is located at `0x180080000`. Loading from this address as-is would only work
   * if the shared cache is literally present in memory at `0x180000000` (this is the
   * value of `sharedRegionStart`).
   *
   * As part of ordinary process initialization though, the shared cache is actually mapped
   * to a random position. The difference between `sharedRegionStart` and the actual
   * location of the shared cache (i.e. how much the cache was slid) is what is represented
   * by this value.
   *
   * When inspecting the shared cache currently in memory, the correct slide can be gleaned
   * from `TASK_DYLD_INFO`. Otherwise, this can be used to e.g. correct interior pointers to
   * load from a memory-mapped region (when reading from an on-disk cache).
   */
  var slide: Int
}

public extension SharedCache {
  var base: UnsafeRawPointer { UnsafeRawPointer(guts) }

  var magic: String {
    withUnsafeBytes(of: guts.pointee.magic) {
      $0.withMemoryRebound(to: UInt8.self) { String(cString: $0.baseAddress!) }
    }
  }
}

public extension SharedCache {
  init(unsafeLoadingFrom base: consuming UnsafeRawPointer, slide: Int) {
    guts = base.bindMemory(to: dyld_cache_header.self, capacity: 1)
    self.slide = slide
  }

  static var inMemory: Self {
    // `task_info(MACH_TASK_SELF, TASK_DYLD_INFO, &info, &count)`
    let dyldInfo = {
      var info = task_dyld_info_data_t()
      var count = mach_msg_type_number_t(
        MemoryLayout<task_dyld_info_data_t>.size / MemoryLayout<natural_t>.size)
      guard
        (withUnsafeMutablePointer(to: &info) {
          $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_, task_flavor_t(TASK_DYLD_INFO), $0, &count)
          }
        }) == KERN_SUCCESS
      else {
        fatalError("couldn't grab task_info of the current task")
      }
      return info
    }()

    let allImageInfos = UnsafePointer<dyld_all_image_infos>(
      bitPattern: Int(dyldInfo.all_image_info_addr))!.pointee
    let sharedCacheBase = UnsafeRawPointer(bitPattern: allImageInfos.sharedCacheBaseAddress)!

    return SharedCache(
      unsafeLoadingFrom: sharedCacheBase,
      slide: Int(allImageInfos.sharedCacheSlide),
    )
  }
}

public extension SharedCache {
  var subcaches: [Subcache] {
    let firstSubcache = (base + Int(guts.pointee.subCacheArrayOffset)).bindMemory(to: dyld_subcache_entry.self, capacity: 1)
    let subcaches = UnsafeBufferPointer(start: firstSubcache, count: Int(guts.pointee.subCacheArrayCount))
    return subcaches.map { Subcache(guts: $0) }
  }
}
