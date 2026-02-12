/* Copyright 2016 Software Freedom Conservancy Inc.
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

// Sidebar entry for "All Inboxes" that aggregates all account inboxes.
public class FolderList.AllInboxesEntry : Geary.BaseObject,
    Sidebar.Entry,
    Sidebar.SelectableEntry {

    private weak InboxesBranch branch;

    public AllInboxesEntry(InboxesBranch branch) {
        this.branch = branch;
    }

    public string get_sidebar_name() {
        return _("All Inboxes");
    }

    public string? get_sidebar_tooltip() {
        return _("View all inboxes");
    }

    public string? get_sidebar_icon() {
        return "mail-inbox-symbolic";
    }

    public int get_count() {
        int total = 0;
        foreach (var entry in branch.folder_entries.values) {
            total += entry.folder.properties.email_unread;
        }
        return total;
    }

    public string to_string() {
        return "AllInboxesEntry: " + get_sidebar_name();
    }

    /** Call when any inbox unread count changes so the sidebar updates the displayed count. */
    public void notify_count_changed() {
        entry_changed();
    }
}
