set(_FFMPEG_PREFIX "${CMAKE_CURRENT_LIST_DIR}/../../..")
set(_FFMPEG_INCLUDE_DIR "${_FFMPEG_PREFIX}/include")
set(_FFMPEG_LIBRARY_DIR "${_FFMPEG_PREFIX}/lib")

if(NOT TARGET FFmpeg::avutil)
  add_library(FFmpeg::avutil STATIC IMPORTED)
  set_target_properties(FFmpeg::avutil PROPERTIES
    IMPORTED_LOCATION "${_FFMPEG_LIBRARY_DIR}/libavutil.a"
    INTERFACE_INCLUDE_DIRECTORIES "${_FFMPEG_INCLUDE_DIR}"
  )

  add_library(FFmpeg::swresample STATIC IMPORTED)
  set_target_properties(FFmpeg::swresample PROPERTIES
    IMPORTED_LOCATION "${_FFMPEG_LIBRARY_DIR}/libswresample.a"
    INTERFACE_INCLUDE_DIRECTORIES "${_FFMPEG_INCLUDE_DIR}"
    INTERFACE_LINK_LIBRARIES FFmpeg::avutil
  )

  add_library(FFmpeg::swscale STATIC IMPORTED)
  set_target_properties(FFmpeg::swscale PROPERTIES
    IMPORTED_LOCATION "${_FFMPEG_LIBRARY_DIR}/libswscale.a"
    INTERFACE_INCLUDE_DIRECTORIES "${_FFMPEG_INCLUDE_DIR}"
    INTERFACE_LINK_LIBRARIES FFmpeg::avutil
  )

  add_library(FFmpeg::avcodec STATIC IMPORTED)
  set_target_properties(FFmpeg::avcodec PROPERTIES
    IMPORTED_LOCATION "${_FFMPEG_LIBRARY_DIR}/libavcodec.a"
    INTERFACE_INCLUDE_DIRECTORIES "${_FFMPEG_INCLUDE_DIR}"
    INTERFACE_LINK_LIBRARIES "FFmpeg::swresample;FFmpeg::avutil"
  )

  add_library(FFmpeg::avformat STATIC IMPORTED)
  set_target_properties(FFmpeg::avformat PROPERTIES
    IMPORTED_LOCATION "${_FFMPEG_LIBRARY_DIR}/libavformat.a"
    INTERFACE_INCLUDE_DIRECTORIES "${_FFMPEG_INCLUDE_DIR}"
    INTERFACE_LINK_LIBRARIES "FFmpeg::avcodec;FFmpeg::swresample;FFmpeg::avutil"
  )

  add_library(FFmpeg::avfilter STATIC IMPORTED)
  set_target_properties(FFmpeg::avfilter PROPERTIES
    IMPORTED_LOCATION "${_FFMPEG_LIBRARY_DIR}/libavfilter.a"
    INTERFACE_INCLUDE_DIRECTORIES "${_FFMPEG_INCLUDE_DIR}"
    INTERFACE_LINK_LIBRARIES "FFmpeg::avformat;FFmpeg::avcodec;FFmpeg::swresample;FFmpeg::avutil"
  )

  add_library(FFmpeg::avdevice STATIC IMPORTED)
  set_target_properties(FFmpeg::avdevice PROPERTIES
    IMPORTED_LOCATION "${_FFMPEG_LIBRARY_DIR}/libavdevice.a"
    INTERFACE_INCLUDE_DIRECTORIES "${_FFMPEG_INCLUDE_DIR}"
    INTERFACE_LINK_LIBRARIES "FFmpeg::avformat;FFmpeg::avcodec;FFmpeg::swresample;FFmpeg::avutil"
  )
endif()

set(FFmpeg_FOUND TRUE)
