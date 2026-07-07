#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <graphviz/cgraph.h>
#include <graphviz/gvc.h>
#include <graphviz/gvcext.h>

#ifdef _WIN32
#define IMPORT __declspec(dllimport)
#else
#define IMPORT /* nothing */
#endif

IMPORT extern gvplugin_library_t gvplugin_dot_layout_LTX_library;
IMPORT extern gvplugin_library_t gvplugin_core_LTX_library;

int main(void)
{
    lt_symlist_t lt_preloaded_symbols[3] = {
        { "gvplugin_dot_layout_LTX_library", &gvplugin_dot_layout_LTX_library },
        { "gvplugin_core_LTX_library", &gvplugin_core_LTX_library },
        { 0, 0 }
    };

    /* Create a graph context with built-in plugins. */
    GVC_t *gvc = gvContextPlugins(lt_preloaded_symbols, 0);
    if (!gvc) {
        fprintf(stderr, "ERROR: gvContextPlugins() returned NULL\n");
        return 1;
    }

    /* Create a simple directed graph */
    Agraph_t *g = agopen("G", Agdirected, NULL);
    if (!g) {
        fprintf(stderr, "ERROR: agopen() returned NULL\n");
        gvFreeContext(gvc);
        return 1;
    }

    /* Add three nodes */
    Agnode_t *a = agnode(g, "A", 1);
    Agnode_t *b = agnode(g, "B", 1);
    Agnode_t *c = agnode(g, "C", 1);
    if (!a || !b || !c) {
        fprintf(stderr, "ERROR: agnode() returned NULL\n");
        agclose(g);
        gvFreeContext(gvc);
        return 1;
    }

    /* Add edges: A -> B, B -> C, A -> C */
    Agedge_t *e1 = agedge(g, a, b, NULL, 1);
    Agedge_t *e2 = agedge(g, b, c, NULL, 1);
    Agedge_t *e3 = agedge(g, a, c, NULL, 1);
    if (!e1 || !e2 || !e3) {
        fprintf(stderr, "ERROR: agedge() returned NULL\n");
        agclose(g);
        gvFreeContext(gvc);
        return 1;
    }

    /* Set a label for the graph */
    agsafeset(g, (char*)"label", (char*)"Test Graph", (char*)"");

    /* Compute a layout using the dot engine */
    if (gvLayout(gvc, g, "dot") != 0) {
        fprintf(stderr, "ERROR: gvLayout() failed\n");
        agclose(g);
        gvFreeContext(gvc);
        return 1;
    }

    /* Render to DOT format in memory */
    char *result = NULL;
    size_t length = 0;
    if (gvRenderData(gvc, g, "dot", &result, &length) != 0) {
        fprintf(stderr, "ERROR: gvRenderData() failed\n");
        gvFreeLayout(gvc, g);
        agclose(g);
        gvFreeContext(gvc);
        return 1;
    }

    /* Verify we got output */
    if (!result || length == 0) {
        fprintf(stderr, "ERROR: gvRenderData() returned empty result\n");
        gvFreeLayout(gvc, g);
        agclose(g);
        gvFreeContext(gvc);
        return 1;
    }

    printf("Graph rendered successfully (%zu bytes):\n%s\n", length, result);

    /* Verify the output contains expected elements */
    if (strstr(result, "digraph") == NULL) {
        fprintf(stderr, "ERROR: output does not contain 'digraph'\n");
        gvFreeRenderData(result);
        gvFreeLayout(gvc, g);
        agclose(g);
        gvFreeContext(gvc);
        return 1;
    }
    if (strstr(result, "A -> B") == NULL) {
        fprintf(stderr, "ERROR: output does not contain 'A -> B'\n");
        gvFreeRenderData(result);
        gvFreeLayout(gvc, g);
        agclose(g);
        gvFreeContext(gvc);
        return 1;
    }

    /* Cleanup */
    gvFreeRenderData(result);
    gvFreeLayout(gvc, g);
    agclose(g);
    gvFreeContext(gvc);

    printf("All tests passed!\n");
    return 0;
}
