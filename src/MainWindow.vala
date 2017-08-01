/*
* Copyright (c) 2017 Ricky Bassom (https://github.com/rickybas)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
*/

public struct Countdown {
    int id;
    string title;
    int end_date;
    int start_date;
}

public class MainWindow : Gtk.Dialog {
    public GenericArray<Countdown?> countdowns { get; private set; }
    public string data_file { get; construct set; }

    public Gtk.FlowBox grid { get; construct set; }
    public Gtk.Popover create_popover { get; construct set; }

    public Gtk.Entry new_title_entry { get; construct set; }
    public DatePicker new_end_date_entry { get; construct set; }
    public DatePicker new_start_date_entry { get; construct set; }
    public Gtk.Button new_create_button { get; construct set; }
    public Gtk.Revealer new_warning_rev { get; construct set; }
    public Gtk.Label new_warning_label { get; construct set; }

    public new Gtk.Button add_button { get; construct set; }

    public bool editing { get; set; default = false; }
    public bool creating { get; set; default = false; }

    private const int seconds_in_min = 86400;
    private const int refresh_time = 300000; // 5 min
    private const int pbar_size = 105;
    private const string pbar_progress_color = "#4a90d9";
    private const string pbar_complete_color = "#ed5353";

    public MainWindow (Gtk.Application application) {
        Object (application: application,
                icon_name: "com.github.rickybas.date-countdown",
                resizable: false,
                title: "Date Countdown");
    }

    construct {
        set_keep_below (true);
        stick ();
        valign = Gtk.Align.START;
        halign = Gtk.Align.START;

        var home_dir = Environment.get_home_dir ();
        data_file = home_dir + "/.countdowns.txt";

        grid = new Gtk.FlowBox ();
        grid.valign = Gtk.Align.START;
        grid.set_min_children_per_line (5);
        grid.set_max_children_per_line (5);
        grid.set_selection_mode (Gtk.SelectionMode.NONE);
        grid.can_focus = false;
        grid.button_press_event.connect ((e) => {
            if (e.button == Gdk.BUTTON_PRIMARY) {
                begin_move_drag ((int) e.button, (int) e.x_root, (int) e.y_root, e.time);
                return true;
            }
            return false;
        });

        draw_countdowns ();

        add_button = new Gtk.Button.with_label (_("Add"));
        add_button.margin = 4;
        add_button.halign = Gtk.Align.CENTER;
        add_button.clicked.connect (() => {
            creating = true;
            new_title_entry.text = "";

            var now_date = new DateTime.from_unix_local ((int) get_time_now ().to_unix ());
            var future_date = new DateTime.from_unix_local ((int) get_time_now ().add_days (1).to_unix ());

            new_end_date_entry.calendar.select_day (future_date.get_day_of_month ());
            new_end_date_entry.calendar.select_month (future_date.get_month ()-1, future_date.get_year ());

            new_start_date_entry.calendar.select_day (now_date.get_day_of_month ());
            new_start_date_entry.calendar.select_month (now_date.get_month ()-1, now_date.get_year ());

            new_end_date_entry.date = future_date;
            new_start_date_entry.date = now_date;
            create_popover.visible = true;
        });

        new_warning_rev = new Gtk.Revealer ();
        new_warning_rev.reveal_child = false;
        new_warning_rev.set_transition_type (Gtk.RevealerTransitionType.SLIDE_DOWN);
        new_warning_label = new Gtk.Label ("");
        new_warning_label.get_style_context ().add_class ("warning");
        new_warning_rev.add (new_warning_label);

        new_title_entry = new Gtk.Entry ();
        new_title_entry.placeholder_text = _("Title");
        new_end_date_entry = new DatePicker ();
        new_start_date_entry = new DatePicker ();

        new_create_button = new Gtk.Button.with_label (_("Create"));
        new_create_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        new_create_button.clicked.connect (() => {
            var validate = validate_input (new_title_entry.text,
                (int) new_end_date_entry.date.to_unix (), (int) new_start_date_entry.date.to_unix ());
            if (validate == null) {
                add_countdown (new_title_entry.text, new_end_date_entry.date.to_unix (),
                    new_start_date_entry.date.to_unix ());
                create_popover.visible = false;
                draw_countdowns ();
            } else {
                new_warning_label.label = validate;
                new_warning_rev.reveal_child = true;
            }
        });

        create_popover = new Gtk.Popover (add_button);
        // create_popover.constrain_to = Gtk.PopoverConstraint.NONE;
        create_popover.position = Gtk.PositionType.TOP;
        var create_popover_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 8);
        create_popover_box.add (new_warning_rev);
        create_popover_box.add (new Gtk.Label (_("Title: ")));
        create_popover_box.add (new_title_entry);
        create_popover_box.add (new Gtk.Label (_("Enter start date: ")));
        create_popover_box.add (new_start_date_entry);
        create_popover_box.add (new Gtk.Label (_("Enter end date: ")));
        create_popover_box.add (new_end_date_entry);
        create_popover_box.add (new_create_button);
        create_popover_box.show_all ();
        create_popover.add (create_popover_box);

        create_popover.closed.connect (() => {
            creating = false;
            new_warning_label.label = "";
            new_warning_rev.reveal_child = false;
        });

        var content_box = get_content_area () as Gtk.Box;
        content_box.border_width = 0;
        content_box.pack_start (grid, true, true, 0);
        content_box.pack_end (add_button, false, false, 0);
        content_box.show_all ();

        button_press_event.connect ((e) => {
            if (e.button == Gdk.BUTTON_PRIMARY && !editing && !creating) {
                begin_move_drag ((int) e.button, (int) e.x_root, (int) e.y_root, e.time);
                return true;
            }
            return false;
        });

        Timeout.add (refresh_time, () => {
            if (!editing) draw_countdowns ();
            return true;
        });
    }

    private void draw_countdowns () {
        grid.forall ((element) => grid.remove (element));
        load_countdowns ();

        if (countdowns.length == 0){
            grid.margin = 130;
        } else {
            grid.margin = 0;
        }

        countdowns.foreach ((countdown) => {
            var countdown_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            if (countdowns.length == 1){
                countdown_box.margin = 8;
                countdown_box.margin_left = 130;
                countdown_box.margin_right = 130;
            } else {
                countdown_box.margin = 8;
            }

            var pbar = new CircularProgressWidgets.CircularProgressBar ();
            pbar.line_cap = Cairo.LineCap.ROUND;
            pbar.margin = 8;
            pbar.width_request = pbar_size;
            pbar.height_request = pbar_size;
            pbar.line_width = 8;

            var title_label = new Gtk.Label (countdown.title);
            title_label.get_style_context ().add_class ("countdown-title");
            title_label.margin_bottom = 6;
            title_label.max_width_chars = 20;
            title_label.ellipsize = Pango.EllipsizeMode.END;
            title_label.set_tooltip_text (countdown.title);

            int days_remaining = unix_to_days (countdown.end_date - (int) get_time_now ().to_unix ());
            int days_finished = unix_to_days (countdown.end_date - countdown.start_date) - days_remaining;

            pbar.percentage = (double) days_finished / (days_remaining + days_finished);
            countdown_box.add (pbar);
            countdown_box.add (title_label);

            if (pbar.percentage >= 1.0) { // if completed
                pbar.progress_fill_color = pbar_complete_color;
                var completed_label = new Gtk.Label ("Completed");
                completed_label.get_style_context ().add_class ("info-text");
                countdown_box.add (completed_label);
            } else {
                pbar.progress_fill_color = pbar_progress_color;

                var days_remaining_label = new Gtk.Label (
                    "<b>" + _("Days remaining: ") + "</b>" + days_remaining.to_string ());
                days_remaining_label.set_use_markup (true);
                days_remaining_label.get_style_context ().add_class ("info-text");

                var days_finished_label = new Gtk.Label (
                    "<b>" + _("Days finished: ") + "</b>" + days_finished.to_string ());
                days_finished_label.set_use_markup (true);
                days_finished_label.get_style_context ().add_class ("info-text");

                countdown_box.add (days_remaining_label);
                countdown_box.add (days_finished_label);
            }

            var event_box = new Gtk.EventBox ();
            event_box.add (countdown_box);
            event_box.button_release_event.connect ((e) => {
                if (e.button == Gdk.BUTTON_SECONDARY) {
                    editing = true;

                    var edit_warning_rev = new Gtk.Revealer ();
                    edit_warning_rev.reveal_child = false;
                    edit_warning_rev.set_transition_type (Gtk.RevealerTransitionType.SLIDE_DOWN);
                    var edit_warning_label = new Gtk.Label ("");
                    edit_warning_label.get_style_context ().add_class ("warning");
                    edit_warning_rev.add (edit_warning_label);

                    Gtk.Popover edit_popover = new Gtk.Popover (pbar);
                    // edit_popover.constrain_to = Gtk.PopoverConstraint.NONE;
                    edit_popover.position = Gtk.PositionType.RIGHT;
                    edit_popover.closed.connect (() => {
                        editing = false;
                        edit_popover.visible = false;
                        edit_warning_label.label = "";
                        edit_warning_rev.reveal_child = false;
                    });
                    var edit_popover_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 8);

                    var edit_button = new Gtk.Button.with_label (_("Save changes"));
                    edit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
                    var remove_button = new Gtk.Button.with_label (_("Remove"));
                    remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                    remove_button.margin_top = 16;

                    var edit_title_entry = new Gtk.Entry ();
                    edit_title_entry.placeholder_text = _("Title");
                    var edit_end_date_entry = new DatePicker ();
                    var edit_start_date_entry = new DatePicker ();

                    var end_date = new DateTime.from_unix_local (countdown.end_date);
                    var start_date = new DateTime.from_unix_local (countdown.start_date);

                    edit_end_date_entry.calendar.select_day (end_date.get_day_of_month ());
                    edit_end_date_entry.calendar.select_month (end_date.get_month ()-1, end_date.get_year ());

                    edit_start_date_entry.calendar.select_day (start_date.get_day_of_month ());
                    edit_start_date_entry.calendar.select_month (start_date.get_month ()-1, start_date.get_year ());

                    edit_title_entry.text = countdown.title;
                    edit_end_date_entry.date = end_date;
                    edit_start_date_entry.date = start_date;

                    edit_button.clicked.connect (() => {
                        var validate = validate_input (edit_title_entry.text,
                            (int) edit_end_date_entry.date.to_unix (), (int) edit_start_date_entry.date.to_unix ());
                        if (validate == null) {
                            edit_countdown (countdown.id, edit_title_entry.text,
                                edit_end_date_entry.date.to_unix (), edit_start_date_entry.date.to_unix ());
                            draw_countdowns ();
                            edit_popover.visible = false;
                        } else {
                            edit_warning_label.label = validate;
                            edit_warning_rev.reveal_child = true;
                        }
                    });

                    remove_button.clicked.connect (() => {
                        editing = false;
                        remove_countdown (countdown.id);
                        draw_countdowns ();
                    });

                    edit_popover_box.add (edit_warning_rev);
                    edit_popover_box.add (new Gtk.Label (_("Title: ")));
                    edit_popover_box.add (edit_title_entry);
                    edit_popover_box.add (new Gtk.Label (_("Start date: ")));
                    edit_popover_box.add (edit_start_date_entry);
                    edit_popover_box.add (new Gtk.Label (_("End date: ")));
                    edit_popover_box.add (edit_end_date_entry);

                    edit_popover_box.add (edit_button);
                    edit_popover_box.add (remove_button);

                    edit_popover_box.show_all ();
                    edit_popover.add (edit_popover_box);
                    edit_popover.show_all ();
                }
                return true;
            });

            grid.add (event_box);
        });

        grid.forall ((element) => element.can_focus = false);

        grid.show_all ();
    }

    private string? validate_input (string title, int end_date, int start_date) {
        if (title == "") return _("Enter title");
        if (start_date >= end_date) return _("Start date is greater than end date");
        if (end_date < (int) get_time_now ().to_unix ()) return _("End date is smaller than current date");
        if (start_date > (int) get_time_now ().to_unix ()) return _("Start date is greater than current date");
        return null;
    }

    private File create_start_data_file_if_not_exists () {
        var file = File.new_for_path (data_file);

        if (!file.query_exists ()) {
            stderr.printf ("File '%s' doesn't exist.\n", file.get_path ());

            var now = get_time_now ();
            var future = now.add_days (3);
            try {
                file.create (FileCreateFlags.NONE);
            } catch (Error e) {
                error ("%s", e.message);
            }
            if (file.query_exists ()) {
                stdout.printf ("File successfully created.\n");
            }
            add_countdown (_("Welcome"), future.to_unix (), now.to_unix () - seconds_in_min); // minus a day off start date
        }

        return file;
    }

    private GenericArray<Countdown?> load_countdowns () {
        var file = create_start_data_file_if_not_exists ();

        countdowns = new GenericArray<Countdown?> ();

        try {
            // Open file for reading and wrap returned FileInputStream into a
            // DataInputStream, so we can read line by line
            var dis = new DataInputStream (file.read ());
            string line;
            int count = 0;
            // Read lines until end of file (null) is reached
            while ((line = dis.read_line (null)) != null) {
                countdowns.add (line_to_countdown (line, count));
                count++;
            }
        } catch (Error e) {
            error ("%s", e.message);
        }

        return countdowns;
    }

    private Countdown line_to_countdown (string line, int id) {
        string[] split = line.split (",", 3);
        return Countdown () {
            id = id,
            title = split[2],
            end_date = int.parse(split[0]),
            start_date = int.parse(split[1])
        };
    }

    private void add_countdown (string title, int64 end_date, int64 start_date) {
        create_start_data_file_if_not_exists ();
        string file_contents = "";
        try {
            FileUtils.get_contents (data_file, out file_contents);
            FileUtils.set_contents (data_file, file_contents + "%i,%i,%s".printf ((int) end_date, (int) start_date, title) + "\n");
        } catch (Error e) {
            error ("%s", e.message);
        }
    }

    private void edit_countdown (int id, string title, int64 end_date, int64 start_date) {
        var file = File.new_for_path (data_file);

        string new_file = "";

        try {
            // Open file for reading and wrap returned FileInputStream into a
            // DataInputStream, so we can read line by line
            var dis = new DataInputStream (file.read ());
            string line;
            int count = 0;
            // Read lines until end of file (null) is reached
            while ((line = dis.read_line (null)) != null) {
                if (count != id) {
                    new_file = new_file + line + "\n";
                } else {
                    new_file = new_file + "%i,%i,%s".printf ((int) end_date, (int) start_date, title) + "\n";
                }

                count++;
            }
        } catch (Error e) {
            error ("%s", e.message);
        }

        try {
            FileUtils.set_contents (data_file, new_file);
        } catch (Error e) {
            error ("%s", e.message);
        }
    }

    private void remove_countdown (int id) {
        var file = File.new_for_path (data_file);

        string new_file = "";

        try {
            // Open file for reading and wrap returned FileInputStream into a
            // DataInputStream, so we can read line by line
            var dis = new DataInputStream (file.read ());
            string line;
            int count = 0;
            // Read lines until end of file (null) is reached
            while ((line = dis.read_line (null)) != null) {
                if (count != id) new_file = new_file + line + "\n";

                count++;
            }
        } catch (Error e) {
            error ("%s", e.message);
        }

        try {
            FileUtils.set_contents (data_file, new_file);
        } catch (Error e) {
            error ("%s", e.message);
        }
    }

    private int unix_to_days (int unix_time) {
        int days = (int) Math.ceil ((double) unix_time / (double) seconds_in_min);
        return days;
    }

    private static DateTime get_time_now () {
        return new DateTime.now_local ();
    }
}
