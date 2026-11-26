import java.io.*;
import java.math.BigInteger;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.security.MessageDigest;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.regex.*;
import java.util.stream.*;
import java.util.zip.*;

public class Hello {
    static int failures = 0;
    static void check(String name, boolean ok) {
        System.out.println((ok ? "PASS " : "FAIL ") + name);
        if (!ok) failures++;
    }

    public static void main(String[] args) throws Exception {
        long t0 = System.nanoTime();
        System.out.println("Hello from Java " + System.getProperty("java.version")
            + " on " + System.getProperty("os.name") + "/" + System.getProperty("os.arch")
            + " (" + System.getProperty("java.vm.name") + ", " + System.getProperty("java.vm.info") + ")");
        System.out.println("GC: " + java.lang.management.ManagementFactory.getGarbageCollectorMXBeans()
            .stream().map(b -> b.getName()).collect(Collectors.joining(", ")));

        check("streams", IntStream.rangeClosed(1, 100).sum() == 5050);
        check("collections", new TreeMap<>(Map.of("b", 2, "a", 1)).firstKey().equals("a"));
        check("bigint", BigInteger.TWO.pow(200).toString().endsWith("301376"));
        check("regex", Pattern.compile("(\\w+)@(\\w+)\\.com").matcher("mail me: joe@example.com").find());
        check("format", String.format("%08.3f|%x|%s", Math.PI, 255, List.of(1, 2)).equals("0003.142|ff|[1, 2]"));

        MessageDigest md = MessageDigest.getInstance("SHA-256");
        byte[] h = md.digest("abc".getBytes(StandardCharsets.UTF_8));
        check("sha256", HexFormat.of().formatHex(h).startsWith("ba7816bf"));

        Path p = Files.createTempFile("hello", ".txt");
        Files.writeString(p, "line1\nline2\n");
        check("file io", Files.readAllLines(p).size() == 2);

        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        try (GZIPOutputStream gz = new GZIPOutputStream(bos)) { gz.write("x".repeat(10000).getBytes()); }
        byte[] back = new GZIPInputStream(new ByteArrayInputStream(bos.toByteArray())).readAllBytes();
        check("gzip", bos.size() < 200 && back.length == 10000);

        ExecutorService pool = Executors.newFixedThreadPool(4);
        List<Future<Long>> fs = new ArrayList<>();
        for (int i = 0; i < 8; i++) {
            final int n = i;
            fs.add(pool.submit(() -> LongStream.rangeClosed(1, 20000L * (n + 1)).sum()));
        }
        long total = 0;
        for (Future<Long> f : fs) total += f.get();
        pool.shutdown();
        check("threads", pool.awaitTermination(30, TimeUnit.SECONDS) && total > 0);

        CompletableFuture<String> cf = CompletableFuture.supplyAsync(() -> "async").thenApply(s -> s + "!");
        check("completable future", cf.get(30, TimeUnit.SECONDS).equals("async!"));

        check("time", LocalDate.of(2024, 2, 28).plusDays(1).getDayOfMonth() == 29
            && ZoneId.of("Europe/Paris").getRules().getOffset(Instant.parse("2024-07-01T00:00:00Z")).getTotalSeconds() == 7200);

        try { Object o = null; o.hashCode(); check("npe", false); }
        catch (NullPointerException e) { check("npe", e.getMessage() != null); }

        // allocation churn to exercise the collector
        List<int[]> keep = new ArrayList<>();
        for (int i = 0; i < 20000; i++) { int[] a = new int[256]; if (i % 100 == 0) keep.add(a); }
        System.gc();
        check("gc churn", keep.size() == 200);

        long iters = 0; long s = System.nanoTime();
        while (System.nanoTime() - s < 1_000_000_000L) { for (int i = 0; i < 1000; i++) iters += i & 1; }
        System.out.println("interpreter: ~" + (iters * 2 / 1_000_000) + "M loop iterations/s");

        System.out.printf("elapsed %.1f s, heap used %d MB%n", (System.nanoTime() - t0) / 1e9,
            (Runtime.getRuntime().totalMemory() - Runtime.getRuntime().freeMemory()) >> 20);
        System.out.println(failures == 0 ? "ALL TESTS PASSED" : failures + " TESTS FAILED");
        System.exit(failures == 0 ? 0 : 1);
    }
}
