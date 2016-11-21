/*
 * driver - driver for loading mruby source code
 */

#include <stdint.h>
#include <stdio.h>

#include "mruby.h"
#include "mruby/compile.h"
#include "mruby/irep.h"
#include "mruby/string.h"
mrb_value mrb_get_backtrace(mrb_state *mrb, mrb_value self);

/* The generated mruby bytecodes are stored in this array */
extern const uint8_t app_irep[];

#ifdef HAS_REQUIRE
void mrb_enable_require(mrb_state *mrb);
#endif

/*
 * Print levels:
 * 0 - Do not print anything
 * 1 - Print errors only
 * 2 - Print errors and results
 */
static int check_and_print_errors(mrb_state* mrb, mrb_value result,
                                  int print_level)
{
  if (mrb->exc && (print_level > 0)) {
    mrb_p(mrb, mrb_obj_value(mrb->exc));
    mrb->exc = 0;
    return 1;
  }

  if (print_level > 1) {
    mrb_p(mrb, result);
  }
  return 0;
}

int webruby_internal_run_bytecode(mrb_state* mrb, const uint8_t *bc,
                                  int print_level)
{
  return check_and_print_errors(mrb, mrb_load_irep(mrb, bc), print_level);
}

int webruby_internal_run(mrb_state* mrb, int print_level)
{
  return webruby_internal_run_bytecode(mrb, app_irep, print_level);
}

int webruby_internal_run_source(mrb_state* mrb, const char *s, int print_level)
{
  mrbc_context *c = NULL;
  int err;

  if (print_level > 0) {
    c = mrbc_context_new(mrb);
    //c->dump_result = TRUE;
  }
  err = check_and_print_errors(mrb, mrb_load_string_cxt(mrb, s, c),
                               print_level);
  if (c) {
    mrbc_context_free(mrb, c);
  }
  return err;
}

char* webruby_internal_run_source_file(mrb_state* mrb, const char *s, const char *filename, int print_level)
{
  mrbc_context *c = NULL;
  int err;
  char* result_ptr = "";

  if (print_level > 0) {
    c = mrbc_context_new(mrb);
    mrbc_filename(mrb, c, filename);
    //c->dump_result = TRUE;
  }

  mrb_value result = mrb_load_string_cxt(mrb, s, c);


  if (mrb->exc) {
    mrb_value exc = mrb_obj_value(mrb->exc);
    result_ptr = mrb_str_to_cstr(mrb, mrb_inspect(mrb, exc));
  }

  err = check_and_print_errors(mrb, result,
                               print_level);

  if (c) {
    mrbc_context_free(mrb, c);
  }

  return result_ptr;
  //return err;
}

int webruby_internal_setup(mrb_state* mrb)
{
#ifdef HAS_REQUIRE
  mrb_enable_require(mrb);
#endif
  return 0;
}
