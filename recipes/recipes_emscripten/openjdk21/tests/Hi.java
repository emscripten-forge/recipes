import java.util.stream.*;
public class Hi {
    record Point(int x, int y) {}
    public static void main(String[] args) {
        var pts = IntStream.range(0, 5).mapToObj(i -> new Point(i, i * i)).toList();
        System.out.println("compiled in wasm: " + pts.get(4) + " args=" + String.join(",", args));
    }
}
