/*
* Copyright (c) 2018 Alecaddd (http://alecaddd.com)
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
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/
public class Akira.Layouts.Partials.LayersPanel : Gtk.ListBox {
	public weak Akira.Window window { get; construct; }

	private bool scroll_up = false;
	private bool scrolling = false;
	private bool should_scroll = false;
	public Gtk.Adjustment vadjustment;

	private const int SCROLL_STEP_SIZE = 5;
	private const int SCROLL_DISTANCE = 30;
	private const int SCROLL_DELAY = 50;

	private const Gtk.TargetEntry targetEntries[] = {
		{ "ARTBOARD", Gtk.TargetFlags.SAME_APP, 0 }
	};

	public LayersPanel (Akira.Window main_window) {
		Object (
			window: main_window,
			activate_on_single_click: false,
			selection_mode: Gtk.SelectionMode.SINGLE
		);
	}

	construct {
		get_style_context ().add_class ("sidebar-r");

		var artboard = new Akira.Layouts.Partials.Artboard (window, "Artboard 1");
		artboard.container.attach (new Akira.Layouts.Partials.Layer (window, "Rectangle", "/com/github/alecaddd/akira/tools/rectangle.svg"), 0, 0, 1, 1);
		artboard.container.attach (new Akira.Layouts.Partials.Layer (window, "Circle", "/com/github/alecaddd/akira/tools/circle.svg"), 0, 1, 1, 1);
		artboard.container.attach (new Akira.Layouts.Partials.Layer (window, "Triangle", "/com/github/alecaddd/akira/tools/triangle.svg"), 0, 2, 1, 1);

		var artboard2 = new Akira.Layouts.Partials.Artboard (window, "Artboard 2");
		var artboard3 = new Akira.Layouts.Partials.Artboard (window, "Artboard 3");

		insert (artboard, 0);
		insert (artboard2, 1);
		insert (artboard3, 2);

		row_activated.connect (on_row_activated);
		build_drag_and_drop ();
	}

	private void on_row_activated (Gtk.ListBoxRow row) {
		warning (row.name);
	}

	private void build_drag_and_drop () {
		Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, targetEntries, Gdk.DragAction.MOVE);

		drag_data_received.connect (on_drag_data_received);
		drag_motion.connect (on_drag_motion);
		drag_leave.connect (on_drag_leave);
	}

	private void on_drag_data_received (Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint target_type, uint time) {
		Akira.Layouts.Partials.Artboard target;
		Gtk.Widget row;
		Akira.Layouts.Partials.Artboard source;
		int newPos;
		int oldPos;

		target = (Akira.Layouts.Partials.Artboard) get_row_at_y (y);

		newPos = target.get_index ();
		row = ((Gtk.Widget[]) selection_data.get_data ())[0];

		if (! (row is Akira.Layouts.Partials.Artboard)) {
			return;
		}

		source = (row as Akira.Layouts.Partials.Artboard);
		oldPos = source.get_index ();

		if (source == target) {
			return;
		}

		remove (source);
		insert (source, newPos);
	}

	public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
		this.get_style_context ().add_class ("highlight-drop-area");

		check_scroll (y);
		if (should_scroll && !scrolling) {
			scrolling = true;
			Timeout.add (SCROLL_DELAY, scroll);
		}

		return true;
	}

	public void on_drag_leave (Gdk.DragContext context, uint time) {
		this.get_style_context ().remove_class ("highlight-drop-area");
	}

	private void check_scroll (int y) {
		vadjustment = window.main_window.right_sidebar.layers_scroll.vadjustment;

		if (vadjustment == null) {
			return;
		}

		double vadjustment_min = vadjustment.value;
		double vadjustment_max = vadjustment.page_size + vadjustment_min;
		double show_min = double.max (0, y - SCROLL_DISTANCE);
		double show_max = double.min (vadjustment.upper, y + SCROLL_DISTANCE);

		if (vadjustment_min > show_min) {
			should_scroll = true;
			scroll_up = true;
		} else if (vadjustment_max < show_max) {
			should_scroll = true;
			scroll_up = false;
		} else {
			should_scroll = false;
		}
	}

	private bool scroll () {
		if (should_scroll) {
			if (scroll_up) {
				vadjustment.value -= SCROLL_STEP_SIZE;
			} else {
				vadjustment.value += SCROLL_STEP_SIZE;
			}
		} else {
			scrolling = false;
		}

		return should_scroll;
	}
}