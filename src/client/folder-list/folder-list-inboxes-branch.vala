/* Copyright 2016 Software Freedom Conservancy Inc.
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

// A special branch that sits before the accounts branches, containing only
// the inboxes for all accounts.
public class FolderList.InboxesBranch : Sidebar.Branch {
    public Gee.HashMap<Geary.Account, InboxFolderEntry> folder_entries {
        get; private set; default = new Gee.HashMap<Geary.Account, InboxFolderEntry>(); }

    public AllInboxesEntry? all_inboxes_entry { get; private set; default = null; }

    public InboxesBranch() {
        base(
            new Sidebar.Header(_("Inboxes")),
            STARTUP_OPEN_GROUPING,
            inbox_comparator
        );
    }

    private static int inbox_comparator(Sidebar.Entry a, Sidebar.Entry b) {
        bool a_all = a is AllInboxesEntry;
        bool b_all = b is AllInboxesEntry;
        if (a_all && !b_all)
            return -1;
        if (!a_all && b_all)
            return 1;
        if (a_all && b_all)
            return 0;

        InboxFolderEntry entry_a = (InboxFolderEntry) a;
        InboxFolderEntry entry_b = (InboxFolderEntry) b;
        return Geary.AccountInformation.compare_ascending(entry_a.get_account_information(),
            entry_b.get_account_information());
    }

    public InboxFolderEntry? get_entry_for_account(Geary.Account account) {
        return folder_entries.get(account);
    }

    /** Returns the folder for the first inbox by account ordinal, or null if none. */
    public Geary.Folder? get_first_inbox_folder() {
        if (folder_entries.is_empty)
            return null;
        InboxFolderEntry? first = null;
        foreach (var entry in folder_entries.values) {
            if (first == null ||
                Geary.AccountInformation.compare_ascending(
                    entry.get_account_information(),
                    first.get_account_information()) < 0) {
                first = entry;
            }
        }
        return first != null ? first.folder : null;
    }

    /** Returns all inbox folders sorted by account ordinal. */
    public Gee.List<Geary.Folder> get_all_inbox_folders() {
        var list = new Gee.ArrayList<Geary.Folder>();
        var entries_list = new Gee.ArrayList<InboxFolderEntry>();
        entries_list.add_all(folder_entries.values);
        entries_list.sort((a, b) =>
            Geary.AccountInformation.compare_ascending(
                a.get_account_information(),
                b.get_account_information()));
        foreach (var entry in entries_list) {
            list.add(entry.folder);
        }
        return list;
    }

    public void add_inbox(Application.FolderContext inbox) {
        if (folder_entries.is_empty) {
            all_inboxes_entry = new AllInboxesEntry(this);
            graft(get_root(), all_inboxes_entry);
        }
        inbox.folder.properties.notify[Geary.FolderProperties.PROP_NAME_EMAIL_UNREAD]
            .connect(on_inbox_unread_changed);

        InboxFolderEntry folder_entry = new InboxFolderEntry(inbox);
        graft(get_root(), folder_entry);

        folder_entries.set(inbox.folder.account, folder_entry);
        inbox.folder.account.information.notify["ordinal"].connect(on_ordinal_changed);
    }

    public void remove_inbox(Geary.Account account) {
        Sidebar.Entry? entry = folder_entries.get(account);
        if(entry == null) {
            debug("Could not remove inbox for %s", account.to_string());
            return;
        }

        account.information.notify["ordinal"].disconnect(on_ordinal_changed);
        var folder_entry = (InboxFolderEntry) entry;
        folder_entry.folder.properties.notify[Geary.FolderProperties.PROP_NAME_EMAIL_UNREAD]
            .disconnect(on_inbox_unread_changed);
        prune(entry);
        folder_entries.unset(account);

        if (folder_entries.is_empty && all_inboxes_entry != null) {
            prune(all_inboxes_entry);
            all_inboxes_entry = null;
        }
    }

    private void on_inbox_unread_changed() {
        if (all_inboxes_entry != null)
            all_inboxes_entry.notify_count_changed();
    }

    private void on_ordinal_changed() {
        reorder_all();
    }
}
