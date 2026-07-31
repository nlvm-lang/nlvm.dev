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

    // glyph space (the logo's 512 tile) -> canvas, given the tile origin on
    // that axis and the scale in permille
    private static int g(int origin, int v, int k) {
        return origin + (v * k) / 1000;
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
    // "Sheet 01". The mark as a drawing-office construction sheet. Every
    // number on it is a real number from the identity: the 512 tile the logo
    // is drawn in, the 244x280 ink box, the 44 stroke, the 61-unit clearspace.
    // The left third stays empty for desktop icons, and the title block sits
    // flush in the bottom-right corner of the sheet margin.
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
        int ox = 1220;
        int oy = 120;
        int tile = (512 * k) / 1000;
        int margin = 80;

        int inkL = Wallpaper.g(ox, 138, k);
        int inkR = Wallpaper.g(ox, 382, k);
        int inkT = Wallpaper.g(oy, 106, k);
        int inkB = Wallpaper.g(oy, 386, k);
        // clearspace is a quarter of the mark width - 244 / 4 = 61 units
        int clrL = Wallpaper.g(ox, 77, k);
        int clrR = Wallpaper.g(ox, 443, k);
        int clrT = Wallpaper.g(oy, 45, k);
        int clrB = Wallpaper.g(oy, 447, k);

        // The 512 tile, with its rulers. Without it the vertex coordinates
        // below are unreadable: they are glyph-space, not canvas-space, and
        // the gap between this frame and the ink box IS the built-in margin.
        o.write("<rect x=\"" + Wallpaper.i(ox) + "\" y=\"" + Wallpaper.i(oy) + "\" width=\"" + Wallpaper.i(tile) + "\" height=\"" + Wallpaper.i(tile) + "\" fill=\"none\" stroke=\"" + Wallpaper.border() + "\" stroke-opacity=\"0.9\" stroke-width=\"2\"/>\n");
        for (int v = 0; v <= 512; v = v + 32) {
            int len = 9;
            if (v % 128 == 0) { len = 19; }
            int px = Wallpaper.g(ox, v, k);
            int py = Wallpaper.g(oy, v, k);
            Wallpaper.line(o, px, oy, px, oy + len, Wallpaper.muted(), 40, 1);
            Wallpaper.line(o, ox, py, ox + len, py, Wallpaper.muted(), 40, 1);
            if (v % 128 == 0 && v != 0) {
                Wallpaper.label(o, px, oy - 18, Wallpaper.mono(), 17, 400, Wallpaper.muted(), 60, 1, "middle", Wallpaper.i(v));
                Wallpaper.label(o, ox - 16, py + 6, Wallpaper.mono(), 17, 400, Wallpaper.muted(), 60, 1, "end", Wallpaper.i(v));
            }
        }
        Wallpaper.label(o, ox - 16, oy - 18, Wallpaper.mono(), 17, 500, Wallpaper.jade(), 80, 1, "end", "0,0");

        // Clearspace. The one amber thing on the sheet, and the only one that
        // earns it: this is a keep-out rule, not decoration.
        o.write("<rect x=\"" + Wallpaper.i(clrL) + "\" y=\"" + Wallpaper.i(clrT) + "\" width=\"" + Wallpaper.i(clrR - clrL) + "\" height=\"" + Wallpaper.i(clrB - clrT) + "\" fill=\"none\" stroke=\"" + Wallpaper.amber() + "\" stroke-opacity=\"0.45\" stroke-width=\"2\" stroke-dasharray=\"9 13\"/>\n");
        Wallpaper.label(o, clrL + 18, clrT - 16, Wallpaper.mono(), 17, 500, Wallpaper.amber(), 85, 3, "start", "CLEARSPACE 61");

        // ink envelope
        o.write("<rect x=\"" + Wallpaper.i(inkL) + "\" y=\"" + Wallpaper.i(inkT) + "\" width=\"" + Wallpaper.i(inkR - inkL) + "\" height=\"" + Wallpaper.i(inkB - inkT) + "\" fill=\"none\" stroke=\"" + Wallpaper.jade() + "\" stroke-opacity=\"0.22\" stroke-width=\"2\" stroke-dasharray=\"14 10\"/>\n");

        Wallpaper.openMarks(o);
        Wallpaper.mark(o, Wallpaper.g(ox, 260, k), Wallpaper.g(oy, 246, k), k, Wallpaper.jade(), 100, true);
        o.write("</g>\n");

        int[] vx = new int[]{160, 160, 196, 244, 280, 280, 360, 360};
        int[] vy = new int[]{364, 224, 190, 190, 224, 364, 364, 128};
        for (int n = 0; n < vx.length(); n++) {
            int px = Wallpaper.g(ox, vx[n], k);
            int py = Wallpaper.g(oy, vy[n], k);
            o.write("<rect x=\"" + Wallpaper.i(px - 9) + "\" y=\"" + Wallpaper.i(py - 9) + "\" width=\"18\" height=\"18\" fill=\"none\" stroke=\"" + Wallpaper.text() + "\" stroke-opacity=\"0.6\" stroke-width=\"2\"/>\n");
        }

        // three coordinates, called out where they stay off the ink
        Wallpaper.label(o, Wallpaper.g(ox, 160, k) - 54, Wallpaper.g(oy, 364, k) + 6, Wallpaper.mono(), 18, 400, Wallpaper.muted(), 70, 1, "end", "160,364");
        Wallpaper.label(o, Wallpaper.g(ox, 360, k) + 54, Wallpaper.g(oy, 128, k) + 6, Wallpaper.mono(), 18, 400, Wallpaper.muted(), 70, 1, "start", "360,128");
        Wallpaper.label(o, Wallpaper.g(ox, 244, k) + 26, Wallpaper.g(oy, 190, k) - 66, Wallpaper.mono(), 18, 400, Wallpaper.muted(), 70, 1, "start", "244,190");

        // ink width, dimensioned clear of the clearspace zone
        int dimY = clrB + 46;
        Wallpaper.line(o, inkL, inkB + 18, inkL, dimY + 22, Wallpaper.border(), 70, 1);
        Wallpaper.line(o, inkR, inkB + 18, inkR, dimY + 22, Wallpaper.border(), 70, 1);
        Wallpaper.line(o, inkL, dimY, inkR, dimY, Wallpaper.muted(), 45, 1);
        Wallpaper.line(o, inkL, dimY - 9, inkL, dimY + 9, Wallpaper.muted(), 60, 2);
        Wallpaper.line(o, inkR, dimY - 9, inkR, dimY + 9, Wallpaper.muted(), 60, 2);
        o.write("<rect x=\"" + Wallpaper.i((inkL + inkR) / 2 - 46) + "\" y=\"" + Wallpaper.i(dimY - 16) + "\" width=\"92\" height=\"32\" fill=\"" + Wallpaper.bg() + "\"/>\n");
        Wallpaper.label(o, (inkL + inkR) / 2, dimY + 8, Wallpaper.mono(), 22, 500, Wallpaper.muted(), 85, 2, "middle", "244");

        // ink height
        int dimX = clrL - 46;
        Wallpaper.line(o, inkL - 18, inkT, dimX - 22, inkT, Wallpaper.border(), 70, 1);
        Wallpaper.line(o, inkL - 18, inkB, dimX - 22, inkB, Wallpaper.border(), 70, 1);
        Wallpaper.line(o, dimX, inkT, dimX, inkB, Wallpaper.muted(), 45, 1);
        Wallpaper.line(o, dimX - 9, inkT, dimX + 9, inkT, Wallpaper.muted(), 60, 2);
        Wallpaper.line(o, dimX - 9, inkB, dimX + 9, inkB, Wallpaper.muted(), 60, 2);
        o.write("<rect x=\"" + Wallpaper.i(dimX - 26) + "\" y=\"" + Wallpaper.i((inkT + inkB) / 2 - 18) + "\" width=\"52\" height=\"36\" fill=\"" + Wallpaper.bg() + "\"/>\n");
        Wallpaper.label(o, dimX, (inkT + inkB) / 2 + 8, Wallpaper.mono(), 22, 500, Wallpaper.muted(), 85, 2, "middle", "280");

        // stroke width, across the vertical stem
        int stemL = Wallpaper.g(ox, 338, k);
        int stemR = Wallpaper.g(ox, 382, k);
        int stemY = inkT - 54;
        Wallpaper.line(o, stemL, inkT - 12, stemL, stemY - 14, Wallpaper.border(), 70, 1);
        Wallpaper.line(o, stemR, inkT - 12, stemR, stemY - 14, Wallpaper.border(), 70, 1);
        Wallpaper.line(o, stemL - 26, stemY, stemR + 26, stemY, Wallpaper.muted(), 45, 1);
        Wallpaper.line(o, stemL, stemY - 8, stemL, stemY + 8, Wallpaper.muted(), 60, 2);
        Wallpaper.line(o, stemR, stemY - 8, stemR, stemY + 8, Wallpaper.muted(), 60, 2);
        Wallpaper.label(o, stemR + 42, stemY + 7, Wallpaper.mono(), 22, 500, Wallpaper.jade(), 85, 2, "start", "44");

        // chamfer callout - the one angled cut in the whole identity. Both
        // labels sit above the leader, never on it.
        int chx = Wallpaper.g(ox, 178, k);
        int chy = Wallpaper.g(oy, 207, k);
        // the leader is kept off inkT: at 190 above the chamfer it landed
        // exactly on the ink envelope and the two lines merged
        int leadY = inkT - 62;
        Wallpaper.line(o, chx, chy, chx - 220, leadY, Wallpaper.jade(), 55, 1);
        Wallpaper.line(o, chx - 220, leadY, chx - 460, leadY, Wallpaper.jade(), 55, 1);
        o.write("<rect x=\"" + Wallpaper.i(chx - 15) + "\" y=\"" + Wallpaper.i(chy - 15) + "\" width=\"30\" height=\"30\" fill=\"none\" stroke=\"" + Wallpaper.jade() + "\" stroke-opacity=\"0.75\" stroke-width=\"2\"/>\n");
        Wallpaper.label(o, chx - 240, leadY - 62, Wallpaper.mono(), 21, 500, Wallpaper.jade(), 90, 3, "end", "CHAMFER 45&#176;");
        Wallpaper.label(o, chx - 240, leadY - 30, Wallpaper.mono(), 19, 400, Wallpaper.muted(), 75, 1, "end", "the only cut in the identity. no arcs.");

        // left column - the sheet notes
        Wallpaper.label(o, 200, 300, Wallpaper.mono(), 20, 500, Wallpaper.jade(), 90, 8, "start", "01 &#183; MARK CONSTRUCTION");
        Wallpaper.label(o, 200, 380, Wallpaper.sans(), 52, 600, Wallpaper.text(), 96, 0, "start", "Straight lines,");
        Wallpaper.label(o, 200, 442, Wallpaper.sans(), 52, 600, Wallpaper.text(), 96, 0, "start", "one chamfer,");
        Wallpaper.label(o, 200, 504, Wallpaper.sans(), 52, 600, Wallpaper.jade(), 96, 0, "start", "nothing hidden.");
        Wallpaper.label(o, 202, 576, Wallpaper.sans(), 24, 400, Wallpaper.muted(), 90, 0, "start", "Null safety, checked exceptions, exhaustive matching.");

        // title block, flush in the bottom-right corner of the sheet margin
        int tbw = 580;
        int tbh = 224;
        int tbx = 2560 - margin - tbw;
        int tby = 1440 - margin - tbh;
        o.write("<rect x=\"" + Wallpaper.i(tbx) + "\" y=\"" + Wallpaper.i(tby) + "\" width=\"" + Wallpaper.i(tbw) + "\" height=\"" + Wallpaper.i(tbh) + "\" fill=\"" + Wallpaper.bg() + "\" fill-opacity=\"0.9\" stroke=\"" + Wallpaper.border() + "\" stroke-width=\"2\"/>\n");
        Wallpaper.line(o, tbx, tby + 52, tbx + tbw, tby + 52, Wallpaper.border(), 100, 2);
        Wallpaper.label(o, tbx + 24, tby + 34, Wallpaper.mono(), 22, 700, Wallpaper.text(), 95, 6, "start", "NL &#183; THE MARK");
        Wallpaper.label(o, tbx + tbw - 24, tby + 34, Wallpaper.mono(), 18, 400, Wallpaper.jade(), 85, 2, "end", "SHEET 01/01");
        Wallpaper.label(o, tbx + 24, tby + 90, Wallpaper.mono(), 18, 400, Wallpaper.muted(), 80, 1, "start", "GLYPH SPACE 512 &#215; 512 &#183; SCALE 1:1");
        Wallpaper.label(o, tbx + 24, tby + 122, Wallpaper.mono(), 18, 400, Wallpaper.muted(), 80, 1, "start", "STROKE 44 &#183; MITER &#183; SQUARE CAP");
        Wallpaper.label(o, tbx + 24, tby + 154, Wallpaper.mono(), 18, 400, Wallpaper.muted(), 80, 1, "start", "JADE #35C99B ON #0A0F0C");
        Wallpaper.label(o, tbx + 24, tby + 186, Wallpaper.mono(), 18, 400, Wallpaper.amber(), 85, 1, "start", "CLEARSPACE 61 &#183; MIN SIZE 24 PX");
        Wallpaper.wordmark(o, tbx + tbw - 24, tby + 190, 34, 90);

        // sheet margin, marked at the three corners the title block leaves free
        Wallpaper.line(o, margin, margin, margin + 60, margin, Wallpaper.border(), 90, 2);
        Wallpaper.line(o, margin, margin, margin, margin + 60, Wallpaper.border(), 90, 2);
        Wallpaper.line(o, 2560 - margin, margin, 2560 - margin - 60, margin, Wallpaper.border(), 90, 2);
        Wallpaper.line(o, 2560 - margin, margin, 2560 - margin, margin + 60, Wallpaper.border(), 90, 2);
        Wallpaper.line(o, margin, 1440 - margin, margin + 60, 1440 - margin, Wallpaper.border(), 90, 2);
        Wallpaper.line(o, margin, 1440 - margin, margin, 1440 - margin - 60, Wallpaper.border(), 90, 2);

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
