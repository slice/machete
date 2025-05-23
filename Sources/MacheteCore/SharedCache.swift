import CDyld

public struct SharedCache {
  /// Where the header of the shared cache is reachable.
  var guts: UnsafePointer<dyld_cache_header>

  var slide: UInt
}

public extension SharedCache {
  var base: UnsafeRawPointer { UnsafeRawPointer(guts) }
}

public extension SharedCache {
  init(unsafeLoadingFrom base: consuming UnsafeRawPointer, slide: UInt) {
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

    return SharedCache(unsafeLoadingFrom: sharedCacheBase,
                       slide: allImageInfos.sharedCacheSlide)
  }
}

public extension SharedCache {
  var magic: String {
    withUnsafeBytes(of: guts.pointee.magic) {
      $0.withMemoryRebound(to: UInt8.self) { String(cString: $0.baseAddress!) }
    }
  }
}
