import Foundation
import MachO

var info = task_dyld_info_data_t()
var count = mach_msg_type_number_t(MemoryLayout<task_dyld_info_data_t>.size / MemoryLayout<natural_t>.size)
guard (withUnsafeMutablePointer(to: &info) {
  $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
    task_info(mach_task_self_, task_flavor_t(TASK_DYLD_INFO), $0, &count)
  }
}) == KERN_SUCCESS else {
  fatalError("failed to grab task_info")
}

let allImageInfosPointer = UnsafePointer<dyld_all_image_infos>(bitPattern: Int(info.all_image_info_addr))!
let allImageInfos = allImageInfosPointer.pointee

let cacheHeader = UnsafePointer<dyld_cache_header>(bitPattern: allImageInfos.sharedCacheBaseAddress)!.pointee

let magic = withUnsafeBytes(of: cacheHeader.magic) {
  $0.withMemoryRebound(to: UInt8.self) { String(cString: $0.baseAddress!) }
}
print(magic, "(\(cacheHeader.imagesCount) images)")
let images = UnsafeBufferPointer<dyld_cache_image_info>(
  start: UnsafePointer(bitPattern: allImageInfos.sharedCacheBaseAddress + UInt(cacheHeader.imagesOffset)),
  count: Int(cacheHeader.imagesCount)
)

for (imageIndex, image) in images.enumerated() {
  let path = String(cString: UnsafePointer<CChar>(bitPattern: allImageInfos.sharedCacheBaseAddress + UInt(image.pathFileOffset))!)
  let paddedImageIndex = String(format: "% 8d", imageIndex)
  print("\(paddedImageIndex)", path)
}
