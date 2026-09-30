/*
 * jvm-main.c -- a `java`-style launcher for OpenJDK 21 (Zero) on emscripten.
 *
 *   <program> [jvm options] <main class> [args...]
 *   <program> [jvm options] -jar <file.jar> [args...]
 *   <program> [jvm options] -m <module>[/<main class>] [args...]
 *   <program> [jvm options] <source file>.java [args...]
 *
 * Arguments come from argv (node) or Module.arguments (browser). Supported
 * launcher options: -cp/-classpath/--class-path, -jar, -version, --version,
 * -showversion, and --add-opens/--add-exports/--add-modules/... in both
 * "--opt value" and "--opt=value" form. Everything else starting with '-' is
 * passed to the VM unchanged (-D, -X, -XX:, -ea, -verbose:, ...).
 *
 * The program must be linked with -sPROXY_TO_PTHREAD: main() then runs on a
 * worker, so the VM can block (monitors, Thread.join, DestroyJavaVM) while the
 * browser thread stays free for the DOM, x11.wasm and new pthreads.
 */

#include <errno.h>
#include <signal.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

#include <emscripten.h>
#include <emscripten/threading.h>
#include <jni.h>

#ifndef JVM_MAIN_JAVA_HOME
#define JVM_MAIN_JAVA_HOME "/opt/jdk"
#endif

/* ------------------------------------------------------------------------ */
/* System.in                                                                  */
/*                                                                            */
/* libjava (io_util_md.c, emscripten branch) reads fd 0 through these hooks.  */
/* Under node the ring buffer stays off and read(0) works normally. A page    */
/* calls jvm_enable_ring_buffer_stdin() once and then jvm_stdin_write() /     */
/* jvm_stdin_close() to feed System.in; a reader blocks until data arrives.   */
/* ------------------------------------------------------------------------ */

#define STDIN_RING_SIZE 65536

static unsigned char stdin_ring[STDIN_RING_SIZE];
static _Atomic int32_t stdin_write_pos;   /* monotonically increasing */
static _Atomic int32_t stdin_read_pos;
static _Atomic int32_t stdin_closed;
static _Atomic int32_t stdin_signal;
static _Atomic int32_t use_ring_buffer_stdin;

int jvm_use_ring_buffer_stdin(void) {
    return use_ring_buffer_stdin;
}

int jvm_stdin_available(void) {
    return stdin_write_pos - stdin_read_pos;
}

int stdin_read_byte(void) {
    for (;;) {
        int32_t rp = stdin_read_pos;
        int32_t wp = stdin_write_pos;
        if (rp != wp) {
            unsigned char c = stdin_ring[(uint32_t) rp % STDIN_RING_SIZE];
            stdin_read_pos = rp + 1;
            return c;
        }
        if (stdin_closed) {
            return -1;
        }
        int32_t seen = stdin_signal;
        if (stdin_write_pos == rp && !stdin_closed) {
            emscripten_futex_wait((void *) &stdin_signal, seen, 100.0);
        }
    }
}

static void stdin_wake(void) {
    stdin_signal++;
    emscripten_futex_wake((void *) &stdin_signal, INT32_MAX);
}

EMSCRIPTEN_KEEPALIVE void jvm_enable_ring_buffer_stdin(void) {
    use_ring_buffer_stdin = 1;
}

/* Returns the number of bytes accepted (less than len if the ring is full). */
EMSCRIPTEN_KEEPALIVE int jvm_stdin_write(const char *data, int len) {
    int n = 0;
    if (data == NULL) {
        return 0;
    }
    while (n < len && stdin_write_pos - stdin_read_pos < STDIN_RING_SIZE) {
        stdin_ring[(uint32_t) stdin_write_pos % STDIN_RING_SIZE] = (unsigned char) data[n++];
        stdin_write_pos++;
    }
    stdin_wake();
    return n;
}

EMSCRIPTEN_KEEPALIVE void jvm_stdin_close(void) {
    stdin_closed = 1;
    stdin_wake();
}

/* ------------------------------------------------------------------------ */
/* libc gaps                                                                  */
/* ------------------------------------------------------------------------ */

/* HotSpot's thread suspend/resume signal handler waits in sigsuspend(),
 * which emscripten's libc lacks. That handler never runs here (there are no
 * signals between wasm threads), so this only satisfies the link. */
__attribute__((weak)) int sigsuspend(const sigset_t *mask) {
    (void) mask;
    errno = EINTR;
    return -1;
}

/* HotSpot leaves through _exit() on fatal errors (os::abort). From a pthread
 * that is proxied to the browser thread, where it throws while the runtime
 * is being kept alive for the other threads, so nothing exits and the
 * calling thread waits forever. emscripten_force_exit() shuts the runtime
 * down properly. Linked with -Wl,--wrap=_exit. */
void __real__exit(int code);
void __wrap__exit(int code) {
    fflush(stdout);
    fflush(stderr);
    emscripten_force_exit(code);
    __real__exit(code);
}

/* ------------------------------------------------------------------------ */
/* thread dumps                                                               */
/*                                                                            */
/* There is no SIGQUIT to ask the VM for a thread dump. Setting               */
/* JVM_STACK_DUMP_SECONDS=N prints one every N seconds, and a page can call   */
/* Module._jvm_request_thread_dump() at any time.                             */
/* ------------------------------------------------------------------------ */

#include <pthread.h>
#include <unistd.h>

JNIEXPORT void JNICALL JVM_DumpAllStacks(JNIEnv *env, jclass unused);

static JavaVM *the_vm;
static _Atomic int32_t dump_requests;

static void *dump_thread_main(void *arg) {
    int period = (int) (intptr_t) arg;
    JNIEnv *env = NULL;
    JavaVMAttachArgs aa = { JNI_VERSION_21, "stack dumper", NULL };
    if ((*the_vm)->AttachCurrentThreadAsDaemon(the_vm, (void **) &env, &aa) != JNI_OK) {
        return NULL;
    }
    for (;;) {
        if (period > 0) {
            sleep(period);
        } else {
            int32_t seen = dump_requests;
            while (dump_requests == seen) {
                emscripten_futex_wait((void *) &dump_requests, seen, 1000.0);
            }
        }
        JVM_DumpAllStacks(env, NULL);
        fflush(stdout);
    }
    return NULL;
}

static void start_dump_thread(int period) {
    pthread_t t;
    pthread_attr_t attr;
    pthread_attr_init(&attr);
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    pthread_create(&t, &attr, dump_thread_main, (void *) (intptr_t) period);
    pthread_attr_destroy(&attr);
}

EMSCRIPTEN_KEEPALIVE void jvm_request_thread_dump(void) {
    dump_requests++;
    emscripten_futex_wake((void *) &dump_requests, INT32_MAX);
}

/* ------------------------------------------------------------------------ */
/* argument handling                                                          */
/* ------------------------------------------------------------------------ */

/* launch modes understood by sun.launcher.LauncherHelper.checkAndLoadMain */
enum { LM_CLASS = 1, LM_JAR = 2, LM_MODULE = 3, LM_SOURCE = 4 };
#define SOURCE_LAUNCHER_MAIN_ENTRY "jdk.compiler/com.sun.tools.javac.launcher.Main"

static int ends_with(const char *s, const char *suffix) {
    size_t ls = strlen(s), lx = strlen(suffix);
    return ls >= lx && strcmp(s + ls - lx, suffix) == 0;
}

typedef struct {
    char **items;
    int count, cap;
} StrList;

static void list_add(StrList *l, char *s) {
    if (l->count == l->cap) {
        l->cap = l->cap ? l->cap * 2 : 32;
        l->items = realloc(l->items, sizeof(char *) * l->cap);
    }
    l->items[l->count++] = s;
}

static char *concat(const char *a, const char *b) {
    size_t la = strlen(a), lb = strlen(b);
    char *r = malloc(la + lb + 1);
    memcpy(r, a, la);
    memcpy(r + la, b, lb + 1);
    return r;
}

/* Module options that take a separate value in the launcher but must reach
 * the VM as "--opt=value". */
static const char *const module_opts[] = {
    "--add-opens", "--add-exports", "--add-modules", "--add-reads",
    "--patch-module", "--limit-modules", "--module-path",
    "--upgrade-module-path", "--enable-native-access", NULL
};

static int is_module_opt(const char *a) {
    for (int i = 0; module_opts[i] != NULL; i++) {
        if (strcmp(a, module_opts[i]) == 0) {
            return 1;
        }
    }
    return 0;
}

static void ensure_dir(const char *path) {
    if (mkdir(path, 0777) != 0 && errno != EEXIST) {
        fprintf(stderr, "jvm-main: cannot create %s: %s\n", path, strerror(errno));
    }
}

static int check_exception(JNIEnv *env) {
    if ((*env)->ExceptionCheck(env)) {
        (*env)->ExceptionDescribe(env);
        return 1;
    }
    return 0;
}

static void usage(void) {
    fprintf(stderr,
            "Usage: [jvm options] <main class> [args...]\n"
            "   or: [jvm options] -jar <jar file> [args...]\n"
            "   or: [jvm options] -m <module>[/<main class>] [args...]\n"
            "   or: [jvm options] <source file>.java [args...]\n");
}

int main(int argc, char **argv) {
    StrList vmopts = {0};
    const char *classpath = NULL;
    const char *what = NULL;
    int mode = 0;
    int print_version = 0;      /* 1: -version (stderr), 2: --version (stdout) */
    int show_version = 0;
    int chose_gc = 0;
    int i;

    const char *java_home = getenv("JAVA_HOME");
    if (java_home == NULL || *java_home == '\0') {
        java_home = JVM_MAIN_JAVA_HOME;
        /* os::jvm_path() reads JAVA_HOME before -Djava.home is parsed. */
        setenv("JAVA_HOME", java_home, 1);
    }
    if (getenv("HOME") == NULL) setenv("HOME", "/home/web_user", 1);
    if (getenv("USER") == NULL) setenv("USER", "web_user", 1);
    if (getenv("LANG") == NULL) setenv("LANG", "C.UTF-8", 1);
    /* x11.wasm is the display; AWT treats an unset DISPLAY as headless. */
    if (getenv("DISPLAY") == NULL) setenv("DISPLAY", ":0", 1);

    ensure_dir("/tmp");
    ensure_dir(getenv("HOME"));

    /* defaults first, so anything on the command line overrides them */
    list_add(&vmopts, concat("-Djava.home=", java_home));
    list_add(&vmopts, "-XX:-UsePerfData");         /* no mmap'd hsperfdata */
    list_add(&vmopts, "-XX:+ReduceSignalUsage");   /* no signals in wasm */
    list_add(&vmopts, "-Xshare:off");              /* no CDS archive shipped */
    list_add(&vmopts, "-Xss1m");
    list_add(&vmopts, concat("-Duser.home=", getenv("HOME")));
    list_add(&vmopts, "-Dsun.java.launcher=SUN_STANDARD");

    for (i = 1; i < argc; i++) {
        char *a = argv[i];
        if (strcmp(a, "-cp") == 0 || strcmp(a, "-classpath") == 0 ||
            strcmp(a, "--class-path") == 0) {
            if (++i >= argc) { usage(); return 2; }
            classpath = argv[i];
        } else if (strncmp(a, "--class-path=", 13) == 0) {
            classpath = a + 13;
        } else if (strcmp(a, "-jar") == 0) {
            if (++i >= argc) { usage(); return 2; }
            what = argv[i];
            mode = LM_JAR;
            i++;
            break;
        } else if (strcmp(a, "-m") == 0 || strcmp(a, "--module") == 0 ||
                   strncmp(a, "--module=", 9) == 0) {
            if (a[1] == '-' && a[8] == '=') {
                what = a + 9;
            } else {
                if (++i >= argc) { usage(); return 2; }
                what = argv[i];
            }
            mode = LM_MODULE;
            {
                /* -Djdk.module.main=<module> (the part before any '/') */
                const char *slash = strchr(what, '/');
                size_t n = slash ? (size_t) (slash - what) : strlen(what);
                char *opt = malloc(n + sizeof("-Djdk.module.main="));
                strcpy(opt, "-Djdk.module.main=");
                strncat(opt, what, n);
                list_add(&vmopts, opt);
            }
            i++;
            break;
        } else if (strcmp(a, "-version") == 0) {
            print_version = 1;
        } else if (strcmp(a, "--version") == 0) {
            print_version = 2;
        } else if (strcmp(a, "-showversion") == 0) {
            show_version = 1;
        } else if (strncmp(a, "-splash:", 8) == 0) {
            /* not supported; ignore like a headless launcher would */
        } else if (is_module_opt(a) || strcmp(a, "-p") == 0) {
            if (++i >= argc) { usage(); return 2; }
            const char *name = strcmp(a, "-p") == 0 ? "--module-path" : a;
            char *eq = concat(name, "=");
            list_add(&vmopts, concat(eq, argv[i]));
            free(eq);
        } else if (a[0] == '-') {
            if (strncmp(a, "-XX:+Use", 8) == 0 && strstr(a, "GC") != NULL) {
                chose_gc = 1;
            }
            list_add(&vmopts, a);
        } else {
            struct stat st;
            if (ends_with(a, ".java") && stat(a, &st) == 0) {
                /* source-file mode: the source launcher gets the file name
                 * as its first argument */
                what = SOURCE_LAUNCHER_MAIN_ENTRY;
                mode = LM_SOURCE;
                list_add(&vmopts, "--add-modules=ALL-DEFAULT");
            } else {
                what = a;
                mode = LM_CLASS;
                i++;
            }
            break;
        }
    }

    /* HotSpot would pick G1 here (it sees >= 2 CPUs and >= 2 GB); the serial
     * collector needs no helper threads and the least memory. */
    if (!chose_gc) {
        list_add(&vmopts, "-XX:+UseSerialGC");
    }
    if (mode == LM_JAR) {
        classpath = what;
    }
    if (classpath == NULL) {
        classpath = getenv("CLASSPATH");
    }
    list_add(&vmopts, concat("-Djava.class.path=", classpath ? classpath : "."));

    if (what == NULL && !print_version) {
        usage();
        return 2;
    }

    JavaVMOption *options = calloc(vmopts.count, sizeof(JavaVMOption));
    for (int k = 0; k < vmopts.count; k++) {
        options[k].optionString = vmopts.items[k];
    }
    JavaVMInitArgs vm_args;
    vm_args.version = JNI_VERSION_21;
    vm_args.nOptions = vmopts.count;
    vm_args.options = options;
    vm_args.ignoreUnrecognized = JNI_FALSE;

    JavaVM *vm = NULL;
    JNIEnv *env = NULL;
    jint rc = JNI_CreateJavaVM(&vm, (void **) &env, &vm_args);
    if (rc != JNI_OK) {
        fprintf(stderr, "Error: could not create the Java Virtual Machine (%d).\n", (int) rc);
        return 1;
    }

    int ret = 1;

    the_vm = vm;
    {
        const char *dump = getenv("JVM_STACK_DUMP_SECONDS");
        start_dump_thread(dump != NULL ? atoi(dump) : 0);
    }

    if (print_version || show_version) {
        jclass vp = (*env)->FindClass(env, "java/lang/VersionProps");
        jmethodID print = vp ? (*env)->GetStaticMethodID(env, vp, "print", "(Z)V") : NULL;
        if (print != NULL) {
            (*env)->CallStaticVoidMethod(env, vp, print, print_version == 2 ? JNI_FALSE : JNI_TRUE);
        }
        if (check_exception(env)) goto leave;
        if (print_version) { ret = 0; goto leave; }
    }

    /* Same entry path as the real launcher: LauncherHelper validates the
     * class (or reads Main-Class from the jar manifest) and loads it. */
    jclass helper = (*env)->FindClass(env, "sun/launcher/LauncherHelper");
    if (helper == NULL) { check_exception(env); goto leave; }
    jmethodID check = (*env)->GetStaticMethodID(env, helper, "checkAndLoadMain",
                                                "(ZILjava/lang/String;)Ljava/lang/Class;");
    if (check == NULL) { check_exception(env); goto leave; }
    jstring jwhat = (*env)->NewStringUTF(env, what);
    jclass main_class = (jclass) (*env)->CallStaticObjectMethod(env, helper, check,
                                                                 JNI_TRUE, (jint) mode, jwhat);
    if (check_exception(env) || main_class == NULL) goto leave;

    jmethodID main_id = (*env)->GetStaticMethodID(env, main_class, "main", "([Ljava/lang/String;)V");
    if (main_id == NULL) { check_exception(env); goto leave; }

    jclass string_class = (*env)->FindClass(env, "java/lang/String");
    jobjectArray jargs = (*env)->NewObjectArray(env, argc - i, string_class, NULL);
    for (int k = i; k < argc; k++) {
        jstring s = (*env)->NewStringUTF(env, argv[k]);
        (*env)->SetObjectArrayElement(env, jargs, k - i, s);
        (*env)->DeleteLocalRef(env, s);
    }
    if (check_exception(env)) goto leave;

    (*env)->CallStaticVoidMethod(env, main_class, main_id, jargs);
    ret = check_exception(env) ? 1 : 0;

leave:
    /* Like libjli: detach, then DestroyJavaVM waits for all non-daemon
     * threads -- which is what keeps a Swing program alive after main(). */
    (*vm)->DetachCurrentThread(vm);
    (*vm)->DestroyJavaVM(vm);
    fflush(stdout);
    fflush(stderr);
    return ret;
}
