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

/**
 * A wrapper around GLib's Timeout functionality, specifically intended for
 * timeouts that persist. The TimeoutCB callback can be stopped and started at
 * any time, and it is provided with the time since its last call.
 */
public class CleverTimeout : Object {
	public delegate void TimeoutCB(CleverTimeout timeout, int delta_millisecs);
	
	private unowned TimeoutCB timeout_cb;
	private int frequency;
	private uint source_id;
	private int64 last_time;
	
	public CleverTimeout(TimeoutCB callback, int frequency) {
		this.timeout_cb = callback;
		this.frequency = frequency;
	}
	
	private bool timeout_wrapper() {
		int64 now = get_monotonic_time();
		int64 time_delta = now - this.last_time;
		this.last_time = now;
		
		int delta_millisecs = (int) (time_delta / 1000);
		this.timeout_cb(this, delta_millisecs);
		
		return true;
	}
	
	public void start() {
		if (this.is_running()) {
			Source.remove(this.source_id);
		}
		
		this.last_time = get_monotonic_time();
		
		this.source_id = Timeout.add_seconds(this.frequency, this.timeout_wrapper);
	}
	
	public void set_frequency(int frequency) {
		this.frequency = frequency;
		if (this.is_running()) {
			this.start();
		}
	}
	
	public void stop() {
		if (this.is_running()) {
			Source.remove(this.source_id);
			this.source_id = 0;
		}
	}
	
	public bool is_running() {
		return this.source_id > 0;
	}
}
