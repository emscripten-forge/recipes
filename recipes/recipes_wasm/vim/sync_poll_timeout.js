// Emscripten's synchronous __syscall_poll ignores its timeout and calls
// stream_ops.poll(stream) without one. Override it so that, if no fd is ready,
// each stream's poll handler is called again with the timeout, so that a handler
// that can block synchronously (e.g. the cockle TTY) may wait for up to timeout ms
// (negative means wait forever). Handlers that ignore it return immediately.
addToLibrary({
  __syscall_poll__deps: ['$doPollSync', '$FS'],
  __syscall_poll: (fds, nfds, timeout) => {
    var count = doPollSync(fds, nfds);
    if (count || !timeout) return count;
    for (var i = 0, pollfd = fds; i < nfds; i++, pollfd += {{{ C_STRUCTS.pollfd.__size__ }}}) {
      var stream = FS.getStream({{{ makeGetValue('pollfd', C_STRUCTS.pollfd.fd, 'i32') }}});
      if (!stream?.stream_ops?.poll) continue;
      var events = {{{ makeGetValue('pollfd', C_STRUCTS.pollfd.events, 'i16') }}};
      var revents = stream.stream_ops.poll(stream, timeout) &
        (events | {{{ cDefs.POLLERR }}} | {{{ cDefs.POLLHUP }}} | {{{ cDefs.POLLNVAL }}});
      if (revents) {
        {{{ makeSetValue('pollfd', C_STRUCTS.pollfd.revents, 'revents', 'i16') }}};
        count++;
        timeout = 0; // Once an fd is ready, don't block on any of the others.
      }
    }
    return count;
  },
});
