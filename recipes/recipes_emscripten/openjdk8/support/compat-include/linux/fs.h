/* linux/fs.h -- compatibility header for building OpenJDK with Emscripten. */
#ifndef _COMPAT_LINUX_FS_H
#define _COMPAT_LINUX_FS_H
#include <sys/ioctl.h>
#include <stddef.h>
#ifndef BLKGETSIZE64
#define BLKGETSIZE64 _IOR(0x12, 114, size_t)
#endif
#endif
