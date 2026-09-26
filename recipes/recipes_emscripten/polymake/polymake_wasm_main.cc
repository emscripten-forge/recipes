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
// build.sh derives this from the target perl's own archlib and privlib, because
// which of the two holds a given core module is a decision of the perl package, not
// something to guess: lib.pm and Config.pm sit in the architecture-dependent tree
// while most of the pure-perl library sits in the other one.
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

/* The target perl's compiled-in @INC records the prefix of the machine the perl
 * package was built on, which does not exist inside the wasm filesystem image.
 * PERL5LIB is consulted before those defaults, so pointing it at the preloaded
 * tree is what makes `use strict` and friends resolvable.  polymake adds its own
 * perllib and perlx directories itself, from pm::perl::Main. */
void prepare_environment()
{
   setenv("PERL5LIB", env_or("POLYMAKE_WASM_PERL5LIB", POLYMAKE_WASM_PERL5LIB), 0);
   // polymake writes nothing outside the image when the config path is "none";
   // "user" would start the interactive configuration wizard on first run, which
   // cannot be answered in a non-interactive wasm runtime.
   setenv("POLYMAKE_CONFIG_PATH", "none", 0);
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
      prepare_environment();
      interp.reset(new polymake::Main(env_or("POLYMAKE_CONFIG_PATH", "none"),
                                  env_or("POLYMAKE_WASM_INSTALL_TOP", POLYMAKE_WASM_INSTALL_TOP),
                                  env_or("POLYMAKE_WASM_INSTALL_ARCH", POLYMAKE_WASM_INSTALL_ARCH)));
      interp->shell_enable();
      if (application && *application) {
         // AnyString keeps a pointer into whatever string it was built from, so
         // this has to outlive the call rather than be a temporary
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

/* Execute one piece of polymake/perl code, as if typed into the interactive
 * shell.  Returns 1 when the input was parsed and executed, 0 when it was
 * incomplete or unparsable.  Use the accessors below to collect the output. */
EMSCRIPTEN_KEEPALIVE
int polymake_execute(const char* input)
{
   last_stdout.clear();
   last_stderr.clear();
   last_error.clear();
   if (!interp && polymake_init(nullptr) != 0)
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
   if (!interp && polymake_init(nullptr) != 0)
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

/* Ask the running interpreter which application is current, the same way a
 * user could by typing `print $application->name;` -- $application is
 * polymake's own documented alias for the Core::Application object that is
 * "current" at any moment, updated whenever application('NAME') runs. Falls
 * back to the last known name if the query itself fails, so a hiccup here
 * never breaks the prompt or reverts it to the startup default. */
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

/* shell_execute returns {false, "", "", ""} for input which is syntactically
 * correct but not yet complete (an open block, an unfinished statement).  Keep
 * buffering in that case so that multi-line input works the same way it does in
 * the native interactive shell. */
int repl(const std::string& application)
{
   std::string buffer, line;
   std::string prompt_app = application;

   // Main::greeting() supplies polymake's own version/copyright/license text.
   // The native interactive frontend prefixes it with "Welcome to " and adds
   // this short shell hint; keep those presentation details in the WASM driver.
   std::cout << "Welcome to " << polymake_greeting() << '\n'
             << "Press F1 or enter 'help;' for basic instructions.\n"
             << std::endl;

   for (;;) {
      if (buffer.empty()) {
         // Refreshed once per top-level prompt: picks up `application 'X';`
         // (or any other way the session's current application may have
         // changed) without having to parse the user's input for it.
         prompt_app = current_application_name(prompt_app);
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
      buffer.clear();
   }
   return 0;
}

void usage(const char* argv0)
{
   std::cerr <<
      "usage: " << argv0 << " [options] [script.pl [args...]]\n"
      "  -e CODE           execute CODE and exit\n"
      "  --script FILE     execute the polymake script FILE and exit\n"
      "  -A, --application NAME\n"
      "                    select the application to start in (default: polytope)\n"
      "  -h, --help        this message\n"
      "With no arguments a read-eval-print loop is started on stdin.\n";
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
      } else if (arg == "-h" || arg == "--help") {
         usage(argv[0]);
         return 0;
      } else if (!arg.empty() && arg[0] != '-' && script.empty() && code.empty()) {
         script = arg;
      } else {
         usage(argv[0]);
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
