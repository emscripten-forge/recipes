/* Minimal PPD declarations, see cups.h in this directory. */
#ifndef _CUPS_PPD_H_
#define _CUPS_PPD_H_

#include <stdio.h>
#include "cups.h"

#ifdef __cplusplus
extern "C" {
#endif

#define PPD_MAX_NAME 41
#define PPD_MAX_TEXT 81

typedef enum ppd_ui_e { PPD_UI_BOOLEAN, PPD_UI_PICKONE, PPD_UI_PICKMANY } ppd_ui_t;
typedef enum ppd_section_e {
  PPD_ORDER_ANY, PPD_ORDER_DOCUMENT, PPD_ORDER_EXIT, PPD_ORDER_JCL,
  PPD_ORDER_PAGE, PPD_ORDER_PROLOG
} ppd_section_t;

struct ppd_option_s;

typedef struct ppd_choice_s {
  char marked;
  char choice[PPD_MAX_NAME];
  char text[PPD_MAX_TEXT];
  char *code;
  struct ppd_option_s *option;
} ppd_choice_t;

typedef struct ppd_option_s {
  char conflicted;
  char keyword[PPD_MAX_NAME];
  char defchoice[PPD_MAX_NAME];
  char text[PPD_MAX_TEXT];
  ppd_ui_t ui;
  ppd_section_t section;
  float order;
  int num_choices;
  ppd_choice_t *choices;
} ppd_option_t;

typedef struct ppd_size_s {
  int marked;
  char name[PPD_MAX_NAME];
  float width;
  float length;
  float left;
  float bottom;
  float right;
  float top;
} ppd_size_t;

typedef struct ppd_file_s ppd_file_t;

#ifdef __cplusplus
}
#endif

#endif
