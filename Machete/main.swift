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

let formattedBase = String(format: "%x", allImageInfos.sharedCacheBaseAddress)
let formattedSlide = String(format: "%x", allImageInfos.sharedCacheSlide)
print(magic, "(\(cacheHeader.imagesCount) images, base: \(formattedBase), slide: \(formattedSlide))")
let images = UnsafeBufferPointer<dyld_cache_image_info>(
  start: UnsafePointer(bitPattern: allImageInfos.sharedCacheBaseAddress + UInt(cacheHeader.imagesOffset)),
  count: Int(cacheHeader.imagesCount)
)

for (imageIndex, image) in images.enumerated() {
  let path = String(cString: UnsafePointer<CChar>(bitPattern: allImageInfos.sharedCacheBaseAddress + UInt(image.pathFileOffset))!)
  let paddedImageIndex = String(format: "% 8d % 8x", imageIndex, image.address)

  let machOBase = UnsafeRawPointer(bitPattern: Int(image.address) + Int(allImageInfos.sharedCacheSlide))!
  let header = machOBase.load(as: mach_header_64.self)
  assert(header.magic == 0xFEED_FACF, "bad magic")

  let flags = MachHeader.Flags(rawValue: header.flags).description
  print("\(paddedImageIndex) \(path) \(flags)")
  defer { print() }

  let firstLoadCmd = machOBase + MemoryLayout<mach_header_64>.stride
  var offset = 0
  while offset < header.sizeofcmds {
    let cmdPointer = (firstLoadCmd + offset)
    let loadCmd = cmdPointer.load(as: load_command.self)
    assert(loadCmd.cmdsize > 0, "load cmd size was zero")
    assert(loadCmd.cmdsize.isMultiple(of: 8), "load cmd size wasn't multiple of 8")

    print("         \(loadCmd)")
    offset += Int(loadCmd.cmdsize)
  }
}
