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
 * Base class for a break's activity tracking functionality.
 * A break can be started or stopped, and once started it will be activated
 * and finished either manually or autonomously based on user activity, or
 * some related metric. The mechanism for activating a break and for
 * satisfying it is unique to each implementation.
 * This class provides mechanisms for tracking and directly setting the
 * break's state, which can be either WAITING, ACTIVE, or DISABLED.
 */
public abstract class BreakController : Object {
	protected BreakType break_type;
	
	/**
	 * ''WAITING'':  The break has not started yet. For example, it may be
	 *               monitoring user activity in the background, waiting
	 *               until the user has been working for a particular
	 *               time.
	 * ''ACTIVE'':   The break has started. For example, when a break
	 *               becomes active, it might show a "Take a break"
	 *               screen. Once the break has been satisfied, it should
	 *               return to the WAITING state.
	 * ''DISABLED'': The break is not in use, and should not be monitoring
	 *               activity. This state is usually set explicitly by
	 *               BreakManager.
	*/
	public enum State {
		WAITING,
		ACTIVE,
		DISABLED
	}
	public State state {get; private set;}

	public enum FinishedReason {
		SKIPPED,
		SATISFIED
	}
	
	/** The break has been enabled. It will monitor user activity and emit activated() or finished() signals until it is disabled. */
	public signal void enabled();
	/** The break has been disabled. Its timers have been stopped and it will not do anything until it is enabled again. */
	public signal void disabled();

	/** The break is going to happen soon */
	public signal void warned();
	/** The break is no longer going to start soon */ 
	public signal void unwarned();
	
	/** The break has been activated and is now counting down aggressively until it is satisfied. */
	public signal void activated();
	/** The break has been satisfied. This can happen at any time, including while the break is waiting or after it has been activiated. */
	public signal void finished(BreakController.FinishedReason reason);
	
	public BreakController(BreakType break_type) {
		this.break_type = break_type;
		this.state = State.DISABLED;
	}
	
	/**
	 * Set whether the break is enabled or disabled. If it is enabled,
	 * it will periodically update in the background, and if it is
	 * disabled it will do nothing (and consume fewer resources).
	 * This will also emit the enabled() or disabled() signal.
	 * @param enable True to enable the break, false to disable it
	 */
	public void set_enabled(bool enable) {
		if (enable && ! this.is_enabled()) {
			this.state = State.WAITING;
			this.enabled();
		} else if (this.is_enabled()) {
			this.state = State.DISABLED;
			this.disabled();
		}
	}
	
	/**
	 * @return true if the break is enabled and waiting to start automatically
	 */
	public bool is_enabled() {
		return this.state != State.DISABLED;
	}
	
	/**
	 * @return true if the break has been activated, is in focus, and expects to be satisfied
	 */
	public bool is_active() {
		return this.state == State.ACTIVE;
	}
	
	/**
	 * Start a break. This is usually triggered automatically by the break
	 * controller itself, but it may be triggered externally as well.
	 */
	public void activate() {
		if (this.state < State.ACTIVE) {
			this.state = State.ACTIVE;
			this.activated();
		}
	}
	
	/**
	 * The break's requirements have been satisfied. Start counting from
	 * the beginning again.
	 */
	public void finish() {
		this.state = State.WAITING;
		this.finished(BreakController.FinishedReason.SATISFIED);
	}

	/**
	 * We're skipping this break. The BreakController should act as if the
	 * break has finished as usual, but we will send a different
	 * FinishedReason to the "finished" signal. This way, its BreakView will
	 * know to present this differently than if the break has actually been
	 * satisfied.
	 */
	public void skip() {
		this.state = State.WAITING;
		this.finished(BreakController.FinishedReason.SKIPPED);
	}
}
