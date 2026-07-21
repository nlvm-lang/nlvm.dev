namespace site;

class NavItem {
    public string id;
    public string label;
    public string href;
    public bool external;

    public construct(string id, string label, string href, bool external) {
        this.id = id;
        this.label = label;
        this.href = href;
        this.external = external;
    }
}
