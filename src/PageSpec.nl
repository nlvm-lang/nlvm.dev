namespace site;

class PageSpec {
    public string title;
    public string description;
    public string contentPath;
    public string outPath;
    public string root;
    public bool inDevlog;
    public string navActiveId;
    public string footerFirst;

    public construct(string title, string description, string contentPath, string outPath,
                      string root, bool inDevlog, string navActiveId, string footerFirst) {
        this.title = title;
        this.description = description;
        this.contentPath = contentPath;
        this.outPath = outPath;
        this.root = root;
        this.inDevlog = inDevlog;
        this.navActiveId = navActiveId;
        this.footerFirst = footerFirst;
    }
}
