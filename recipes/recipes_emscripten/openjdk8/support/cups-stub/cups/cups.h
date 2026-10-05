/*
 * Minimal CUPS declarations for building OpenJDK's CUPS bridge
 * (CUPSfuncs.c).  OpenJDK loads libcups with dlopen() at run time; in the
 * browser there is no CUPS, so only the types are needed at build time.
 * The layouts follow the public CUPS 2.x headers.
 */
#ifndef _CUPS_CUPS_H_
#define _CUPS_CUPS_H_

#include <stddef.h>
#include <string.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct _http_s http_t;

typedef struct cups_option_s {
  char *name;
  char *value;
} cups_option_t;

typedef struct cups_dest_s {
  char *name;
  char *instance;
  int is_default;
  int num_options;
  cups_option_t *options;
} cups_dest_t;

#ifdef __cplusplus
}
#endif

#endif
