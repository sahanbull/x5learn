import { ActionTypes, logAction, playlistContext } from './actionLogging';
import { postAction } from './api';

jest.mock('./api', () => ({ postAction: jest.fn() }));

const post = postAction as jest.Mock;

afterEach(() => jest.restoreAllMocks());

it('sends JSON-string params through the authenticated action API', async () => {
  post.mockResolvedValue({ result: 'Action logged' });
  await logAction(ActionTypes.PLAYLIST_ITEM_SKIPPED, {
    ...playlistContext(7),
    oer_id: 12,
    from: 12,
    to: 13,
  });
  expect(post).toHaveBeenLastCalledWith({
    action_type_id: 17,
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
