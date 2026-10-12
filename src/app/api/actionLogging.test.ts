import {
  ActionTypes,
  logAction,
  logActions,
  playlistContext,
} from './actionLogging';
import { postAction, postActionsBulk } from './api';

jest.mock('./api', () => ({
  postAction: jest.fn(),
  postActionsBulk: jest.fn(),
}));

const post = postAction as jest.Mock;
const bulk = postActionsBulk as jest.Mock;

beforeEach(() => jest.clearAllMocks());
afterEach(() => jest.restoreAllMocks());

it('sends JSON-string params through the authenticated action API', async () => {
  post.mockResolvedValue({ result: 'Action logged' });
  await logAction(ActionTypes.PLAYLIST_ITEM_PREVIOUS, {
    ...playlistContext(7),
    oer_id: 12,
    from: 12,
    to: 13,
  });
  expect(post).toHaveBeenLastCalledWith({
    action_type_id: 18,
    is_bundled: false,
    params: JSON.stringify({
      playlist_type: 'published',
      playlist_id: 7,
      oer_id: 12,
      from: 12,
      to: 13,
    }),
  });
});

it('sends resource and video params using the supplied oerId key', async () => {
  post.mockResolvedValue({ result: 'Action logged' });
  await logAction(ActionTypes.VIDEO_PAUSED, {
    oer_id: 12,
    positionInSeconds: 3.976099,
  });
  expect(post).toHaveBeenLastCalledWith({
    action_type_id: 5,
    is_bundled: false,
    params: '{"positionInSeconds":3.976099,"oerId":12}',
  });
  await logAction(ActionTypes.OER_FEEDBACK, {
    oer_id: 31,
    'user feedback': '>>>Inspiring',
  });
  expect(JSON.parse(post.mock.calls[1][0].params)).toEqual({
    'OER id': 31,
    'user feedback': '>>>Inspiring',
  });
});

it('skips events whose existing backend IDs have not been configured', async () => {
  await logAction(undefined, { text: 'brain' });
  await logActions([{ actionType: undefined, params: {} }]);
  expect(post).not.toHaveBeenCalled();
  expect(bulk).not.toHaveBeenCalled();
});

it('sends bulk arrays in matching order without an is_bundled flag', async () => {
  bulk.mockResolvedValue({ result: 'Actions logged' });
  await logActions([
    { actionType: ActionTypes.OER_OPENED, params: { oerId: 42 } },
    { actionType: ActionTypes.PDF_OPENED, params: {} },
  ]);
  expect(bulk).toHaveBeenCalledWith({
    action_type_ids: [1, 17],
    params_list: ['{"oerId":42}', '{}'],
  });
  expect(post).not.toHaveBeenCalled();
});

it('skips empty batches and absorbs bulk failures', async () => {
  await logActions([]);
  expect(bulk).not.toHaveBeenCalled();
  const error = jest.spyOn(console, 'error').mockImplementation(() => {});
  bulk.mockRejectedValue(new Error('Offline'));
  await expect(
    logActions([
      {
        actionType: ActionTypes.VIDEO_PAUSED,
        params: { oerId: 42, positionInSeconds: 3.976099 },
      },
    ]),
  ).resolves.toBeUndefined();
  expect(error).toHaveBeenCalledTimes(1);
  bulk.mockRejectedValue({ message: { status: 401 } });
  await logActions([{ actionType: ActionTypes.OER_OPENED, params: {} }]);
  expect(error).toHaveBeenCalledTimes(1);
});

it('absorbs logging failures so playback and navigation can continue', async () => {
  const error = jest.spyOn(console, 'error').mockImplementation(() => {});
  post.mockRejectedValue(new Error('Offline'));
  await expect(
    logAction(ActionTypes.VIDEO_PLAYED, { oer_id: 12 }),
  ).resolves.toBeUndefined();
  expect(error).toHaveBeenCalledTimes(1);
});

it('silently skips unauthorized visitors', async () => {
  const error = jest.spyOn(console, 'error').mockImplementation(() => {});
  post.mockRejectedValue({ message: { status: 401 } });
  await logAction(ActionTypes.OER_OPENED, { oer_id: 12 });
  expect(error).not.toHaveBeenCalled();
});

it('uses the temporary title as the identifier for temporary playlists', () => {
  expect(playlistContext(null, 'My playlist')).toEqual({
    playlist_type: 'temporary',
    temp_title: 'My playlist',
  });
  expect(playlistContext()).toEqual({});
});
