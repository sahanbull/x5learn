import { ActionType, ActionTypes, logAction } from 'app/api/actionLogging';

type Log = (action: ActionType, params: Record<string, unknown>) => unknown;

/** Tracks a single video instance, including players without seek callbacks. */
export class VideoPlaybackTracker {
  private position = 0;
  private observedAt = 0;
  private playing = false;
  private initialized = false;
  private rate = 1;
  private seekFrom: number | null = null;
  private initialTarget: number | null = null;

  constructor(
    private context: Record<string, unknown>,
    private log: Log = logAction,
    private now: () => number = Date.now,
  ) {}

  initialize(position: number) {
    this.position = position;
    this.initialized = true;
    this.observedAt = this.now();
  }

  setStartPosition(position: number) {
    this.initialize(position);
    this.initialTarget = position > 0 ? position : null;
  }

  play(position: number, detectSeek = false) {
    if (this.initialTarget !== null) {
      this.initialize(position);
      this.initialTarget = null;
    }
    this.progress(position, detectSeek);
    if (!this.playing) {
      this.playing = true;
      this.log(ActionTypes.VIDEO_PLAYED, {
        ...this.context,
        time: position,
      });
    }
  }

  pause(position: number, detectSeek = false) {
    this.progress(position, detectSeek);
    if (this.playing) {
      this.playing = false;
      this.log(ActionTypes.VIDEO_PAUSED, {
        ...this.context,
        time: position,
      });
    }
  }

  end(position: number) {
    this.initialize(position);
    this.playing = false;
  }

  setRate(rate: number) {
    this.rate = rate;
  }

  beginSeek() {
    if (this.seekFrom === null) this.seekFrom = this.position;
  }

  seek(position: number) {
    const from = this.seekFrom ?? this.position;
    const initialSeek =
      this.initialTarget !== null &&
      Math.abs(position - this.initialTarget) < 1;
    this.initialTarget = null;
    this.seekFrom = null;
    this.initialize(position);
    if (!initialSeek && Math.abs(position - from) > 0.01) {
      this.log(ActionTypes.VIDEO_SEEKED, {
        ...this.context,
        from,
        to: position,
      });
    }
  }

  progress(position: number, detectSeek = false) {
    if (this.seekFrom !== null || !Number.isFinite(position)) return;
    if (this.initialTarget !== null) {
      if (Math.abs(position - this.initialTarget) < 1) {
        this.initialTarget = null;
      }
      this.initialize(position);
      return;
    }
    const elapsed = Math.max(0, (this.now() - this.observedAt) / 1000);
    const advance = this.playing ? elapsed * this.rate : 0;
    // Allow normal playback, buffering, rate changes and delayed timer ticks.
    // YouTube does not emit onSeek, so infer jumps outside that range.
    if (
      detectSeek &&
      this.initialized &&
      (position < this.position - 1 || position > this.position + advance + 1)
    ) {
      this.seek(position);
      return;
    }
    this.initialize(position);
  }
}
