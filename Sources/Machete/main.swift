import MacheteCore

for image in SharedCache.inMemory.images {
  print(image)
  for lc in image.loadCommands {
    print("  \(lc)")
  }
}
