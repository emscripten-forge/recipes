/* WebAssembly entry point for polymake.
 *
 * Upstream polymake is driven by the perl script perl/polymake, which starts a
 * perl interpreter and loads the C++ half through DynaLoader.  That model needs
 * a perl with dynamic loading, which the emscripten-forge perl does not have
 * (usedl='undef', dlsrc='dl_none.xs', dlext='none').
 *
 * This driver uses polymake's callable interface instead: pm::perl::Main builds
 * the perl interpreter itself and bootstraps every core XS module statically via
 * the generated polymakeBootstrapXS.h, which is exactly what a single static
 * wasm binary needs.  All application clients are linked into this executable,
 * so their static constructors have registered themselves with the C++/perl glue
 * before the first rule file is read.
 *
 * Two ways to drive it:
 *   - as a program: a line oriented read-eval-print loop on stdin, plus
 *     `-e CODE` and `--script FILE`;
 *   - from JavaScript: the polymake_* functions below are exported, so a web
 *     page can call them directly without going through stdin.
 */

#include "polymake/Main.h"

#include <cstdlib>
#include <cstring>
#include <iostream>
#include <memory>
#include <set>
#include <sstream>
#include <string>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#else
#define EMSCRIPTEN_KEEPALIVE
#endif

namespace {

// Where build.sh mounts the filesystem image inside the wasm runtime.  These
// must agree with the --preload arguments in build.sh.
#ifndef POLYMAKE_WASM_INSTALL_TOP
#define POLYMAKE_WASM_INSTALL_TOP "/polymake/share"
#endif
#ifndef POLYMAKE_WASM_INSTALL_ARCH
#define POLYMAKE_WASM_INSTALL_ARCH "/polymake/lib"
#endif
// build.sh derives this from the target perl's archlib/privlib.
#ifndef POLYMAKE_WASM_PERL5LIB
#define POLYMAKE_WASM_PERL5LIB "/polymake/perl5/core_perl"
#endif

std::unique_ptr<polymake::Main> interp;
std::string last_stdout, last_stderr, last_error;

const char* env_or(const char* name, const char* fallback)
{
   const char* v = std::getenv(name);
   return v && *v ? v : fallback;
}

} // namespace

extern "C" {

/* Start the interpreter.  Returns 0 on success, 1 on failure; on failure the
 * message is available through polymake_last_error(). */
EMSCRIPTEN_KEEPALIVE
int polymake_init(const char* application)
{
   if (interp)
      return 0;
   try {
      // Points @INC at the preloaded perl5 tree instead of the build machine's.
      setenv("PERL5LIB", env_or("POLYMAKE_WASM_PERL5LIB", POLYMAKE_WASM_PERL5LIB), 0);
      // "none" skips the interactive first-run configuration wizard.
      setenv("POLYMAKE_CONFIG_PATH", "none", 0);
      interp.reset(new polymake::Main(env_or("POLYMAKE_CONFIG_PATH", "none"),
                                  env_or("POLYMAKE_WASM_INSTALL_TOP", POLYMAKE_WASM_INSTALL_TOP),
                                  env_or("POLYMAKE_WASM_INSTALL_ARCH", POLYMAKE_WASM_INSTALL_ARCH)));
      interp->shell_enable();
      if (application && *application) {
         // AnyString points into this, so it must outlive the call.
         const std::string app_name(application);
         interp->set_application(app_name);
      }
      return 0;
   } catch (const std::exception& ex) {
      last_error = ex.what();
      interp.reset();
      return 1;
   }
}

// Lazy-init guard for entry points that don't take an application name.
bool ensure_interp()
{
   return interp || polymake_init(nullptr) == 0;
}

/* Execute one piece of polymake/perl code, as if typed into the interactive
 * shell.  Returns 1 when the input was parsed and executed, 0 when it was
 * incomplete or unparsable.  Use the accessors below to collect the output. */
EMSCRIPTEN_KEEPALIVE
int polymake_execute(const char* input)
{
   last_stdout.clear();
   last_stderr.clear();
   last_error.clear();
   if (!ensure_interp())
      return 0;
   try {
      const auto result = interp->shell_execute(input ? input : "");
      last_stdout = std::get<1>(result);
      last_stderr = std::get<2>(result);
      last_error = std::get<3>(result);
      return std::get<0>(result) ? 1 : 0;
   } catch (const std::exception& ex) {
      last_error = ex.what();
      return 0;
   }
}

EMSCRIPTEN_KEEPALIVE const char* polymake_last_stdout() { return last_stdout.c_str(); }
EMSCRIPTEN_KEEPALIVE const char* polymake_last_stderr() { return last_stderr.c_str(); }
EMSCRIPTEN_KEEPALIVE const char* polymake_last_error()  { return last_error.c_str(); }

EMSCRIPTEN_KEEPALIVE
const char* polymake_greeting()
{
   static std::string greeting;
   if (!ensure_interp())
      return last_error.c_str();
   greeting = interp->greeting();
   return greeting.c_str();
}

} // extern "C"

namespace {

void report()
{
   if (!last_stdout.empty())
      std::cout << last_stdout << std::flush;
   if (!last_stderr.empty())
      std::cerr << last_stderr << std::flush;
   if (!last_error.empty())
      std::cerr << "polymake: " << last_error << std::endl;
}

int run_string(const std::string& code)
{
   const int ok = polymake_execute(code.c_str());
   report();
   return ok ? 0 : 1;
}

// $application is polymake's own alias for the current Core::Application
// object; falls back to the last known name if the query itself fails.
std::string current_application_name(const std::string& fallback)
{
   if (polymake_execute("print $application->name;")) {
      std::string name = last_stdout;
      while (!name.empty() && (name.back() == '\n' || name.back() == '\r'))
         name.pop_back();
      if (!name.empty())
         return name;
   }
   return fallback;
}

// shell_execute returns {false, "", "", ""} for input that's syntactically
// correct but incomplete; keep buffering until a full statement is seen.
int repl(const std::string& application)
{
   std::string buffer, line;
   std::string prompt_app = application;
   std::set<std::string> credits_shown;

   std::cout << "Welcome to " << polymake_greeting() << '\n'
             << "Press F1 or enter 'help;' for basic instructions.\n"
             << std::flush;

   for (;;) {
      if (buffer.empty()) {
         // Picks up `application 'X';` without parsing the user's input.
         prompt_app = current_application_name(prompt_app);

         // Mirrors Core::Shell::get_line (Shell.pm): show each application's
         // credits banner once, the first time its prompt is shown.
         if (credits_shown.insert(prompt_app).second) {
            run_string("show_credits(1);");
            // show_unconfigured prints nothing when there's nothing to report,
            // so a non-empty result stands in for Shell.pm's internal flag.
            if (polymake_execute("show_unconfigured;") && !last_stdout.empty()) {
               std::cout <<
                  "\nWarning: some rulefiles could not be configured automatically\n"
                  "due to lacking third-party software and/or other issues.\n"
                  "To see the complete list: show_unconfigured;\n";
            }
         }

         std::cout << prompt_app << " > " << std::flush;
      } else {
         std::cout << std::string(prompt_app.size() + 3, ' ') << std::flush;
      }

      if (!std::getline(std::cin, line)) {
         std::cout << std::endl;
         break;
      }

      buffer += line;
      buffer += '\n';
      const int ok = polymake_execute(buffer.c_str());
      const bool incomplete = !ok && last_stdout.empty() && last_stderr.empty() && last_error.empty();
      if (incomplete)
         continue;
      report();
      std::cout << '\n';
      buffer.clear();
   }
   return 0;
}

} // namespace

int main(int argc, char** argv)
{
   std::string application = "polytope";
   std::string code, script;

   for (int i = 1; i < argc; ++i) {
      const std::string arg = argv[i];
      if ((arg == "-e" || arg == "--eval") && i + 1 < argc) {
         code = argv[++i];
      } else if (arg == "--script" && i + 1 < argc) {
         script = argv[++i];
      } else if ((arg == "-A" || arg == "--application") && i + 1 < argc) {
         application = argv[++i];
      } else if (!arg.empty() && arg[0] != '-' && script.empty() && code.empty()) {
         script = arg;
      } else {
         std::cerr << "polymake: unrecognized argument: " << arg << std::endl;
         return 2;
      }
   }

   if (polymake_init(application.c_str()) != 0) {
      std::cerr << "polymake: could not initialize: " << last_error << std::endl;
      return 1;
   }

   if (!code.empty())
      return run_string(code);

   if (!script.empty()) {
      std::ostringstream stmt;
      stmt << "script(\"" << script << "\");";
      return run_string(stmt.str());
   }

   return repl(application);
}
