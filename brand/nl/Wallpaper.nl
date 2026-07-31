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

    private static void stop(system.io.FileHandle o, string offset, string color, int alpha) throws IOException {
        o.write("<stop offset=\"" + offset + "\" stop-color=\"" + color + "\" stop-opacity=\"" + Wallpaper.op(alpha) + "\"/>");
    }

    // A straight-edged shaft of light: the triangle between a point source and
    // a slice of the far edge. Arcs are still out, so volumetric light is made
    // of polygons - which is also why it stays this crisp when it is rasterised
    // at 4K.
    private static void wedge(system.io.FileHandle o, int sx, int sy, int ex,
                              int y1, int y2, string fill, int alpha) throws IOException {
        o.write("<path d=\"M" + Wallpaper.i(sx) + " " + Wallpaper.i(sy) + "L" + Wallpaper.i(ex) + " " + Wallpaper.i(y1) + "L" + Wallpaper.i(ex) + " " + Wallpaper.i(y2) + "Z\" fill=\"" + fill + "\" fill-opacity=\"" + Wallpaper.op(alpha) + "\"/>\n");
    }

    // Where the ray from (sx,sy) through (px,py) is, once it reaches atX.
    private static int ray(int sx, int sy, int px, int py, int atX) {
        return sy + ((py - sy) * (atX - sx)) / (px - sx);
    }

    // The beam. One wide shaft aimed straight at the mark - so that the shadow
    // has something to be a shadow *of* - and a scatter of thinner ones around
    // it for the air. Everything goes through the gobo, so the mark prints
    // itself into the light instead of sitting on top of it.
    //
    // It is called twice: once over the sheet and once clipped to the code
    // panel, weaker, so the light reads as landing on a surface rather than
    // floating over one. The two copies line up only because each call is given
    // a freshly seeded Rng - which is what Rng.nl is for.
    private static void fan(system.io.FileHandle o, Rng rng, int sx, int sy,
                            int mx, int my, int strength) throws IOException {
        o.write("<g mask=\"url(#gobo)\" opacity=\"" + Wallpaper.op(strength) + "\">\n");

        // the core, framed on the mark's ink box with 60px to spare
        int lead = mx - 134;
        int top = Wallpaper.ray(sx, sy, lead, my - 214, 2560);
        int bot = Wallpaper.ray(sx, sy, lead, my + 214, 2560);
        Wallpaper.wedge(o, sx, sy, 2560, top, bot, "url(#ray)", 15);

        int t = -1100;
        while (t < 2600) {
            int w = rng.range(30, 190);
            int a = rng.range(4, 11);
            Wallpaper.wedge(o, sx, sy, 2560, t, t + w, "url(#ray)", a);
            t = t + w + rng.range(70, 260);
        }
        o.write("</g>\n");
    }

    // The mark, used as a gobo. A point source casts the shadow of a shape as
    // that same shape scaled about the source: at factor s, a point P lands on
    // S + s(P - S). So the whole shadow cone is nothing but the mark drawn
    // again and again about the source, larger every time, in black, inside a
    // mask - no ray casting, no arcs, no imported bitmap.
    //
    // The light that gets past it is the light that went through the counter of
    // the n and the gap before the l, which is the point: what identifies the
    // mark is as much what is not drawn as what is.
    private static void gobo(system.io.FileHandle o, int sx, int sy, int mx, int my, int k0) throws IOException {
        o.write("<mask id=\"gobo\" maskUnits=\"userSpaceOnUse\" x=\"0\" y=\"0\" width=\"2560\" height=\"1440\">\n");
        o.write("<rect width=\"2560\" height=\"1440\" fill=\"#ffffff\"/>\n");
        // The cone is a union of discrete copies, so its outline is a staircase
        // one step long - 34px here. Blurring the whole stack costs one filter
        // and buys two things: the staircase disappears, and the shadow gets the
        // soft edge every real shadow has. Nothing casts a razor.
        o.write("<g filter=\"url(#penumbra)\">\n");
        Wallpaper.openMarks(o);
        // A 0.6% step drifts a copy by ~34px against a stroke ~50px wide, so
        // consecutive copies still overlap and the cone comes out solid rather
        // than striped. The loop stops as soon as a copy has left the sheet.
        for (int s = 1000; s <= 12000; s = s + 6) {
            int cx = sx + ((mx - sx) * s) / 1000;
            int cy = sy + ((my - sy) * s) / 1000;
            if (cx > 3600 || cy > 2600) { break; }
            Wallpaper.mark(o, cx, cy, (k0 * s) / 1000, "#000000", 100, true);
        }
        o.write("</g>\n</g>\n</mask>\n");
    }

    // One line of source, as its own <text>. The line owns its brightness and
    // the scanner owns its colours; the two never negotiate.
    private static void codeLine(system.io.FileHandle o, int x, int y, int lum, string src) throws IOException {
        o.write("<text x=\"" + Wallpaper.i(x) + "\" y=\"" + Wallpaper.i(y) + "\" xml:space=\"preserve\" fill-opacity=\"" + Wallpaper.op(lum) + "\">" + Highlight.tspans(src) + "</text>\n");
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

    // ---------------------------------------------------------------- D ----
    // "Lumen". The language itself, on the wall. Twenty lines of real NL - they
    // compile with nlc and run on nlvm, exit 0 - standing in a beam that comes
    // in from off the sheet, hits the mark, and carries its shadow across the
    // code. Brightness is the argument, as in concept A: the accent falls on
    // the one line that holds the whole idea, `public int|null read() throws
    // IOException`, and no other line drops below 46. Nothing is hidden.
    //
    // And nothing is imported. The shafts are polygons, the shadow is the mark
    // scaled about the source, the bloom is a blur of the same geometry, the
    // grain is fractal noise, and the colours come from a scanner that reads
    // the source character by character (Highlight.nl). The .svg is the whole
    // asset - no bitmap, no font subset, no external anything.
    public static void conceptLumen(string path) throws IOException {
        auto o = system.io.File.open(path, system.io.FileMode.ReadWriteTruncate);
        Wallpaper.head(o, "NL - the checker's light");

        // The source is far off the sheet, up and to the left, and the mark
        // stands in its beam. Two things follow from putting it *far* away.
        // A source sitting on the mark blocks every direction at once and the
        // wall goes flat; a source just off the edge throws a shadow that grows
        // faster than the sheet and swallows the panel whole. From 5200px out
        // the rays are near enough to parallel that the shadow stays the size
        // of the mark, and the counter of the n still reads as a channel when
        // it lands on the code, 2000px downstream.
        int sx = -5200;
        int sy = -1600;
        int mx = 400;
        int my = 300;
        int mk = 1100;

        // The panel. Chamfered top-left and bottom-right - the mark's one cut,
        // repeated at sheet scale.
        int panL = 950;
        int panR = 2470;
        int panT = 232;
        int panB = 1300;
        int cham = 30;

        // 20 lines at 30/50. IBM Plex Mono advances 0.6em, so a column is
        // exactly 18px and the longest line lands at 1050 + 75*18 = 2400.
        int codeX = 1050;
        int line0 = 292;
        int lineH = 50;
        int focus = 6;
        int focusY = line0 + focus * lineH;

        string[] src = new string[]{
            "namespace demo;",
            "",
            "class Port {",
            "    private readonly string source;",
            "",
            "    // A missing port is a value, not a surprise.",
            "    public int|null read() throws IOException {",
            "        auto f = system.io.File.open(this.source, system.io.FileMode.Read);",
            "        string|null raw = f.readLine();",
            "        f.close();",
            "        if (raw == null) { return null; }",
            "        return system.Int.tryParse(raw.trim());",
            "    }",
            "",
            "    public string status() throws IOException {",
            "        int|null port = this.read();",
            "        if (port == null) { return \"no port configured\"; }",
            "        return \"listening on \" + port;",
            "    }",
            "}"
        };

        o.write("<defs>\n");
        // the spill: where the beam enters the sheet, not where it comes from
        o.write("<radialGradient id=\"spill\" gradientUnits=\"userSpaceOnUse\" cx=\"-120\" cy=\"-80\" r=\"1500\">");
        Wallpaper.stop(o, "0", Wallpaper.jadeBright(), 34);
        Wallpaper.stop(o, "0.5", Wallpaper.jade(), 10);
        Wallpaper.stop(o, "1", Wallpaper.jade(), 0);
        o.write("</radialGradient>\n");
        // and the halo the mark itself throws back
        o.write("<radialGradient id=\"halo\" gradientUnits=\"userSpaceOnUse\" cx=\"" + Wallpaper.i(mx) + "\" cy=\"" + Wallpaper.i(my) + "\" r=\"640\">");
        Wallpaper.stop(o, "0", Wallpaper.jadeBright(), 22);
        Wallpaper.stop(o, "0.45", Wallpaper.jade(), 7);
        Wallpaper.stop(o, "1", Wallpaper.jade(), 0);
        o.write("</radialGradient>\n");
        // Every shaft shares one falloff so the beam keeps a single direction.
        // It is measured across the sheet, not from the source: the source is
        // 5200px off-canvas and a gradient anchored there would spend all of
        // its range outside the picture.
        o.write("<linearGradient id=\"ray\" gradientUnits=\"userSpaceOnUse\" x1=\"-200\" y1=\"0\" x2=\"2560\" y2=\"0\">");
        Wallpaper.stop(o, "0", Wallpaper.jadeBright(), 72);
        Wallpaper.stop(o, "0.42", Wallpaper.jade(), 28);
        Wallpaper.stop(o, "1", Wallpaper.jade(), 3);
        o.write("</linearGradient>\n");
        // the light landing on the panel's leading edge
        o.write("<linearGradient id=\"edge\" gradientUnits=\"userSpaceOnUse\" x1=\"0\" y1=\"" + Wallpaper.i(panT) + "\" x2=\"0\" y2=\"" + Wallpaper.i(panB) + "\">");
        Wallpaper.stop(o, "0", Wallpaper.jade(), 0);
        Wallpaper.stop(o, "0.34", Wallpaper.jadeBright(), 85);
        Wallpaper.stop(o, "0.62", Wallpaper.jade(), 12);
        Wallpaper.stop(o, "1", Wallpaper.jade(), 0);
        o.write("</linearGradient>\n");
        // the bar under the line the beam is aimed at
        o.write("<linearGradient id=\"row\" gradientUnits=\"userSpaceOnUse\" x1=\"" + Wallpaper.i(panL) + "\" y1=\"0\" x2=\"" + Wallpaper.i(panR) + "\" y2=\"0\">");
        Wallpaper.stop(o, "0", Wallpaper.jadeBright(), 34);
        Wallpaper.stop(o, "0.55", Wallpaper.jade(), 10);
        Wallpaper.stop(o, "1", Wallpaper.jade(), 0);
        o.write("</linearGradient>\n");
        // light comes from the left, so the far end of every line sits deeper
        o.write("<linearGradient id=\"falloff\" gradientUnits=\"userSpaceOnUse\" x1=\"" + Wallpaper.i(codeX) + "\" y1=\"0\" x2=\"2420\" y2=\"0\">");
        o.write("<stop offset=\"0\" stop-color=\"#ffffff\" stop-opacity=\"1\"/>");
        o.write("<stop offset=\"1\" stop-color=\"#ffffff\" stop-opacity=\"0.72\"/>");
        o.write("</linearGradient>\n");
        o.write("<mask id=\"lit\" maskUnits=\"userSpaceOnUse\" x=\"" + Wallpaper.i(panL) + "\" y=\"" + Wallpaper.i(panT) + "\" width=\"" + Wallpaper.i(panR - panL) + "\" height=\"" + Wallpaper.i(panB - panT) + "\">");
        o.write("<rect x=\"" + Wallpaper.i(panL) + "\" y=\"" + Wallpaper.i(panT) + "\" width=\"" + Wallpaper.i(panR - panL) + "\" height=\"" + Wallpaper.i(panB - panT) + "\" fill=\"url(#falloff)\"/></mask>\n");
        o.write("<clipPath id=\"panel\"><path d=\"M" + Wallpaper.i(panL + cham) + " " + Wallpaper.i(panT) + "L" + Wallpaper.i(panR) + " " + Wallpaper.i(panT) + "L" + Wallpaper.i(panR) + " " + Wallpaper.i(panB - cham) + "L" + Wallpaper.i(panR - cham) + " " + Wallpaper.i(panB) + "L" + Wallpaper.i(panL) + " " + Wallpaper.i(panB) + "L" + Wallpaper.i(panL) + " " + Wallpaper.i(panT + cham) + "Z\"/></clipPath>\n");
        // bloom: blur the geometry, then lift the alpha back up so the halo
        // reads as light and not as a smudge
        o.write("<filter id=\"bloom\" x=\"-60%\" y=\"-60%\" width=\"220%\" height=\"220%\"><feGaussianBlur stdDeviation=\"19\" result=\"b\"/><feComponentTransfer in=\"b\"><feFuncA type=\"linear\" slope=\"1.35\"/></feComponentTransfer></filter>\n");
        o.write("<filter id=\"penumbra\" x=\"-20%\" y=\"-20%\" width=\"140%\" height=\"140%\"><feGaussianBlur stdDeviation=\"17\"/></filter>\n");
        o.write("<filter id=\"bloomSoft\" x=\"-60%\" y=\"-60%\" width=\"220%\" height=\"220%\"><feGaussianBlur stdDeviation=\"9\"/></filter>\n");
        // fractal noise, tinted jade and kept under 10% - the only thing on the
        // sheet that is not aligned to the grid
        o.write("<filter id=\"grain\" x=\"0%\" y=\"0%\" width=\"100%\" height=\"100%\"><feTurbulence type=\"fractalNoise\" baseFrequency=\"0.85\" numOctaves=\"2\" seed=\"31\" result=\"n\"/><feColorMatrix in=\"n\" type=\"matrix\" values=\"0 0 0 0 0.72  0 0 0 0 0.94  0 0 0 0 0.85  0 0 0 0.55 0\"/></filter>\n");
        o.write("<radialGradient id=\"vignette\" gradientUnits=\"userSpaceOnUse\" cx=\"1180\" cy=\"660\" r=\"1620\">");
        Wallpaper.stop(o, "0.42", "#000000", 0);
        Wallpaper.stop(o, "1", "#000000", 62);
        o.write("</radialGradient>\n");
        Wallpaper.gobo(o, sx, sy, mx, my, mk);
        o.write("</defs>\n");

        o.write("<rect width=\"2560\" height=\"1440\" fill=\"url(#spill)\"/>\n");
        o.write("<rect width=\"2560\" height=\"1440\" fill=\"url(#halo)\"/>\n");
        Wallpaper.fan(o, new Rng(20260801), sx, sy, mx, my, 100);

        // the panel: translucent, so the fan keeps going underneath it
        o.write("<g clip-path=\"url(#panel)\">\n");
        o.write("<rect x=\"" + Wallpaper.i(panL) + "\" y=\"" + Wallpaper.i(panT) + "\" width=\"" + Wallpaper.i(panR - panL) + "\" height=\"" + Wallpaper.i(panB - panT) + "\" fill=\"#0c1512\" fill-opacity=\"0.70\"/>\n");
        Wallpaper.fan(o, new Rng(20260801), sx, sy, mx, my, 80);
        o.write("<rect x=\"" + Wallpaper.i(panL) + "\" y=\"" + Wallpaper.i(focusY - 36) + "\" width=\"" + Wallpaper.i(panR - panL) + "\" height=\"50\" fill=\"url(#row)\"/>\n");
        o.write("</g>\n");

        o.write("<path d=\"M" + Wallpaper.i(panL + cham) + " " + Wallpaper.i(panT) + "L" + Wallpaper.i(panR) + " " + Wallpaper.i(panT) + "L" + Wallpaper.i(panR) + " " + Wallpaper.i(panB - cham) + "L" + Wallpaper.i(panR - cham) + " " + Wallpaper.i(panB) + "L" + Wallpaper.i(panL) + " " + Wallpaper.i(panB) + "L" + Wallpaper.i(panL) + " " + Wallpaper.i(panT + cham) + "Z\" fill=\"none\" stroke=\"" + Wallpaper.jade() + "\" stroke-opacity=\"0.16\" stroke-width=\"2\"/>\n");
        o.write("<path d=\"M" + Wallpaper.i(panL) + " " + Wallpaper.i(panT + cham) + "L" + Wallpaper.i(panL) + " " + Wallpaper.i(panB) + "\" stroke=\"url(#edge)\" stroke-width=\"3\"/>\n");

        // line numbers, in the gutter, dim enough to stay out of the way
        o.write("<g font-family=\"" + Wallpaper.mono() + "\" font-size=\"19\" fill=\"" + Wallpaper.faint() + "\" text-anchor=\"end\">\n");
        for (int n = 0; n < src.length(); n++) {
            int num = n + 1;
            string pad = Wallpaper.i(num);
            if (num < 10) { pad = "0" + pad; }
            int a = 30;
            if (n == focus) { a = 70; }
            o.write("<text x=\"1010\" y=\"" + Wallpaper.i(line0 + n * lineH) + "\" fill-opacity=\"" + Wallpaper.op(a) + "\">" + pad + "</text>\n");
        }
        o.write("</g>\n");

        // the source. Its brightness is a function of the distance to the beam,
        // and the floor is 46: a line you cannot read is a line that hides.
        o.write("<g font-family=\"" + Wallpaper.mono() + "\" font-size=\"30\" mask=\"url(#lit)\">\n");
        for (int n = 0; n < src.length(); n++) {
            int y = line0 + n * lineH;
            int lum = Wallpaper.clamp(104 - Wallpaper.abs(y - focusY) / 14, 46, 100);
            Wallpaper.codeLine(o, codeX, y, lum, src[n]);
        }
        o.write("</g>\n");
        // the caret, parked after the closing brace
        o.write("<rect x=\"" + Wallpaper.i(codeX + 18) + "\" y=\"" + Wallpaper.i(line0 + 19 * lineH - 24) + "\" width=\"13\" height=\"30\" fill=\"" + Wallpaper.jade() + "\" fill-opacity=\"0.5\"/>\n");

        // the mark, standing in the beam
        o.write("<g filter=\"url(#bloom)\">\n");
        Wallpaper.openMarks(o);
        Wallpaper.mark(o, mx, my, mk, Wallpaper.jadeBright(), 90, true);
        o.write("</g></g>\n");
        Wallpaper.openMarks(o);
        Wallpaper.mark(o, mx, my, mk, Wallpaper.jadeBright(), 100, true);
        o.write("</g>\n");

        // the callout, aimed at line 07 - the one flag on the sheet, and the
        // only place amber is louder than a token
        Wallpaper.line(o, 894, focusY - 8, 944, focusY - 8, Wallpaper.amber(), 40, 1);
        Wallpaper.label(o, 880, focusY - 30, Wallpaper.mono(), 21, 500, Wallpaper.amber(), 88, 2, "end", "int|null &#183; the signature says so,");
        Wallpaper.label(o, 880, focusY + 2, Wallpaper.mono(), 21, 400, Wallpaper.amber(), 62, 1, "end", "so the caller cannot skip it.");

        Wallpaper.label(o, 82, 762, Wallpaper.mono(), 20, 500, Wallpaper.jade(), 90, 8, "start", "04 &#183; THE LANGUAGE");
        o.write("<g filter=\"url(#bloomSoft)\" opacity=\"0.35\">\n");
        Wallpaper.label(o, 80, 842, Wallpaper.sans(), 58, 600, Wallpaper.text(), 100, 0, "start", "You cannot forget");
        Wallpaper.label(o, 80, 908, Wallpaper.sans(), 58, 600, Wallpaper.text(), 100, 0, "start", "what the type");
        Wallpaper.label(o, 80, 974, Wallpaper.sans(), 58, 600, Wallpaper.jade(), 100, 0, "start", "already told you.");
        o.write("</g>\n");
        Wallpaper.label(o, 80, 842, Wallpaper.sans(), 58, 600, Wallpaper.text(), 96, 0, "start", "You cannot forget");
        Wallpaper.label(o, 80, 908, Wallpaper.sans(), 58, 600, Wallpaper.text(), 96, 0, "start", "what the type");
        Wallpaper.label(o, 80, 974, Wallpaper.sans(), 58, 600, Wallpaper.jade(), 96, 0, "start", "already told you.");
        Wallpaper.label(o, 82, 1046, Wallpaper.sans(), 25, 400, Wallpaper.muted(), 88, 0, "start", "Unions make null explicit. Checked exceptions");
        Wallpaper.label(o, 82, 1080, Wallpaper.sans(), 25, 400, Wallpaper.muted(), 88, 0, "start", "and exhaustive matches do the rest.");

        Wallpaper.label(o, panL, 1362, Wallpaper.mono(), 19, 400, Wallpaper.faint(), 85, 4, "start", "DEMO/PORT.NL &#183; 20 LINES &#183; COMPILES CLEAN &#183; RUNS AS-IS");
        Wallpaper.wordmark(o, panR, 1364, 42, 70);

        // the same sheet margin as concept B, marked at the two corners the
        // panel leaves free - it is the same drawing office, after all
        Wallpaper.line(o, 80, 80, 140, 80, Wallpaper.border(), 70, 2);
        Wallpaper.line(o, 80, 80, 80, 140, Wallpaper.border(), 70, 2);
        Wallpaper.line(o, 80, 1360, 140, 1360, Wallpaper.border(), 70, 2);
        Wallpaper.line(o, 80, 1360, 80, 1300, Wallpaper.border(), 70, 2);

        o.write("<rect width=\"2560\" height=\"1440\" fill=\"url(#vignette)\"/>\n");
        o.write("<rect width=\"2560\" height=\"1440\" filter=\"url(#grain)\" opacity=\"0.09\"/>\n");

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
        Wallpaper.conceptLumen("brand/generated/wallpaper-d-lumen.svg");
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
