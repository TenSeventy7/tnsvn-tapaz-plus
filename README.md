<h1 align="center">tnsvn-tapaz-plus</h1>
<p align="center">
  <i>Optimizations and improvements for the Xiaomi Redmi Note 12 4G (tapas/topaz).</i>
</p>

## Features

- Tested on the non-NFC variant of the Redmi Note 12 4G (`tapas`) running Xiaomi.eu
- Optimized scheduler latencies based on @tytydraco's work on [KTweak](https://github.com/tytydraco/KTweak)
- Match migration margins to `core_ctl` busy thresholds to avoid often scaling to higher frequencies across all CPUs
- Allow CPUs 2-7 to go to low power mode on low overall loads
- Conservatively pack small tasks to Silver CPUs
- Restrict unimportant tasks to Silver cores
- Make it easier for `top-app` tasks to move to the Gold cluster by boosting them using UClamp
- Schedule and colocate `top-app` threads to idle CPUs as much as possible to improve app performance
- Set up rate limits to CPU scaling on both Silver and Gold clusters
- Add related task group (RTG) boosting to the Silver cluster
- Mimic a behavior done by Google and Samsung and boost `foreground` tasks to Gold cores on input
- Tuned memory writeback ratio and timings
- Optimized Qualcomm performance hints to remove unnecessary boosts
- Enable control center blur and locking app to memory for all variants
- Schedule UI-critical threads as FIFO to reduce jitter
- Use two threads for MIUI animator
- Reduce logging by disabling logs to certain unimportant components
- Pin SystemUI to memory on MIUI
- Enable core multi-gen LRU (MGLRU) functionality to reduce CPU usage due to memory management
- Some touch hacks that [somehow still works](https://github.com/Ardjlon/android_device_xiaomi_surya/commit/e47375294471b38037db1a1c3541c82c4ad8a9be)

## [Download 📦](releases)

## Installation 
- Install the module via Magisk Manager or KernelSU

## Author

👤 **John Vincent**

* Twitter: [@TenSeventy7](https://twitter.com/TenSeventy7)
* Github: [@TenSeventy7](https://github.com/TenSeventy7)

## License 📝

Copyright © 2023 [John Vincent](https://github.com/TenSeventy7).

This project is licensed under the [GNU General Public License v3.0](LICENSE).
