import java.util.*;
import java.util.concurrent.*;
import java.lang.management.*;

/** Multi-threaded allocation churn with a live set, to exercise each collector. */
public class GcStress {
    public static void main(String[] args) throws Exception {
        int threads = 4, rounds = args.length > 0 ? Integer.parseInt(args[0]) : 60;
        ExecutorService pool = Executors.newFixedThreadPool(threads);
        List<Future<Long>> results = new ArrayList<>();
        for (int t = 0; t < threads; t++) {
            final int seed = t;
            results.add(pool.submit(() -> {
                Random r = new Random(seed);
                ArrayDeque<int[]> live = new ArrayDeque<>();
                Map<Integer, String> map = new HashMap<>();
                long sum = 0;
                for (int round = 0; round < rounds; round++) {
                    for (int i = 0; i < 2000; i++) {
                        int[] a = new int[16 + r.nextInt(512)];
                        a[0] = i; a[a.length - 1] = round;
                        live.add(a);
                        if (live.size() > 400) sum += live.poll()[0];
                        if ((i & 63) == 0) map.put(r.nextInt(5000), "v" + i + "-" + round);
                    }
                    sum += map.size();
                }
                return sum;
            }));
        }
        long total = 0;
        for (Future<Long> f : results) total += f.get();
        pool.shutdown();
        long collections = 0;
        for (GarbageCollectorMXBean b : ManagementFactory.getGarbageCollectorMXBeans())
            collections += Math.max(0, b.getCollectionCount());
        System.out.println("GcStress done total=" + total + " collections=" + collections);
    }
}
