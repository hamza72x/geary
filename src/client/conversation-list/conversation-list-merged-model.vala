/*
 * Copyright © 2022 John Renner <john@jrenner.net>
 * Copyright © 2022 Cédric Bellegarde <cedric.bellegarde@adishatz.org>
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later). See the COPYING file in this distribution.
 */

/**
 * Merges multiple ConversationMonitors into a single sorted list (e.g. for "All Inboxes").
 */
public class ConversationList.MergedModel : Object, ListModel {
    internal GLib.GenericArray<Geary.App.Conversation> items =
        new GLib.GenericArray<Geary.App.Conversation>();
    private Gee.List<Geary.App.ConversationMonitor> monitors =
        new Gee.ArrayList<Geary.App.ConversationMonitor>();
    private int scans_pending = 0;

    public signal void conversations_added(bool start);
    public signal void conversations_removed(bool start);
    public signal void conversations_loaded();
    public signal void conversation_updated(Geary.App.Conversation convo);

    public MergedModel(Gee.Collection<Geary.App.ConversationMonitor> monitors) {
        this.monitors.add_all(monitors);
        scans_pending = this.monitors.size;
        foreach (var monitor in this.monitors) {
            monitor.conversations_added.connect(on_conversations_added);
            monitor.conversations_removed.connect(on_conversations_removed);
            monitor.conversation_appended.connect(on_conversation_appended);
            monitor.conversation_trimmed.connect(on_conversation_trimmed);
            monitor.scan_completed.connect(on_scan_completed);
        }
        // Seed from already-loaded conversations
        foreach (var monitor in this.monitors) {
            foreach (var convo in monitor.read_only_view) {
                insert_conversation(convo);
            }
        }
        items.sort(compare);
    }

    ~MergedModel() {
        foreach (var monitor in monitors) {
            monitor.conversations_added.disconnect(on_conversations_added);
            monitor.conversations_removed.disconnect(on_conversations_removed);
            monitor.conversation_appended.disconnect(on_conversation_appended);
            monitor.conversation_trimmed.disconnect(on_conversation_trimmed);
            monitor.scan_completed.disconnect(on_scan_completed);
        }
    }

    public Object? get_item(uint position) {
        if (position >= items.length)
            return null;
        return items.get(position);
    }

    public Type get_item_type() {
        return typeof(Geary.App.Conversation);
    }

    public uint get_n_items() {
        return items.length;
    }

    public bool load_more(int amount) {
        bool any = false;
        foreach (var monitor in monitors) {
            monitor.min_window_count += amount;
            any = true;
        }
        return any;
    }

    private static int compare(Object a, Object b) {
        return Util.Email.compare_conversation_descending(
            a as Geary.App.Conversation,
            b as Geary.App.Conversation
        );
    }

    private bool insert_conversation(Geary.App.Conversation convo) {
        Geary.Email? last_email = convo.get_latest_recv_email(
            Geary.App.Conversation.Location.ANYWHERE);
        if (last_email == null)
            return false;
        items.add(convo);
        return true;
    }

    private void on_conversations_added(Gee.Collection<Geary.App.Conversation> conversations) {
        conversations_added(true);
        uint count_before = items.length;
        foreach (var convo in conversations) {
            insert_conversation(convo);
        }
        items.sort(compare);
        if (items.length != count_before) {
            this.items_changed(0, count_before, items.length);
        }
        conversations_added(false);
    }

    private void on_conversations_removed(Gee.Collection<Geary.App.Conversation> conversations) {
        conversations_removed(true);
        var to_remove = new Gee.ArrayList<uint>();
        foreach (var convo in conversations) {
            for (uint i = 0; i < items.length; i++) {
                if (items.get(i) == convo) {
                    to_remove.add(i);
                    break;
                }
            }
        }
        to_remove.sort((a, b) => (int)(b - a)); // Remove from end first
        foreach (var idx in to_remove) {
            items.remove_index(idx);
            this.items_changed(idx, 1, 0);
        }
        conversations_removed(false);
    }

    private void on_conversation_appended(Geary.App.ConversationMonitor sender,
                                          Geary.App.Conversation convo,
                                          Gee.Collection<Geary.Email> emails) {
        conversation_updated(convo);
    }

    private void on_conversation_trimmed(Geary.App.ConversationMonitor sender,
                                         Geary.App.Conversation convo,
                                         Gee.Collection<Geary.Email> emails) {
        conversation_updated(convo);
    }

    private void on_scan_completed(Geary.App.ConversationMonitor source) {
        scans_pending--;
        if (scans_pending <= 0) {
            scans_pending = 0;
            GLib.Timeout.add(100, () => {
                conversations_loaded();
                return false;
            });
        }
    }
}
