// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Link-time support for interactive stdin. A host may supply stdinReady()
// returning a Promise that resolves when stdin() has data or reaches EOF.
// Pthread proxying waits without Asyncify; ordinary stdin also remains usable.
addToLibrary({
  fd_read__deps: ['$doReadv', '$SYSCALLS'],
  fd_read__proxy: 'sync',
  fd_read__async: 'auto',
  fd_read: (fd, iov, iovcnt, pnum) => {
    const read = () => {
      try {
        const stream = SYSCALLS.getStreamFromFD(fd);
        const num = doReadv(stream, iov, iovcnt);
        {{{ makeSetValue('pnum', 0, 'num', SIZE_TYPE) }}};
        return 0;
      } catch (error) {
        if (error.name !== 'ErrnoError') throw error;
        return error.errno;
      }
    };
    return Promise.resolve(fd === 0 ? Module.stdinReady?.() : undefined).then(read);
  },
});
