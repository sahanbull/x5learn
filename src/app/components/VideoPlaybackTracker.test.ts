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
    [
      ActionTypes.VIDEO_PLAYED,
      { oer_id: 12, playlist_id: 7, positionInSeconds: 0 },
    ],
    [
      ActionTypes.VIDEO_PAUSED,
      { oer_id: 12, playlist_id: 7, positionInSeconds: 5 },
    ],
    [
      ActionTypes.VIDEO_PLAYED,
      { oer_id: 12, playlist_id: 7, positionInSeconds: 5 },
    ],
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
      { oer_id: 12, playlist_id: 7, positionInSeconds: 40, from: 10, to: 40 },
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
    [
      ActionTypes.VIDEO_SEEKED,
      { oer_id: 12, playlist_id: 7, positionInSeconds: 50, from: 2, to: 50 },
    ],
    [
      ActionTypes.VIDEO_SEEKED,
      { oer_id: 12, playlist_id: 7, positionInSeconds: 8, from: 50, to: 8 },
    ],
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
  expect(
    log.mock.calls.some(([type]) => type === ActionTypes.VIDEO_SEEKED),
  ).toBe(false);
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
    [
      ActionTypes.VIDEO_PLAYED,
      { oer_id: 12, playlist_id: 7, positionInSeconds: 90 },
    ],
    [ActionTypes.VIDEO_PLAYED, { oer_id: 13, positionInSeconds: 0 }],
  ]);
});

it('keeps fractional seconds for pauses and forward/backward seeks', () => {
  const { tracker, log } = setup();
  tracker.play(0);
  tracker.pause(3.976099);
  tracker.seek(360.831325);
  tracker.seek(1.234567);
  expect(log).toHaveBeenCalledWith(ActionTypes.VIDEO_PAUSED, {
    oer_id: 12,
    playlist_id: 7,
    positionInSeconds: 3.976099,
  });
  expect(log).toHaveBeenCalledWith(ActionTypes.VIDEO_SEEKED, {
    oer_id: 12,
    playlist_id: 7,
    positionInSeconds: 360.831325,
    from: 3.976099,
    to: 360.831325,
  });
  expect(log).toHaveBeenCalledWith(ActionTypes.VIDEO_SEEKED, {
    oer_id: 12,
    playlist_id: 7,
    positionInSeconds: 1.234567,
    from: 360.831325,
    to: 1.234567,
  });
});

it('reports continuing playback every ten seconds, skipping paused and stalled playback', () => {
  const { tracker, log, tick } = setup();
  tracker.play(0);
  tick(9);
  tracker.progress(9);
  expect(log).toHaveBeenCalledTimes(1);
  tick(1);
  tracker.progress(10.186097);
  tracker.progress(10.186097);
  tick(10);
  tracker.progress(10.186097);
  tracker.pause(10.186097);
  tick(10);
  tracker.progress(10.186097);
  tracker.play(10.186097);
  tick(10);
  tracker.progress(20.186097);
  expect(
    log.mock.calls.filter(([type]) => type === ActionTypes.VIDEO_STILL_PLAYING),
  ).toEqual([
    [9, { oer_id: 12, playlist_id: 7, positionInSeconds: 10.186097 }],
    [9, { oer_id: 12, playlist_id: 7, positionInSeconds: 20.186097 }],
  ]);
});

it('ignores invalid playback positions', () => {
  const { tracker, log } = setup();
  [NaN, Infinity, -1].forEach(position => {
    tracker.play(position);
    tracker.pause(position);
    tracker.seek(position);
    tracker.progress(position, true);
  });
  expect(log).not.toHaveBeenCalled();
});
