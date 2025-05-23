import CDyld
import Foundation
import MacheteCore
import MachO

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
  fatalError("failed to grab task_info")
}

let allImageInfosPointer = UnsafePointer<dyld_all_image_infos>(
  bitPattern: Int(info.all_image_info_addr))!
let allImageInfos = allImageInfosPointer.pointee

let cacheHeader = UnsafePointer<dyld_cache_header>(
  bitPattern: allImageInfos.sharedCacheBaseAddress)!.pointee

let sharedCache = SharedCache(unsafeLoadingFrom: UnsafeRawPointer(bitPattern: allImageInfos.sharedCacheBaseAddress)!, slide: allImageInfos.sharedCacheSlide)

for image in sharedCache.images {
  print(image)
  for lc in image.loadCommands {
    print("  \(lc)")
  }
}
