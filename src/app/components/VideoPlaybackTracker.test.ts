import { ActionTypes } from 'app/api/actionLogging';
import { VideoPlaybackTracker } from './VideoPlaybackTracker';

jest.mock('app/api/actionLogging', () => ({
  ...jest.requireActual('app/api/actionLogging'),
  logAction: jest.fn(),
}));

function setup() {
  const log = jest.fn();
  let clock = 1000;
  const tracker = new VideoPlaybackTracker(
    { oer_id: 12, playlist_id: 7 },
    log,
    () => clock,
  );
  tracker.initialize(0);
  return { tracker, log, tick: (seconds: number) => (clock += seconds * 1000) };
}

it('records play/resume and pause once per state change with resource context', () => {
  const { tracker, log, tick } = setup();
  tracker.play(0);
  tracker.play(0);
  tick(5);
  tracker.progress(5);
  tracker.pause(5);
  tracker.pause(5);
  tracker.play(5);
  expect(log.mock.calls).toEqual([
    [ActionTypes.VIDEO_PLAYED, { oer_id: 12, playlist_id: 7, time: 0 }],
    [ActionTypes.VIDEO_PAUSED, { oer_id: 12, playlist_id: 7, time: 5 }],
    [ActionTypes.VIDEO_PLAYED, { oer_id: 12, playlist_id: 7, time: 5 }],
  ]);
});

it('keeps the original native seek position while progress callbacks fire', () => {
  const { tracker, log } = setup();
  tracker.initialize(10);
  tracker.beginSeek();
  tracker.progress(40);
  tracker.beginSeek();
  tracker.seek(40);
  tracker.seek(40);
  expect(log.mock.calls).toEqual([
    [
      ActionTypes.VIDEO_SEEKED,
      { oer_id: 12, playlist_id: 7, from: 10, to: 40 },
    ],
  ]);
});

it('infers forward and backward YouTube seeks while playing and paused', () => {
  const { tracker, log, tick } = setup();
  tracker.play(0, true);
  tick(2);
  tracker.progress(2, true);
  tick(0.25);
  tracker.progress(50, true);
  tracker.pause(50, true);
  tick(4);
  tracker.progress(8, true);
  expect(
    log.mock.calls.filter(([type]) => type === ActionTypes.VIDEO_SEEKED),
  ).toEqual([
    [ActionTypes.VIDEO_SEEKED, { oer_id: 12, playlist_id: 7, from: 2, to: 50 }],
    [ActionTypes.VIDEO_SEEKED, { oer_id: 12, playlist_id: 7, from: 50, to: 8 }],
  ]);
});

it('handles long polling gaps, buffering and playback rate without false seeks', () => {
  const { tracker, log, tick } = setup();
  tracker.play(0, true);
  tracker.setRate(2);
  tick(20);
  tracker.progress(40, true);
  tick(10);
  tracker.progress(40, true);
  tick(1);
  tracker.progress(42, true);
  expect(log).toHaveBeenCalledTimes(1);
});

it('ignores configured start positions and resets independently between videos', () => {
  const { tracker, log } = setup();
  tracker.setStartPosition(90);
  tracker.progress(0, true);
  tracker.seek(90);
  tracker.play(90, true);
  tracker.end(100);
  tracker.pause(100);
  const second = new VideoPlaybackTracker({ oer_id: 13 }, log);
  second.initialize(0);
  second.play(0);
  expect(log.mock.calls).toEqual([
    [ActionTypes.VIDEO_PLAYED, { oer_id: 12, playlist_id: 7, time: 90 }],
    [ActionTypes.VIDEO_PLAYED, { oer_id: 13, time: 0 }],
  ]);
});
