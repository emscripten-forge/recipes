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

#include <cctype>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <memory>
#include <set>
#include <sstream>
#include <string>
#include <sys/ioctl.h>
#include <termios.h>
#include <unistd.h>
#include <vector>

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

/* ----------------------------------------------------------------------------
 * Line editing with TAB completion.
 *
 * Core::Shell hands line editing to GNU readline, which completes on TAB
 * through Completion::get_completion.  There is no readline here, and the
 * terminal's own line discipline cannot complete for us because in canonical
 * mode it only releases a line once return is pressed -- the program never sees
 * the partial input.  So the driver switches the terminal to raw mode and edits
 * the line itself, asking polymake through Main::shell_complete.
 * ------------------------------------------------------------------------- */

/* Emscripten mounts its stdin as a tty device whatever it is really attached
 * to, so isatty() cannot tell a terminal from a pipe: under node the host
 * knows, and anywhere else -- a worker driving a pty from the page -- there is
 * a terminal. */
bool stdin_is_terminal()
{
#ifdef __EMSCRIPTEN__
   return EM_ASM_INT({
      return (typeof process === "object" && process.stdin) ? (process.stdin.isTTY ? 1 : 0) : 1;
   }) != 0;
#else
   return isatty(STDIN_FILENO) != 0;
#endif
}

// ICANON, ECHO and ISIG go; c_oflag is left alone so that "\n" still becomes
// CR LF and the rest of the driver's output needs no changes.
struct RawMode {
   termios saved;
   bool active;

   RawMode() : active(false)
   {
      if (!stdin_is_terminal() || tcgetattr(STDIN_FILENO, &saved) != 0)
         return;
      termios raw = saved;
      raw.c_lflag &= ~(ICANON | ECHO | ISIG);
      raw.c_cc[VMIN] = 1;
      raw.c_cc[VTIME] = 0;
      active = tcsetattr(STDIN_FILENO, TCSANOW, &raw) == 0;
   }
   ~RawMode() { if (active) tcsetattr(STDIN_FILENO, TCSANOW, &saved); }
};

int read_byte()
{
   unsigned char c;
   return read(STDIN_FILENO, &c, 1) == 1 ? c : -1;
}

/* The line being edited, and what the last redraw left on the screen.
 *
 * A line longer than the terminal is wide occupies several rows, and a carriage
 * return only reaches the start of the row the cursor is on, not the start of
 * the prompt.  Redrawing therefore has to walk up over the rows the previous
 * redraw used and clear each of them; this is the scheme linenoise calls
 * refreshMultiLine.  maxrows remembers how tall the line has ever been, since
 * that is how much needs clearing, and oldpos which row the cursor was left on.
 *
 * Nothing the editor writes ends in a newline, so every write is pushed out
 * explicitly: emscripten buffers stdout per line on the JavaScript side. */
std::size_t terminal_columns()
{
   winsize ws;
   if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == 0 && ws.ws_col > 0)
      return ws.ws_col;
   return 80;
}

struct Editor {
   std::string prompt, line;
   std::size_t point;
   std::size_t oldpos, maxrows;
   std::size_t cols;

   // asked once: the pty carries no resize notification anyway
   Editor() : point(0), oldpos(0), maxrows(0), cols(terminal_columns()) {}

   // Call after writing anything of our own: the cursor then starts a fresh row
   // and nothing above it belongs to the line any more.
   void start_fresh_row() { oldpos = 0; maxrows = 0; }

   static void push()
   {
      std::cout << std::flush;
#ifdef __EMSCRIPTEN__
      fsync(STDOUT_FILENO);
#endif
   }

   /* Appending at the end of a line that has not wrapped is what typing is,
    * and redrawing the whole line for it is what makes the cursor jump: the
    * pty hands the terminal one byte at a time, so the redraw is not atomic
    * and the carriage return at the head of it is drawn on its own.  Emit just
    * the character instead and let the terminal advance the cursor. */
   bool append(char c)
   {
      if (point != line.size() || maxrows > 1 || prompt.size() + line.size() + 1 >= cols)
         return false;
      line.insert(point++, 1, c);
      std::cout << c;
      push();
      oldpos = point;
      return true;
   }

   // Likewise for rubbing out the character before the cursor.
   bool backspace()
   {
      if (point != line.size() || point == 0 || maxrows > 1 ||
          prompt.size() + line.size() >= cols)
         return false;
      line.erase(--point, 1);
      std::cout << "\b \b";
      push();
      oldpos = point;
      return true;
   }

   void refresh()
   {
      const std::size_t plen = prompt.size();
      std::size_t rows = (plen + line.size() + cols - 1) / cols;
      if (rows == 0)
         rows = 1;
      const std::size_t old_rows = maxrows ? maxrows : 1;
      const std::size_t old_row = (plen + oldpos) / cols + 1;
      if (rows > maxrows)
         maxrows = rows;

      std::string out;
      if (old_rows > old_row)
         out += "\033[" + std::to_string(old_rows - old_row) + 'B';
      for (std::size_t j = 1; j < old_rows; ++j)
         out += "\r\033[0K\033[1A";
      out += "\r\033[0K";
      out += prompt;
      out += line;

      // a cursor resting exactly on the right edge would otherwise stay on the
      // row it just filled instead of moving to the next one
      if (point == line.size() && plen + point > 0 && (plen + point) % cols == 0) {
         out += "\n\r";
         if (++rows > maxrows)
            maxrows = rows;
      }

      const std::size_t row = (plen + point) / cols + 1;
      if (rows > row)
         out += "\033[" + std::to_string(rows - row) + 'A';
      out += '\r';
      const std::size_t col = (plen + point) % cols;
      if (col)
         out += "\033[" + std::to_string(col) + 'C';

      std::cout << out;
      push();
      oldpos = point;
   }

   // Leave the cursor after the line and start a new row, as return does.
   void finish()
   {
      const std::size_t saved = point;
      point = line.size();
      refresh();
      point = saved;
      std::cout << '\n';
      push();
      start_fresh_row();
   }
};

/* shell_complete returns the length of the already typed prefix that the
 * proposals repeat, a character to append after a unique match, and the
 * proposals themselves. */
void complete(Editor& ed, const std::string& context)
{
   if (!interp)
      return;
   std::vector<std::string> proposals;
   int offset = 0;
   char append = 0;
   try {
      const auto result = interp->shell_complete(context + ed.line.substr(0, ed.point));
      offset = std::get<0>(result);
      append = std::get<1>(result);
      proposals = std::get<2>(result);
   } catch (const std::exception&) {
      return;
   }
   if (proposals.empty() || offset < 0)
      return;

   std::string common = proposals.front();
   for (const auto& p : proposals) {
      std::size_t i = 0;
      while (i < common.size() && i < p.size() && common[i] == p[i])
         ++i;
      common.resize(i);
   }

   if (common.size() > std::size_t(offset)) {
      const std::string add = common.substr(offset);
      ed.line.insert(ed.point, add);
      ed.point += add.size();
      if (proposals.size() == 1 && append) {
         ed.line.insert(ed.point, 1, append);
         ++ed.point;
      }
   } else if (proposals.size() > 1) {
      // readline lists the candidates once they no longer share a prefix
      ed.finish();
      const std::size_t cols = ed.cols;
      std::size_t col = 0;
      for (const auto& p : proposals) {
         if (col && col + p.size() + 2 > cols - 2) {
            std::cout << '\n';
            col = 0;
         }
         std::cout << p << "  ";
         col += p.size() + 2;
      }
      std::cout << '\n';
      Editor::push();
   }
}

/* Ctrl-C abandons the whole input group, not just the line being typed, which
 * is why the caller has to hear about it separately. */
enum class Read { Line, Eof, Cancelled };

Read read_line(const std::string& prompt, const std::string& context,
               std::vector<std::string>& history, std::string& out)
{
   Editor ed;
   std::string saved_line;
   std::size_t hist = history.size();
   ed.prompt = prompt;

   ed.refresh();
   for (;;) {
      const int c = read_byte();
      if (c < 0)
         return Read::Eof;
      switch (c) {
      case '\r':
      case '\n':
         ed.finish();
         out = ed.line;
         return Read::Line;
      case 0x04:                                   // Ctrl-D
         if (ed.line.empty()) {
            ed.finish();
            return Read::Eof;
         }
         break;
      case 0x03:                                   // Ctrl-C
         std::cout << "^C";
         ed.finish();
         out = ed.line;
         return Read::Cancelled;
      case '\t':
         complete(ed, context);
         break;
      case 0x7f:
      case '\b':
         if (ed.backspace())
            continue;
         if (ed.point > 0)
            ed.line.erase(--ed.point, 1);
         break;
      case 0x01: ed.point = 0; break;              // Ctrl-A
      case 0x05: ed.point = ed.line.size(); break; // Ctrl-E
      case 0x0b: ed.line.erase(ed.point); break;   // Ctrl-K
      case 0x15: ed.line.erase(0, ed.point); ed.point = 0; break;   // Ctrl-U
      case 0x17: {                                 // Ctrl-W
         std::size_t i = ed.point;
         while (i > 0 && std::isspace(static_cast<unsigned char>(ed.line[i-1]))) --i;
         while (i > 0 && !std::isspace(static_cast<unsigned char>(ed.line[i-1]))) --i;
         ed.line.erase(i, ed.point - i);
         ed.point = i;
         break;
      }
      case 0x1b: {                                 // escape sequence
         const int a = read_byte();
         if (a != '[' && a != 'O')
            break;
         const int b = read_byte();
         if (b == 'A' || b == 'B') {
            if (hist == history.size())
               saved_line = ed.line;
            if (b == 'A' ? hist > 0 : hist < history.size()) {
               hist += b == 'A' ? -1 : 1;
               ed.line = hist == history.size() ? saved_line : history[hist];
               ed.point = ed.line.size();
            }
         } else if (b == 'C') {
            if (ed.point < ed.line.size()) ++ed.point;
         } else if (b == 'D') {
            if (ed.point > 0) --ed.point;
         } else if (b == 'H') {
            ed.point = 0;
         } else if (b == 'F') {
            ed.point = ed.line.size();
         } else if (b == '3') {
            if (read_byte() == '~' && ed.point < ed.line.size())
               ed.line.erase(ed.point, 1);
         }
         break;
      }
      default:
         if (c >= 0x20) {
            if (ed.append(static_cast<char>(c)))
               continue;
            ed.line.insert(ed.point++, 1, static_cast<char>(c));
         }
         break;
      }
      ed.refresh();
   }
}

// shell_execute returns {false, "", "", ""} for input that's syntactically
// correct but incomplete; keep buffering until a full statement is seen.
int repl(const std::string& application)
{
   RawMode raw;
   std::vector<std::string> history;
   std::string buffer, line;
   std::string prompt_app = application;
   std::set<std::string> credits_shown;

   std::cout << "Welcome to " << polymake_greeting() << '\n'
             << "Press F1 or enter 'help;' for basic instructions.\n"
             << std::flush;

   for (;;) {
      std::string prompt;
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

         prompt = prompt_app + " > ";
      } else {
         prompt = std::string(prompt_app.size() + 3, ' ');
      }

      if (raw.active) {
         const Read r = read_line(prompt, buffer, history, line);
         if (r == Read::Eof) {
            std::cout << std::endl;
            break;
         }
         if (r == Read::Cancelled) {
            // Shell::readline says "Canceled" when there was something to
            // cancel -- a continued input, or a line with anything on it --
            // and otherwise reminds the user how to leave.
            const bool had_input = !buffer.empty() ||
                                   line.find_first_not_of(" \t") != std::string::npos;
            std::cout << (had_input ? "Canceled\n" : "Type 'exit;' to leave polymake\n")
                      << std::flush;
            buffer.clear();
            continue;
         }
         history.push_back(line);
      } else {
         std::cout << prompt << std::flush;
         if (!std::getline(std::cin, line)) {
            std::cout << std::endl;
            break;
         }
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
