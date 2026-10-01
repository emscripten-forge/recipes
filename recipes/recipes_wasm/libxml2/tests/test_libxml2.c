/*
 * End-to-end link test for libxml2. Two subtests:
 *
 *  1. test_parse_and_xpath: parses an in-memory XML document and evaluates
 *     an XPath expression. Exercises the core parser + XPath engine.
 *
 *  2. test_gzipped_parse: writes a small .xml.gz file and asks libxml2 to
 *     parse it by filename. This exercises libxml2's transparent-gzip
 *     input path (LIBXML2_WITH_ZLIB=ON). Currently reported as a WARN
 *     rather than a hard failure because zlib isn't wired up yet; a
 *     subsequent commit enabling LIBXML2_WITH_ZLIB will make this a
 *     hard assertion.
 *
 * The main() return code aggregates only the hard-failure subtests.
 */
#include <stdio.h>
#include <string.h>
#include <zlib.h>
#include <libxml/parser.h>
#include <libxml/tree.h>
#include <libxml/xpath.h>

#define CHECK(cond, msg)                                                       \
    do {                                                                       \
        if (!(cond)) {                                                         \
            fprintf(stderr, "  FAIL: %s\n", msg);                              \
            return 1;                                                          \
        }                                                                      \
    } while (0)

static int test_parse_and_xpath(void) {
    const char *xml =
        "<?xml version=\"1.0\"?>"
        "<root><a x=\"1\"/><a x=\"2\"/><b>hi</b></root>";

    xmlDocPtr doc = xmlReadMemory(xml, (int)strlen(xml), "in.xml", NULL, 0);
    CHECK(doc, "xmlReadMemory returned NULL");

    xmlXPathContextPtr ctx = xmlXPathNewContext(doc);
    CHECK(ctx, "xmlXPathNewContext returned NULL");

    xmlXPathObjectPtr res =
        xmlXPathEvalExpression((const xmlChar *)"//a", ctx);
    CHECK(res && res->nodesetval, "XPath //a returned no nodeset");
    CHECK(res->nodesetval->nodeNr == 2,
          "XPath //a expected 2 matches");

    xmlXPathFreeObject(res);
    xmlXPathFreeContext(ctx);
    xmlFreeDoc(doc);
    printf("  parse+xpath OK\n");
    return 0;
}

/*
 * Hard check: libxml2 is built with LIBXML2_WITH_ZLIB=ON, so xmlReadFile
 * on a .xml.gz path must transparently decompress. The .xml.gz fixture
 * is written on the fly to the in-process filesystem using zlib's own
 * gz* API, so this test has no external fixture dependency.
 *
 * libxml2 requires XML_PARSE_UNZIP for transparent decompression; without
 * it the gzip path in xmlIO.c is skipped even when LIBXML_ZLIB_ENABLED
 * is defined.
 */
static int test_gzipped_parse(void) {
    const char *path = "/tmp/test_libxml2.xml.gz";
    const char *payload =
        "<?xml version=\"1.0\"?><root><item>hi</item></root>\n";

    gzFile gz = gzopen(path, "wb");
    CHECK(gz, "gzopen for write failed");
    int payload_len = (int)strlen(payload);
    int written = gzwrite(gz, payload, (unsigned int)payload_len);
    CHECK(written == payload_len, "gzwrite short write");
    CHECK(gzclose(gz) == Z_OK, "gzclose failed");

    xmlDocPtr doc = xmlReadFile(path, NULL, XML_PARSE_UNZIP);
    CHECK(doc,
          "xmlReadFile on .xml.gz returned NULL — LIBXML2_WITH_ZLIB not "
          "wired up?");
    xmlNodePtr root = xmlDocGetRootElement(doc);
    CHECK(root && xmlStrEqual(root->name, (const xmlChar *)"root"),
          "gzipped doc root element mismatch");
    xmlNodePtr item = xmlFirstElementChild(root);
    CHECK(item && xmlStrEqual(item->name, (const xmlChar *)"item"),
          "gzipped doc <item> child mismatch");
    xmlChar *text = xmlNodeGetContent(item);
    CHECK(text && xmlStrEqual(text, (const xmlChar *)"hi"),
          "gzipped doc <item> text mismatch");
    xmlFree(text);
    xmlFreeDoc(doc);
    printf("  gzipped parse OK\n");
    return 0;
}

int main(void) {
    xmlInitParser();
    LIBXML_TEST_VERSION;

    int rc = 0;
    rc |= test_parse_and_xpath();
    rc |= test_gzipped_parse();

    xmlCleanupParser();
    return rc;
}
