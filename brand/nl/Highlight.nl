namespace brand;

// A syntax highlighter for NL, written in NL, emitting SVG tspans.
//
// The wallpaper shows real source, so the colouring has to be real too: this is
// a scanner over the characters, not a table of pre-tagged strings. If the code
// on the wall ever changes, the colours follow on their own.
//
// The palette is a luminance ladder, not a rainbow: the hue stays jade from top
// to bottom and only the brightness moves, exactly like concept A. One token
// breaks the rule - `null` is amber. Amber is the brand's flag colour, and null
// is the one thing the language refuses to let you leave implicit, so it is the
// only thing on the sheet allowed to flag itself.
class Highlight {
    private static string keywords() {
        return " namespace class enum interface use as public private protected static readonly final abstract const auto new return if else for foreach while switch case default break continue match try catch finally throw throws this self super null true false void int float bool string byte construct destruct extends implements virtual override nodiscard typedef instanceof ";
    }

    private static string letters() { return "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"; }
    private static string upper() { return "ABCDEFGHIJKLMNOPQRSTUVWXYZ"; }
    private static string digits() { return "0123456789"; }

    // the ladder, brightest first
    private static string cKeyword() { return "#4ee0ac"; }
    private static string cType() { return "#e7eeea"; }
    private static string cMethod() { return "#bfe3d1"; }
    private static string cMember() { return "#a7c5b9"; }
    private static string cIdent() { return "#8fa8a0"; }
    private static string cString() { return "#7cbda6"; }
    private static string cNumber() { return "#cfe0d8"; }
    private static string cPunct() { return "#6d857e"; }
    private static string cComment() { return "#5d7a71"; }
    private static string cNull() { return "#e0a458"; }

    private static bool isIn(string set, string c) {
        return set.indexOf(c) >= 0;
    }

    private static bool isWord(string c) {
        return Highlight.isIn(Highlight.letters(), c) || Highlight.isIn(Highlight.digits(), c);
    }

    private static string esc(string s) {
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
    }

    private static string span(string color, string text) {
        return "<tspan fill=\"" + color + "\">" + Highlight.esc(text) + "</tspan>";
    }

    // The character before index i, "" at the start of the line. Used to spot
    // member access: what follows a dot is never a bare identifier.
    private static string before(string line, int i) {
        if (i <= 0) { return ""; }
        return line.charAt(i - 1);
    }

    // The next character that is not a space, "" at end of line. Used to spot a
    // call: what precedes an open paren is a method name, whatever its case.
    private static string peek(string line, int from) {
        int n = line.length();
        int j = from;
        while (j < n) {
            string c = line.charAt(j);
            if (c != " ") { return c; }
            j = j + 1;
        }
        return "";
    }

    private static string wordColor(string w, string prev, string next) {
        if (w == "null") { return Highlight.cNull(); }
        if (Highlight.isIn(Highlight.keywords(), " " + w + " ")) { return Highlight.cKeyword(); }
        if (next == "(") { return Highlight.cMethod(); }
        if (Highlight.isIn(Highlight.upper(), w.charAt(0))) { return Highlight.cType(); }
        if (prev == ".") { return Highlight.cMember(); }
        return Highlight.cIdent();
    }

    // One line of NL source -> the inner markup of one <text> element. The
    // caller owns the element itself, and so owns the line's brightness: the
    // scanner never decides how lit a line is, only what colour its tokens are.
    public static string tspans(string line) {
        string out = "";
        int n = line.length();
        int i = 0;
        while (i < n) {
            string c = line.charAt(i);

            // a comment swallows the rest of the line, whatever is in it
            if (c == "/" && i + 1 < n && line.charAt(i + 1) == "/") {
                return out + Highlight.span(Highlight.cComment(), line.substring(i));
            }

            if (c == "\"") {
                int j = i + 1;
                while (j < n && line.charAt(j) != "\"") { j = j + 1; }
                if (j < n) { j = j + 1; }
                out = out + Highlight.span(Highlight.cString(), line.substring(i, j));
                i = j;
                continue;
            }

            if (Highlight.isIn(Highlight.digits(), c)) {
                int j = i;
                while (j < n && Highlight.isWord(line.charAt(j))) { j = j + 1; }
                out = out + Highlight.span(Highlight.cNumber(), line.substring(i, j));
                i = j;
                continue;
            }

            if (Highlight.isIn(Highlight.letters(), c)) {
                int j = i;
                while (j < n && Highlight.isWord(line.charAt(j))) { j = j + 1; }
                string w = line.substring(i, j);
                out = out + Highlight.span(Highlight.wordColor(w, Highlight.before(line, i), Highlight.peek(line, j)), w);
                i = j;
                continue;
            }

            // everything else - operators, braces, spaces - runs together in
            // one span, and stops dead at the start of a comment
            int k = i;
            while (k < n) {
                string d = line.charAt(k);
                if (d == "\"" || Highlight.isWord(d)) { break; }
                if (d == "/" && k + 1 < n && line.charAt(k + 1) == "/") { break; }
                k = k + 1;
            }
            out = out + Highlight.span(Highlight.cPunct(), line.substring(i, k));
            i = k;
        }
        return out;
    }
}
