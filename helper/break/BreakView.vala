/*
 * This file is part of Brain Break.
 * 
 * Brain Break is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * Brain Break is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with Brain Break.  If not, see <http://www.gnu.org/licenses/>.
 */

public interface IBreakOverlaySource : Object {
	// TODO: background image, class name for StyleContext
	public signal void overlay_started();
	public signal void overlay_stopped();
	
	public signal void request_attention();
	
	public abstract string get_overlay_title();
	public abstract Gtk.Widget get_overlay_content();
}

public abstract class BreakView : Object, IBreakOverlaySource {
	protected BreakModel model {get; private set;}
	protected FocusPriority priority;
	
	public signal void focus_requested(FocusPriority priority);
	public signal void focus_released();
	
	public string title {get; protected set;}
	
	public struct NotificationContent {
		public string summary;
		public string? body;
		public string? icon;
	}
	
	public BreakView(BreakModel model, FocusPriority priority) {
		this.model = model;
		this.priority = priority;
		
		model.activated.connect(this.request_focus_cb);
		model.finished.connect(this.release_focus_cb);
		model.disabled.connect(this.release_focus_cb);
	}
	
	private void request_focus_cb() {
		this.request_focus();
	}
	private void release_focus_cb() {
		this.release_focus();
	}
	
	protected void request_focus(FocusPriority? priority = null) {
		if (priority == null) priority = this.priority;
		this.focus_requested(priority);
	}
	
	protected void release_focus() {
		this.focus_released();
	}
	
	public abstract string get_status_message();
	
	public abstract NotificationContent get_start_notification();
	public abstract NotificationContent get_finish_notification();
	public abstract int get_lead_in_seconds();
	
	/***** IBreakOverlaySource interface ******/
	
	public string get_overlay_title() {
		return this.title;
	}
	
	public abstract Gtk.Widget get_overlay_content();
}

