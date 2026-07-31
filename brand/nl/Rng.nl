namespace brand;

// Deterministic LCG. The wallpapers are generative but must be reproducible:
// same seed, same file, byte for byte. Constants are the glibc ones; the
// modulus keeps every intermediate well inside 64-bit range.
class Rng {
    private int state;

    public construct(int seed) {
        this.state = seed;
    }

    public int next() {
        this.state = (this.state * 1103515245 + 12345) % 2147483648;
        return this.state;
    }

    // Inclusive on both ends. The high bits of an LCG are the good ones, so
    // shift the low noise out before folding into the range.
    public int range(int lo, int hi) {
        int span = hi - lo + 1;
        int v = this.next() / 65536;
        if (v < 0) {
            v = 0 - v;
        }
        return lo + v % span;
    }
}
