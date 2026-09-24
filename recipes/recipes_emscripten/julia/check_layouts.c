/* Compares the C layout of the runtime structures between the i686 bootstrap
 * build (which generates the system image) and the wasm32 build (which loads
 * it). The image stores runtime objects with their in-memory layout, and the
 * generated code bakes in offsets such as jl_tls_states_t::defer_signal or the
 * GC pool offsets, so the two builds have to agree on all of these.
 *
 * Built for both targets during the recipe's build and diffed.
 */
#include <stddef.h>
#include <stdio.h>

#include "julia.h"
#include "julia_internal.h"
#include "gc.h"

/* Alignment is deliberately not compared: i686 aligns 64-bit members to 4
 * and wasm32 to 8, which changes _Alignof of a few structs without moving
 * any member. "info" lines are reported but not compared either. */
#define SIZE(T) printf("sizeof %-28s %6zu\n", #T, sizeof(T))
#define INFO_SIZE(T) printf("info sizeof %-23s %6zu\n", #T, sizeof(T))
#define OFF(T, F) printf("offset %-22s %-24s %6zu\n", #T, #F, (size_t)offsetof(T, F))

int main(void)
{
    SIZE(void *);
    SIZE(size_t);
    SIZE(jl_taggedvalue_t);
    SIZE(jl_datatype_t);
    SIZE(jl_typename_t);
    SIZE(jl_svec_t);
    SIZE(jl_array_t);
    SIZE(jl_module_t);
    SIZE(jl_binding_t);
    SIZE(jl_method_t);
    SIZE(jl_method_instance_t);
    SIZE(jl_code_instance_t);
    SIZE(jl_typemap_entry_t);
    SIZE(jl_typemap_level_t);
    SIZE(jl_methtable_t);
    SIZE(jl_expr_t);
    SIZE(jl_handler_t);
    SIZE(jl_gcframe_t);
    SIZE(jl_excstack_t);
    SIZE(jl_datatype_layout_t);
    /* the bootstrap build has COPY_STACKS (an extra jmp_buf at the end) */
    INFO_SIZE(jl_tls_states_t);
    SIZE(jl_thread_heap_t);
    SIZE(jl_thread_gc_num_t);
    SIZE(jl_gc_pool_t);
    SIZE(jl_gc_mark_cache_t);
    SIZE(jl_uuid_t);
    SIZE(htable_t);
    SIZE(arraylist_t);
    SIZE(ios_t);
    SIZE(jl_jmp_buf);

    OFF(jl_array_t, data);
    OFF(jl_array_t, length);
    OFF(jl_array_t, flags);
    OFF(jl_array_t, elsize);
    OFF(jl_array_t, offset);
    OFF(jl_array_t, nrows);
    OFF(jl_datatype_t, name);
    OFF(jl_datatype_t, super);
    OFF(jl_datatype_t, parameters);
    OFF(jl_datatype_t, types);
    OFF(jl_datatype_t, instance);
    OFF(jl_datatype_t, layout);
    OFF(jl_datatype_t, size);
    OFF(jl_datatype_t, ninitialized);
    OFF(jl_typename_t, name);
    OFF(jl_typename_t, cache);
    OFF(jl_typename_t, hash);
    OFF(jl_module_t, build_id);
    OFF(jl_module_t, uuid);
    OFF(jl_module_t, primary_world);
    OFF(jl_module_t, counter);
    OFF(jl_module_t, istopmod);
    OFF(jl_method_t, primary_world);
    OFF(jl_method_t, deleted_world);
    OFF(jl_method_t, nargs);
    OFF(jl_method_instance_t, specTypes);
    OFF(jl_method_instance_t, cache);
    OFF(jl_code_instance_t, min_world);
    OFF(jl_code_instance_t, max_world);
    OFF(jl_code_instance_t, invoke);
    OFF(jl_code_instance_t, specptr);
    OFF(jl_handler_t, eh_ctx);
    OFF(jl_handler_t, gcstack);
    OFF(jl_handler_t, prev);
    OFF(jl_handler_t, gc_state);
    OFF(jl_handler_t, defer_signal);
    OFF(jl_handler_t, world_age);
    OFF(jl_tls_states_t, pgcstack);
    OFF(jl_tls_states_t, world_age);
    OFF(jl_tls_states_t, tid);
    OFF(jl_tls_states_t, safepoint);
    OFF(jl_tls_states_t, gc_state);
    OFF(jl_tls_states_t, in_finalizer);
    OFF(jl_tls_states_t, disable_gc);
    OFF(jl_tls_states_t, heap);
    OFF(jl_tls_states_t, gc_num);
    OFF(jl_tls_states_t, defer_signal);
    OFF(jl_tls_states_t, current_task);
    OFF(jl_tls_states_t, root_task);
    OFF(jl_thread_heap_t, weak_refs);
    OFF(jl_thread_heap_t, norm_pools);
    OFF(jl_task_t, next);
    OFF(jl_task_t, state);
    OFF(jl_task_t, start);
    OFF(jl_task_t, sticky);
    return 0;
}
