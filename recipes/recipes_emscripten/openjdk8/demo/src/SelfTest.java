import java.awt.Color;
import java.awt.Font;
import java.awt.GradientPaint;
import java.awt.Graphics2D;
import java.awt.GraphicsEnvironment;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.*;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.text.*;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.regex.*;
import java.util.stream.*;
import java.util.zip.*;
import javax.crypto.Cipher;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import javax.imageio.ImageIO;
import javax.sound.sampled.*;

/**
 * Self test of the WebAssembly OpenJDK runtime: exercises the VM and the
 * main class library areas.  Prints one line per check and
 * "SELFTEST PASSED n/n"; exits with status 1 if a check fails.
 * Optional arguments: "nashorn" also runs the JavaScript engine.
 */
public class SelfTest {
    interface Check { String run() throws Exception; }

    static int passed, failed;

    static void check(String name, Check c) {
        long t0 = System.nanoTime();
        try {
            String detail = c.run();
            passed++;
            System.out.printf("ok    %-14s %5d ms  %s%n", name, (System.nanoTime() - t0) / 1000000, detail);
        } catch (Throwable t) {
            failed++;
            System.out.printf("FAIL  %-14s %s%n", name, t);
            t.printStackTrace(System.out);
        }
    }

    static void expect(boolean cond, String what) {
        if (!cond) throw new AssertionError(what);
    }

    static String hex(byte[] b) {
        StringBuilder sb = new StringBuilder();
        for (byte x : b) sb.append(String.format("%02x", x));
        return sb.toString();
    }

    public static void main(String[] args) throws Exception {
        boolean nashorn = Arrays.asList(args).contains("nashorn");

        check("properties", () -> {
            String v = System.getProperty("java.version");
            expect(v.startsWith("1.8.0"), "java.version " + v);
            expect("Linux".equals(System.getProperty("os.name")), "os.name");
            return "java " + v + ", " + System.getProperty("java.vm.name") + ", arch "
                    + System.getProperty("os.arch") + ", cpus " + Runtime.getRuntime().availableProcessors();
        });

        check("threads", () -> {
            final AtomicInteger counter = new AtomicInteger();
            final int[] plain = new int[1];
            final Object lock = new Object();
            Thread[] ts = new Thread[6];
            for (int i = 0; i < ts.length; i++) {
                ts[i] = new Thread(() -> {
                    for (int k = 0; k < 2000; k++) {
                        counter.incrementAndGet();
                        synchronized (lock) { plain[0]++; }
                        if (k % 500 == 0) Thread.yield();
                    }
                });
                ts[i].start();
            }
            for (Thread t : ts) t.join();
            expect(counter.get() == 12000 && plain[0] == 12000, "counts " + counter + " " + plain[0]);
            BlockingQueue<Integer> q = new ArrayBlockingQueue<>(4);
            Thread producer = new Thread(() -> {
                try { for (int i = 1; i <= 100; i++) q.put(i); q.put(-1); } catch (InterruptedException e) { }
            });
            producer.start();
            int sum = 0;
            for (int x; (x = q.take()) != -1; ) sum += x;
            expect(sum == 5050, "queue sum " + sum);
            ExecutorService pool = Executors.newFixedThreadPool(3);
            List<Future<Long>> fs = new ArrayList<>();
            for (int i = 0; i < 6; i++) {
                final long n = 1000 * (i + 1);
                fs.add(pool.submit(() -> LongStream.rangeClosed(1, n).sum()));
            }
            long total = 0;
            for (Future<Long> f : fs) total += f.get();
            pool.shutdown();
            expect(pool.awaitTermination(10, TimeUnit.SECONDS), "pool termination");
            long t0 = System.currentTimeMillis();
            Thread.sleep(50);
            long slept = System.currentTimeMillis() - t0;
            expect(slept >= 45, "sleep " + slept);
            return "12000 increments, queue 5050, pool " + total + ", sleep " + slept + " ms";
        });

        check("collections", () -> {
            List<String> words = Arrays.asList("pear", "apple", "fig", "banana", "cherry", "date");
            String joined = words.stream().filter(w -> w.length() > 3).sorted().map(String::toUpperCase)
                    .collect(Collectors.joining(","));
            expect("APPLE,BANANA,CHERRY,DATE,PEAR".equals(joined), joined);
            Map<Integer, Long> byLen = words.stream().collect(Collectors.groupingBy(String::length, TreeMap::new, Collectors.counting()));
            int psum = IntStream.range(0, 100000).parallel().filter(i -> i % 7 == 0).sum();
            expect(psum == 714264285, "parallel sum " + psum);
            return joined + " " + byLen;
        });

        check("text", () -> {
            String f = String.format(Locale.US, "%08.3f|%-5s|%x|%,d", Math.PI, "ab", 255, 1234567);
            expect("0003.142|ab   |ff|1,234,567".equals(f), f);
            Matcher m = Pattern.compile("(\\w+)@(\\w+)\\.org").matcher("mail duke@openjdk.org now");
            expect(m.find() && m.group(2).equals("openjdk"), "regex");
            String d = new SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.US) {{ setTimeZone(TimeZone.getTimeZone("UTC")); }}
                    .format(new Date(0));
            expect("1970-01-01 00:00".equals(d), d);
            String n = NumberFormat.getCurrencyInstance(Locale.GERMANY).format(1234.5);
            expect(n.contains("1.234,50"), n);
            Collator c = Collator.getInstance(Locale.FRENCH);
            expect(c.compare("\u00e9t\u00e9", "etre") < 0, "collator");
            return f + " " + n;
        });

        check("math", () -> {
            BigInteger fact = BigInteger.ONE;
            for (int i = 2; i <= 100; i++) fact = fact.multiply(BigInteger.valueOf(i));
            expect(fact.toString().length() == 158, "100! digits");
            BigInteger p = BigInteger.probablePrime(256, new Random(42));
            expect(p.isProbablePrime(50), "prime");
            BigDecimal pi = new BigDecimal("3.14159265358979323846").setScale(10, BigDecimal.ROUND_HALF_EVEN);
            expect(Math.abs(Math.sin(Math.PI / 6) - 0.5) < 1e-12 && Math.pow(2, 0.5) == Math.sqrt(2), "fp");
            expect(Double.toString(0.1 + 0.2).equals("0.30000000000000004"), "double printing");
            expect(Float.parseFloat("1.5e10") == 1.5e10f && Long.MAX_VALUE / 3 == 3074457345618258602L, "parse/long");
            return "100! has 158 digits, " + pi + ", strictfp " + StrictMath.cbrt(27.0);
        });

        check("strings", () -> {
            String s = "h\u00e9llo w\u00f6rld \u65e5\u672c \ud83d\ude00";
            byte[] u8 = s.getBytes(StandardCharsets.UTF_8);
            expect(new String(u8, StandardCharsets.UTF_8).equals(s), "utf-8 round trip");
            Charset sjis = Charset.forName("Shift_JIS");
            byte[] j = "\u65e5\u672c".getBytes(sjis);
            expect(j.length == 4 && new String(j, sjis).equals("\u65e5\u672c"), "Shift_JIS");
            String inter = new StringBuilder("dyn").append("amic").toString().intern();
            expect(inter == "dynamic", "intern");
            return u8.length + " UTF-8 bytes, " + Charset.availableCharsets().size() + " charsets";
        });

        check("zip", () -> {
            byte[] data = new byte[200000];
            for (int i = 0; i < data.length; i++) data[i] = (byte) ((i * 31) ^ (i >> 7));
            ByteArrayOutputStream bos = new ByteArrayOutputStream();
            try (GZIPOutputStream gz = new GZIPOutputStream(bos)) { gz.write(data); }
            byte[] comp = bos.toByteArray();
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            try (GZIPInputStream in = new GZIPInputStream(new ByteArrayInputStream(comp))) {
                byte[] buf = new byte[8192];
                for (int n; (n = in.read(buf)) > 0; ) out.write(buf, 0, n);
            }
            expect(Arrays.equals(data, out.toByteArray()), "gzip round trip");
            CRC32 crc = new CRC32();
            crc.update("123456789".getBytes("US-ASCII"));
            expect(crc.getValue() == 0xCBF43926L, "crc32");
            ByteArrayOutputStream zb = new ByteArrayOutputStream();
            try (ZipOutputStream zo = new ZipOutputStream(zb)) {
                zo.putNextEntry(new ZipEntry("a/b.txt"));
                zo.write("zip entry".getBytes("UTF-8"));
                zo.closeEntry();
            }
            try (ZipInputStream zi = new ZipInputStream(new ByteArrayInputStream(zb.toByteArray()))) {
                ZipEntry e = zi.getNextEntry();
                expect(e != null && e.getName().equals("a/b.txt"), "zip entry");
            }
            return data.length + " -> " + comp.length + " bytes";
        });

        check("files", () -> {
            Path dir = Files.createTempDirectory("selftest");
            Path f = dir.resolve("lines.txt");
            Files.write(f, Arrays.asList("one", "two", "three"), StandardCharsets.UTF_8);
            expect(Files.readAllLines(f).size() == 3 && Files.size(f) == 14, "readAllLines");
            try (FileChannel ch = FileChannel.open(dir.resolve("chan.bin"), StandardOpenOption.CREATE,
                    StandardOpenOption.READ, StandardOpenOption.WRITE)) {
                ByteBuffer bb = ByteBuffer.allocateDirect(1024);
                for (int i = 0; i < 256; i++) bb.putInt(i);
                bb.flip();
                ch.write(bb);
                bb.clear();
                ch.read(bb, 0);
                bb.flip();
                expect(bb.getInt(255 * 4) == 255 && ch.size() == 1024, "FileChannel");
            }
            try (RandomAccessFile raf = new RandomAccessFile(f.toFile(), "r")) {
                raf.seek(4);
                expect(raf.readLine().equals("two"), "RandomAccessFile");
            }
            long n;
            try (Stream<Path> s = Files.list(dir)) { n = s.count(); }
            Files.walk(dir).sorted(Comparator.reverseOrder()).forEach(p -> p.toFile().delete());
            expect(!Files.exists(dir), "delete");
            return n + " files in " + dir.getParent() + ", cwd " + new File(".").getCanonicalPath();
        });

        check("time", () -> {
            LocalDate d = LocalDate.of(2024, 2, 28).plusDays(1);
            expect(d.getDayOfMonth() == 29, "leap day");
            ZonedDateTime z = ZonedDateTime.of(2026, 3, 29, 12, 0, 0, 0, ZoneId.of("Europe/Berlin"));
            expect(z.getOffset().getTotalSeconds() == 7200, "DST offset " + z.getOffset());
            Duration du = Duration.between(Instant.EPOCH, Instant.parse("1970-01-02T00:00:00Z"));
            expect(du.toHours() == 24, "duration");
            return d + ", " + z.getOffset() + ", now " + Instant.now().toString().substring(0, 10)
                    + " " + ZoneId.systemDefault();
        });

        check("crypto", () -> {
            String sha = hex(MessageDigest.getInstance("SHA-256").digest("abc".getBytes("US-ASCII")));
            expect(sha.equals("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"), sha);
            byte[] key = new byte[16], iv = new byte[16];
            SecureRandom rnd = new SecureRandom();
            rnd.nextBytes(key);
            rnd.nextBytes(iv);
            Cipher c = Cipher.getInstance("AES/CBC/PKCS5Padding");
            c.init(Cipher.ENCRYPT_MODE, new SecretKeySpec(key, "AES"), new IvParameterSpec(iv));
            byte[] enc = c.doFinal("attack at dawn".getBytes("UTF-8"));
            c.init(Cipher.DECRYPT_MODE, new SecretKeySpec(key, "AES"), new IvParameterSpec(iv));
            expect(new String(c.doFinal(enc), "UTF-8").equals("attack at dawn"), "AES");
            return "SHA-256 ok, AES/CBC ok, " + java.security.Security.getProviders().length + " providers";
        });

        check("serialization", () -> {
            ByteArrayOutputStream bos = new ByteArrayOutputStream();
            HashMap<String, Object> m = new HashMap<>();
            m.put("list", new ArrayList<>(Arrays.asList(1, 2, 3)));
            m.put("date", LocalDate.of(2000, 1, 1));
            try (ObjectOutputStream oos = new ObjectOutputStream(bos)) { oos.writeObject(m); }
            Object back = new ObjectInputStream(new ByteArrayInputStream(bos.toByteArray())).readObject();
            expect(m.equals(back), "round trip");
            java.lang.reflect.Method meth = String.class.getMethod("concat", String.class);
            expect("ab".equals(meth.invoke("a", "b")), "reflection");
            Runnable proxy = (Runnable) java.lang.reflect.Proxy.newProxyInstance(SelfTest.class.getClassLoader(),
                    new Class<?>[] { Runnable.class }, (p, mm, a) -> null);
            proxy.run();
            return bos.size() + " bytes, reflection and dynamic proxy ok";
        });

        check("gc", () -> {
            List<byte[]> keep = new ArrayList<>();
            long allocated = 0;
            for (int i = 0; i < 400; i++) {
                byte[] b = new byte[256 * 1024];
                allocated += b.length;
                if (i % 40 == 0) keep.add(b);
            }
            java.lang.ref.WeakReference<Object> weak = new java.lang.ref.WeakReference<>(new Object());
            System.gc();
            Runtime rt = Runtime.getRuntime();
            return (allocated >> 20) + " MB allocated, heap " + (rt.totalMemory() >> 20) + "/"
                    + (rt.maxMemory() >> 20) + " MB, weak ref " + (weak.get() == null ? "cleared" : "kept");
        });

        check("java2d", () -> {
            BufferedImage img = new BufferedImage(160, 60, BufferedImage.TYPE_INT_RGB);
            Graphics2D g = img.createGraphics();
            g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            g.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_ON);
            g.setColor(Color.WHITE);
            g.fillRect(0, 0, 160, 60);
            g.setPaint(new GradientPaint(0, 0, Color.RED, 160, 0, Color.BLUE));
            g.fillOval(100, 5, 50, 50);
            g.setColor(Color.BLACK);
            Font font = new Font("SansSerif", Font.BOLD, 20);
            g.setFont(font);
            g.drawString("Java 8", 8, 38);
            int textWidth = g.getFontMetrics().stringWidth("Java 8");
            g.dispose();
            int dark = 0;
            for (int y = 0; y < 60; y++)
                for (int x = 0; x < 100; x++)
                    if ((img.getRGB(x, y) & 0xff) < 128) dark++;
            expect(dark > 100, "text pixels " + dark);
            expect(textWidth > 40, "text width " + textWidth);
            ByteArrayOutputStream png = new ByteArrayOutputStream();
            expect(ImageIO.write(img, "png", png), "png writer");
            BufferedImage back = ImageIO.read(new ByteArrayInputStream(png.toByteArray()));
            expect(back.getRGB(125, 30) == img.getRGB(125, 30), "png round trip");
            String[] fams = GraphicsEnvironment.getLocalGraphicsEnvironment().getAvailableFontFamilyNames();
            return "font " + font.getFontName() + ", " + dark + " text pixels, PNG " + png.size()
                    + " bytes, " + fams.length + " font families, headless " + GraphicsEnvironment.isHeadless();
        });

        check("sound", () -> {
            Mixer.Info[] mixers = AudioSystem.getMixerInfo();
            AudioFormat fmt = new AudioFormat(8000f, 16, 1, true, false);
            SourceDataLine line = AudioSystem.getSourceDataLine(fmt);
            line.open(fmt, 4000);
            line.start();
            byte[] tone = new byte[3200];   // 200 ms
            for (int i = 0; i < 1600; i++) {
                short v = (short) (Math.sin(2 * Math.PI * 440 * i / 8000.0) * 8000);
                tone[2 * i] = (byte) v;
                tone[2 * i + 1] = (byte) (v >> 8);
            }
            long t0 = System.currentTimeMillis();
            line.write(tone, 0, tone.length);
            line.drain();
            long frames = line.getLongFramePosition(), dt = System.currentTimeMillis() - t0;
            line.close();
            expect(frames == 1600, "frames " + frames);
            return mixers.length + " mixer(s): " + mixers[0].getName() + ", 1600 frames in " + dt + " ms";
        });

        check("urls", () -> {
            File tmp = File.createTempFile("url", ".txt");
            Files.write(tmp.toPath(), "via file: URL".getBytes("UTF-8"));
            try (BufferedReader r = new BufferedReader(new InputStreamReader(tmp.toURI().toURL().openStream(), "UTF-8"))) {
                expect(r.readLine().equals("via file: URL"), "file URL");
            }
            tmp.delete();
            java.net.URL res = Object.class.getResource("/java/lang/Object.class");
            expect(res != null && res.getProtocol().equals("jar"), "jar URL " + res);
            try (InputStream in = res.openStream()) {
                byte[] magic = new byte[4];
                expect(in.read(magic) == 4 && (magic[0] & 0xff) == 0xca, "class file magic");
            }
            java.net.URI u = new java.net.URI("http://example.org/a/../b?q=1#f").normalize();
            return "file: and jar: URLs ok, " + u;
        });

        if (nashorn) {
            check("nashorn", () -> {
                javax.script.ScriptEngine js = new javax.script.ScriptEngineManager().getEngineByName("nashorn");
                Object r = js.eval("[1,2,3].map(function(x){return x*x}).join('+') + '=' + (1+4+9)");
                expect("1+4+9=14".equals(r), String.valueOf(r));
                return String.valueOf(r);
            });
        }

        System.out.println((failed == 0 ? "SELFTEST PASSED " : "SELFTEST FAILED ") + passed + "/" + (passed + failed));
        System.exit(failed == 0 ? 0 : 1);
    }
}
