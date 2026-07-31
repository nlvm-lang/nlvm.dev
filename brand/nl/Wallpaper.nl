namespace brand;

// Generates the NL desktop wallpapers as SVG, in NL, from the same geometry as
// brand/nl_logo.svg. Written for `rsvg-convert` output at 2560x1440 and up.
//
// Two self-imposed rules, both straight out of the brand guidelines:
//   - no arcs, ever: every shape is straight segments and chamfers;
//   - jade is the identity, amber is a flag - never both at the same weight.
//
// All arithmetic is integer. Scales are permille, opacities are percent; the
// helpers below turn them back into the decimals SVG wants. That is not just
// prudishness: it keeps the output byte-identical across runs.
class Wallpaper {
    private static int width() { return 2560; }
    private static int height() { return 1440; }

    private static string mono() { return "'IBM Plex Mono',ui-monospace,'JetBrains Mono',Menlo,Consolas,monospace"; }
    private static string sans() { return "'IBM Plex Sans',ui-sans-serif,system-ui,-apple-system,'Segoe UI',Roboto,Arial,sans-serif"; }

    private static string bg() { return "#0a0f0c"; }
    private static string jade() { return "#35c99b"; }
    private static string jadeBright() { return "#4ee0ac"; }
    private static string amber() { return "#e0a458"; }
    private static string border() { return "#263832"; }
    private static string text() { return "#e7eeea"; }
    private static string muted() { return "#93a69e"; }
    private static string faint() { return "#5f7370"; }

    private static string i(int n) {
        return system.Int.toString(n);
    }

    // percent -> SVG opacity literal
    private static string op(int pct) {
        if (pct >= 100) { return "1"; }
        if (pct <= 0) { return "0"; }
        if (pct < 10) { return "0.0" + Wallpaper.i(pct); }
        return "0." + Wallpaper.i(pct);
    }

    // permille -> decimal literal, e.g. 1900 -> "1.900"
    private static string dec3(int permille) {
        int whole = permille / 1000;
        int frac = permille % 1000;
        string f = Wallpaper.i(frac);
        while (f.length() < 3) {
            f = "0" + f;
        }
        return Wallpaper.i(whole) + "." + f;
    }

    private static int clamp(int v, int lo, int hi) {
        if (v < lo) { return lo; }
        if (v > hi) { return hi; }
        return v;
    }

    private static int abs(int v) {
        if (v < 0) { return 0 - v; }
        return v;
    }

    private static void head(system.io.FileHandle o, string title) throws IOException {
        int w = Wallpaper.width();
        int h = Wallpaper.height();
        o.write("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 " + Wallpaper.i(w) + " " + Wallpaper.i(h) + "\" width=\"" + Wallpaper.i(w) + "\" height=\"" + Wallpaper.i(h) + "\">\n");
        o.write("<title>" + title + "</title>\n");
        o.write("<rect width=\"" + Wallpaper.i(w) + "\" height=\"" + Wallpaper.i(h) + "\" fill=\"" + Wallpaper.bg() + "\"/>\n");
    }

    private static void tail(system.io.FileHandle o) throws IOException {
        o.write("</svg>\n");
    }

    private static void label(system.io.FileHandle o, int x, int y, string family, int size,
                              int weight, string fill, int alpha, int spacing, string anchor,
                              string content) throws IOException {
        o.write("<text x=\"" + Wallpaper.i(x) + "\" y=\"" + Wallpaper.i(y) + "\" font-family=\"" + family + "\"");
        o.write(" font-size=\"" + Wallpaper.i(size) + "\" font-weight=\"" + Wallpaper.i(weight) + "\"");
        o.write(" fill=\"" + fill + "\" fill-opacity=\"" + Wallpaper.op(alpha) + "\"");
        if (spacing != 0) {
            o.write(" letter-spacing=\"" + Wallpaper.i(spacing) + "\"");
        }
        if (anchor != "start") {
            o.write(" text-anchor=\"" + anchor + "\"");
        }
        o.write(">" + content + "</text>\n");
    }

    private static void line(system.io.FileHandle o, int x1, int y1, int x2, int y2,
                             string stroke, int alpha, int w) throws IOException {
        o.write("<path d=\"M" + Wallpaper.i(x1) + " " + Wallpaper.i(y1) + "L" + Wallpaper.i(x2) + " " + Wallpaper.i(y2) + "\" stroke=\"" + stroke + "\" stroke-opacity=\"" + Wallpaper.op(alpha) + "\" stroke-width=\"" + Wallpaper.i(w) + "\"/>\n");
    }

    // The mark, straight from nl_logo.svg. Ink box is x 138..382, y 106..386,
    // so its visual centre sits at (260, 246) in glyph space.
    private static void mark(system.io.FileHandle o, int cx, int cy, int k,
                             string color, int alpha, bool full) throws IOException {
        int tx = cx - (260 * k) / 1000;
        int ty = cy - (246 * k) / 1000;
        o.write("<g transform=\"translate(" + Wallpaper.i(tx) + " " + Wallpaper.i(ty) + ") scale(" + Wallpaper.dec3(k) + ")\" stroke=\"" + color + "\" stroke-opacity=\"" + Wallpaper.op(alpha) + "\">");
        if (full) {
            o.write("<path d=\"M160 364 V224 L196 190 L244 190 L280 224 V364\"/>");
        }
        o.write("<path d=\"M360 364 V128\"/></g>\n");
    }

    // Same geometry, but the stroke keeps a constant on-screen weight however
    // far the copy is scaled up: sw_glyph = 3000 / k, in permille.
    private static void ring(system.io.FileHandle o, int cx, int cy, int k,
                             string color, int alpha) throws IOException {
        int tx = cx - (260 * k) / 1000;
        int ty = cy - (246 * k) / 1000;
        o.write("<g transform=\"translate(" + Wallpaper.i(tx) + " " + Wallpaper.i(ty) + ") scale(" + Wallpaper.dec3(k) + ")\" stroke=\"" + color + "\" stroke-opacity=\"" + Wallpaper.op(alpha) + "\" stroke-width=\"" + Wallpaper.dec3(3000000 / k) + "\">");
        o.write("<path d=\"M160 364 V224 L196 190 L244 190 L280 224 V364\"/>");
        o.write("<path d=\"M360 364 V128\"/></g>\n");
    }

    private static void openMarks(system.io.FileHandle o) throws IOException {
        o.write("<g fill=\"none\" stroke-width=\"44\" stroke-linecap=\"square\" stroke-linejoin=\"miter\">\n");
    }

    private static void wordmark(system.io.FileHandle o, int x, int y, int size, int alpha) throws IOException {
        o.write("<text x=\"" + Wallpaper.i(x) + "\" y=\"" + Wallpaper.i(y) + "\" font-family=\"" + Wallpaper.mono() + "\" font-size=\"" + Wallpaper.i(size) + "\" font-weight=\"700\" text-anchor=\"end\" fill-opacity=\"" + Wallpaper.op(alpha) + "\">");
        o.write("<tspan fill=\"" + Wallpaper.text() + "\">nl</tspan><tspan fill=\"" + Wallpaper.faint() + "\">vm</tspan><tspan fill=\"" + Wallpaper.jade() + "\">_</tspan></text>\n");
    }

    // ---------------------------------------------------------------- A ----
    // "Nihil latet". A field of marks lit by a single off-centre source. The
    // ones far from the light never drop to zero: nothing is hidden, you just
    // have to look. One amber mark sits alone in the dark half.
    public static void conceptField(string path) throws IOException {
        auto o = system.io.File.open(path, system.io.FileMode.ReadWriteTruncate);
        Wallpaper.head(o, "NL - nihil latet");

        auto rng = new Rng(20260731);

        Wallpaper.openMarks(o);
        // A strict typographic grid, lit by a diagonal band. No jitter: the
        // order is the point. Brightness alone carries the image, and nothing
        // ever falls to zero.
        int step = 96;
        for (int y = 48; y < 1440; y = y + step) {
            for (int x = 48; x < 2560; x = x + step) {
                int band = Wallpaper.abs((x + y) - 2040);
                int lum = 98 - band / 12;
                lum = lum + rng.range(-16, 10);
                lum = Wallpaper.clamp(lum, 3, 92);
                // keep the caption block readable: the grid steps back there
                if (x < 780 && y > 1130) {
                    lum = Wallpaper.clamp(lum / 5, 2, 9);
                }
                Wallpaper.mark(o, x, y, 108, Wallpaper.jade(), lum, true);
            }
        }
        // Six flagged arms, scattered. They are not hiding; you just have to
        // look at the types.
        Wallpaper.mark(o, 48 + step * 4, 48 + step * 2, 108, Wallpaper.amber(), 58, true);
        Wallpaper.mark(o, 48 + step * 19, 48 + step * 3, 108, Wallpaper.amber(), 70, true);
        Wallpaper.mark(o, 48 + step * 8, 48 + step * 7, 108, Wallpaper.amber(), 76, true);
        Wallpaper.mark(o, 48 + step * 23, 48 + step * 9, 108, Wallpaper.amber(), 62, true);
        Wallpaper.mark(o, 48 + step * 14, 48 + step * 11, 108, Wallpaper.amber(), 66, true);
        Wallpaper.mark(o, 48 + step * 2, 48 + step * 13, 108, Wallpaper.amber(), 52, true);
        o.write("</g>\n");

        Wallpaper.label(o, 180, 1232, Wallpaper.mono(), 46, 700, Wallpaper.jade(), 92, 14, "start", "nihil latet");
        Wallpaper.label(o, 182, 1288, Wallpaper.sans(), 26, 400, Wallpaper.faint(), 90, 0, "start", "nothing is hidden &#8212; it is in the types");
        Wallpaper.wordmark(o, 2380, 1290, 42, 55);

        Wallpaper.tail(o);
        o.close();
        system.Out.println("wrote " + path);
    }

    // ---------------------------------------------------------------- B ----
    // "Sheet 01". The mark as a drawing-office construction sheet: grid,
    // extension lines, dimensions, vertex ticks, title block. The left third
    // stays empty for desktop icons.
    public static void conceptBlueprint(string path) throws IOException {
        auto o = system.io.File.open(path, system.io.FileMode.ReadWriteTruncate);
        Wallpaper.head(o, "NL - mark construction, sheet 01");

        for (int x = 0; x <= 2560; x = x + 40) {
            int a = 13;
            if (x % 200 == 0) { a = 32; }
            Wallpaper.line(o, x, 0, x, 1440, Wallpaper.border(), a, 1);
        }
        for (int y = 0; y <= 1440; y = y + 40) {
            int a = 13;
            if (y % 200 == 0) { a = 32; }
            Wallpaper.line(o, 0, y, 2560, y, Wallpaper.border(), a, 1);
        }

        int k = 1900;
        int ox = 1660 - (260 * k) / 1000;
        int oy = 700 - (246 * k) / 1000;

        // glyph-space -> canvas
        int inkL = ox + (138 * k) / 1000;
        int inkR = ox + (382 * k) / 1000;
        int inkT = oy + (106 * k) / 1000;
        int inkB = oy + (386 * k) / 1000;

        // construction envelope
        o.write("<path d=\"M" + Wallpaper.i(inkL) + " " + Wallpaper.i(inkT) + "H" + Wallpaper.i(inkR) + "V" + Wallpaper.i(inkB) + "H" + Wallpaper.i(inkL) + "Z\" fill=\"none\" stroke=\"" + Wallpaper.jade() + "\" stroke-opacity=\"0.22\" stroke-width=\"2\" stroke-dasharray=\"14 10\"/>\n");

        Wallpaper.openMarks(o);
        Wallpaper.mark(o, 1660, 700, k, Wallpaper.jade(), 100, true);
        o.write("</g>\n");

        // vertex ticks on every node of the two paths
        int[] vx = new int[]{160, 160, 196, 244, 280, 280, 360, 360};
        int[] vy = new int[]{364, 224, 190, 190, 224, 364, 364, 128};
        for (int n = 0; n < vx.length(); n++) {
            int px = ox + (vx[n] * k) / 1000;
            int py = oy + (vy[n] * k) / 1000;
            o.write("<rect x=\"" + Wallpaper.i(px - 9) + "\" y=\"" + Wallpaper.i(py - 9) + "\" width=\"18\" height=\"18\" fill=\"none\" stroke=\"" + Wallpaper.text() + "\" stroke-opacity=\"0.6\" stroke-width=\"2\"/>\n");
        }

        // two coordinates, called out where they stay off the ink
        Wallpaper.label(o, ox + (160 * k) / 1000 - 54, oy + (364 * k) / 1000 + 6, Wallpaper.mono(), 18, 400, Wallpaper.muted(), 70, 1, "end", "160,364");
        Wallpaper.label(o, ox + (360 * k) / 1000 + 54, oy + (128 * k) / 1000 + 6, Wallpaper.mono(), 18, 400, Wallpaper.muted(), 70, 1, "start", "360,128");
        Wallpaper.label(o, ox + (244 * k) / 1000 + 26, oy + (190 * k) / 1000 - 58, Wallpaper.mono(), 18, 400, Wallpaper.muted(), 70, 1, "start", "244,190");

        // horizontal dimension under the mark
        int dimY = inkB + 96;
        Wallpaper.line(o, inkL, inkB + 20, inkL, dimY + 22, Wallpaper.border(), 70, 1);
        Wallpaper.line(o, inkR, inkB + 20, inkR, dimY + 22, Wallpaper.border(), 70, 1);
        Wallpaper.line(o, inkL, dimY, inkR, dimY, Wallpaper.muted(), 45, 1);
        Wallpaper.line(o, inkL, dimY - 9, inkL, dimY + 9, Wallpaper.muted(), 60, 2);
        Wallpaper.line(o, inkR, dimY - 9, inkR, dimY + 9, Wallpaper.muted(), 60, 2);
        o.write("<rect x=\"" + Wallpaper.i((inkL + inkR) / 2 - 46) + "\" y=\"" + Wallpaper.i(dimY - 16) + "\" width=\"92\" height=\"32\" fill=\"" + Wallpaper.bg() + "\"/>\n");
        Wallpaper.label(o, (inkL + inkR) / 2, dimY + 8, Wallpaper.mono(), 22, 500, Wallpaper.muted(), 85, 2, "middle", "244");

        // vertical dimension on the left
        int dimX = inkL - 104;
        Wallpaper.line(o, inkL - 20, inkT, dimX - 22, inkT, Wallpaper.border(), 70, 1);
        Wallpaper.line(o, inkL - 20, inkB, dimX - 22, inkB, Wallpaper.border(), 70, 1);
        Wallpaper.line(o, dimX, inkT, dimX, inkB, Wallpaper.muted(), 45, 1);
        Wallpaper.line(o, dimX - 9, inkT, dimX + 9, inkT, Wallpaper.muted(), 60, 2);
        Wallpaper.line(o, dimX - 9, inkB, dimX + 9, inkB, Wallpaper.muted(), 60, 2);
        o.write("<rect x=\"" + Wallpaper.i(dimX - 26) + "\" y=\"" + Wallpaper.i((inkT + inkB) / 2 - 18) + "\" width=\"52\" height=\"36\" fill=\"" + Wallpaper.bg() + "\"/>\n");
        Wallpaper.label(o, dimX, (inkT + inkB) / 2 + 8, Wallpaper.mono(), 22, 500, Wallpaper.muted(), 85, 2, "middle", "280");

        // stroke-width dimension across the vertical stem
        int stemL = ox + (338 * k) / 1000;
        int stemR = ox + (382 * k) / 1000;
        int stemY = inkT - 54;
        Wallpaper.line(o, stemL, inkT - 12, stemL, stemY - 14, Wallpaper.border(), 70, 1);
        Wallpaper.line(o, stemR, inkT - 12, stemR, stemY - 14, Wallpaper.border(), 70, 1);
        Wallpaper.line(o, stemL - 26, stemY, stemR + 26, stemY, Wallpaper.muted(), 45, 1);
        Wallpaper.line(o, stemL, stemY - 8, stemL, stemY + 8, Wallpaper.muted(), 60, 2);
        Wallpaper.line(o, stemR, stemY - 8, stemR, stemY + 8, Wallpaper.muted(), 60, 2);
        Wallpaper.label(o, stemR + 42, stemY + 7, Wallpaper.mono(), 22, 500, Wallpaper.jade(), 85, 2, "start", "44");

        // chamfer callout - the one angled cut in the whole identity
        int chx = ox + (178 * k) / 1000;
        int chy = oy + (207 * k) / 1000;
        Wallpaper.line(o, chx, chy, chx - 190, chy - 150, Wallpaper.jade(), 55, 1);
        Wallpaper.line(o, chx - 190, chy - 150, chx - 420, chy - 150, Wallpaper.jade(), 55, 1);
        o.write("<rect x=\"" + Wallpaper.i(chx - 15) + "\" y=\"" + Wallpaper.i(chy - 15) + "\" width=\"30\" height=\"30\" fill=\"none\" stroke=\"" + Wallpaper.jade() + "\" stroke-opacity=\"0.75\" stroke-width=\"2\"/>\n");
        Wallpaper.label(o, chx - 200, chy - 168, Wallpaper.mono(), 21, 500, Wallpaper.jade(), 90, 3, "end", "CHAMFER 45&#176;");
        Wallpaper.label(o, chx - 200, chy - 138, Wallpaper.mono(), 19, 400, Wallpaper.muted(), 75, 1, "end", "the only cut in the identity. no arcs.");

        // left column - the sheet notes
        Wallpaper.label(o, 200, 300, Wallpaper.mono(), 20, 500, Wallpaper.jade(), 90, 8, "start", "01 &#183; MARK CONSTRUCTION");
        Wallpaper.label(o, 200, 380, Wallpaper.sans(), 52, 600, Wallpaper.text(), 96, 0, "start", "Straight lines,");
        Wallpaper.label(o, 200, 442, Wallpaper.sans(), 52, 600, Wallpaper.text(), 96, 0, "start", "one chamfer,");
        Wallpaper.label(o, 200, 504, Wallpaper.sans(), 52, 600, Wallpaper.jade(), 96, 0, "start", "nothing hidden.");
        Wallpaper.label(o, 202, 576, Wallpaper.sans(), 24, 400, Wallpaper.muted(), 90, 0, "start", "Null safety, checked exceptions, exhaustive matching.");

        // title block
        int tbx = 1780;
        int tby = 1128;
        o.write("<rect x=\"" + Wallpaper.i(tbx) + "\" y=\"" + Wallpaper.i(tby) + "\" width=\"580\" height=\"192\" fill=\"" + Wallpaper.bg() + "\" fill-opacity=\"0.9\" stroke=\"" + Wallpaper.border() + "\" stroke-width=\"2\"/>\n");
        Wallpaper.line(o, tbx, tby + 52, tbx + 580, tby + 52, Wallpaper.border(), 100, 2);
        Wallpaper.label(o, tbx + 24, tby + 34, Wallpaper.mono(), 22, 700, Wallpaper.text(), 95, 6, "start", "NL &#183; THE MARK");
        Wallpaper.label(o, tbx + 556, tby + 34, Wallpaper.mono(), 18, 400, Wallpaper.jade(), 85, 2, "end", "SHEET 01/01");
        Wallpaper.label(o, tbx + 24, tby + 90, Wallpaper.mono(), 18, 400, Wallpaper.muted(), 80, 1, "start", "STROKE 44 &#183; MITER &#183; SQUARE CAP");
        Wallpaper.label(o, tbx + 24, tby + 122, Wallpaper.mono(), 18, 400, Wallpaper.muted(), 80, 1, "start", "JADE #35C99B ON #0A0F0C");
        Wallpaper.label(o, tbx + 24, tby + 154, Wallpaper.mono(), 18, 400, Wallpaper.muted(), 80, 1, "start", "SCALE 1:1 &#183; 2560 x 1440");
        Wallpaper.wordmark(o, tbx + 556, tby + 158, 34, 90);

        // registration marks
        Wallpaper.line(o, 80, 80, 140, 80, Wallpaper.border(), 90, 2);
        Wallpaper.line(o, 80, 80, 80, 140, Wallpaper.border(), 90, 2);
        Wallpaper.line(o, 2480, 80, 2420, 80, Wallpaper.border(), 90, 2);
        Wallpaper.line(o, 2480, 80, 2480, 140, Wallpaper.border(), 90, 2);
        Wallpaper.line(o, 80, 1360, 140, 1360, Wallpaper.border(), 90, 2);
        Wallpaper.line(o, 80, 1360, 80, 1300, Wallpaper.border(), 90, 2);

        Wallpaper.tail(o);
        o.close();
        system.Out.println("wrote " + path);
    }

    // ---------------------------------------------------------------- C ----
    // "Echo". The mark, propagated. Concentric copies of the exact same two
    // paths, scaled about the ink centre, each keeping a constant on-screen
    // stroke weight. No arcs anywhere: the ripples are as faceted as the mark.
    public static void conceptEcho(string path) throws IOException {
        auto o = system.io.File.open(path, system.io.FileMode.ReadWriteTruncate);
        Wallpaper.head(o, "NL - the mark, propagated");

        int cx = 1560;
        int cy = 660;

        o.write("<g fill=\"none\" stroke-linecap=\"square\" stroke-linejoin=\"miter\">\n");
        int n = 0;
        for (int k = 1240; k < 9600; k = k + 176) {
            int a = Wallpaper.clamp(52 - (k - 1240) / 168, 5, 52);
            if (n % 6 == 0) {
                a = a + 16;
            }
            string c = Wallpaper.jade();
            if (n == 13) {
                c = Wallpaper.amber();
                a = 60;
            }
            Wallpaper.ring(o, cx, cy, k, c, a);
            n = n + 1;
        }
        o.write("</g>\n");

        // the source of the echo, at full weight
        Wallpaper.openMarks(o);
        Wallpaper.mark(o, cx, cy, 900, Wallpaper.jade(), 100, true);
        o.write("</g>\n");

        Wallpaper.label(o, 180, 1176, Wallpaper.mono(), 20, 500, Wallpaper.jade(), 90, 8, "start", "03 &#183; ONE BINARY, ONE FILE");
        Wallpaper.label(o, 180, 1250, Wallpaper.sans(), 54, 600, Wallpaper.text(), 96, 0, "start", "It compiles to one file, and it runs.");
        Wallpaper.label(o, 182, 1298, Wallpaper.sans(), 25, 400, Wallpaper.muted(), 88, 0, "start", "nlc emits a single .nlp. nlvm runs it with zero runtime dependencies.");
        Wallpaper.wordmark(o, 2380, 1298, 42, 70);

        Wallpaper.tail(o);
        o.close();
        system.Out.println("wrote " + path);
    }

    public static int run() throws IOException {
        if (!system.io.Directory.exists("brand/generated")) {
            system.io.Directory.create("brand/generated");
        }
        Wallpaper.conceptField("brand/generated/wallpaper-a-field.svg");
        Wallpaper.conceptBlueprint("brand/generated/wallpaper-b-sheet.svg");
        Wallpaper.conceptEcho("brand/generated/wallpaper-c-echo.svg");
        return 0;
    }

    public static int main(string[] args) {
        try {
            return Wallpaper.run();
        } catch (IOException ex) {
            system.Err.println("Error: " + ex.message);
            return 1;
        }
    }
}
