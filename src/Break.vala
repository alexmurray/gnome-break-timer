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
 * Base class for a type of break.
 * A break inherently activates according to a set time interval, but the
 * mechanism for finishing a break is unique to each implementation.
 */
public abstract class Break : Object {
	private BreakManager manager;
	private BreakManager.FocusRequest focus_request;
	private BreakManager.FocusPriority priority;
	
	public enum State {
		WAITING,
		ACTIVE
	}
	public State state {get; private set;}
	private int interval;
	
	/** Called when a break starts to run */
	public signal void started();
	/** Called when a break is finished running */
	public signal void finished();
	
	private Timer start_timer;
	
	public Break(BreakManager manager, BreakManager.FocusPriority priority, int interval) {
		this.manager = manager;
		this.priority = priority;
		this.interval = interval;
		
		this.start_timer = new Timer();
		Timeout.add_seconds(this.interval, this.start_timeout);
	}
	
	protected void request_focus(BreakManager.FocusPriority priority) {
		if (this.focus_request == null) {
			this.focus_request = new BreakManager.FocusRequest(this, priority, this.focus_start_cb, this.focus_stop_cb);
			this.manager.request_focus(focus_request);
		}
	}
	
	protected void release_focus() {
		if (this.focus_request != null) {
			this.manager.release_focus(this.focus_request);
			this.focus_request = null;
		}
	}
	
	private void focus_start_cb() {
		this.started();
	}
	
	private void focus_stop_cb(bool replaced) {
		this.finished();
	}
	
	public int starts_in() {
		return this.interval - (int)this.start_timer.elapsed();
	}
	
	/**
	 * Periodically tests if it is time for a break
	 */
	private bool start_timeout() {
		/* Start break if the user has been active for interval */
		if (this.start_timer.elapsed() >= this.interval && this.state == State.WAITING) {
			stdout.printf("Activating break %s!\n", this.get_type().name());
			this.activate();
		}
		
		return true;
	}
	
	/**
	 * The break has been satisfied somehow. Start timer will reset
	 */
	protected void break_satisfied() {
		this.start_timer.start();
		this.release_focus();
	}
	
	/**
	 * It is time for a break!
	 */
	public void activate() {
		if (this.state != State.ACTIVE) {
			this.state = State.ACTIVE;
			this.request_focus(this.priority);
		}
	}
	
	/**
	 * Force the break to end.
	 */
	public void end() {
		if (this.state != State.WAITING) {
			this.state = State.WAITING;
			this.break_satisfied();
		}
	}
}

