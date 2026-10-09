import { postAction } from './api';

// These IDs are seeded by x5learn_server/action_logging.py.
export const ActionTypes = {
  OER_OPENED: 1,
  VIDEO_PLAYED: 4,
  VIDEO_PAUSED: 5,
  VIDEO_SEEKED: 6,
  USER_LOGIN: 15,
  PLAYLIST_OPENED: 16,
  PLAYLIST_ITEM_SKIPPED: 17,
  PLAYLIST_ITEM_PREVIOUS: 18,
  NOTE_ADDED: 19,
  TEMP_PLAYLIST_CREATED: 20,
  PLAYLIST_ITEM_ADDED: 21,
  PLAYLIST_PUBLISHED: 22,
  PLAYLIST_SHARE_LINK_COPIED: 23,
} as const;

export type ActionType = typeof ActionTypes[keyof typeof ActionTypes];

export async function logAction(
  actionType: ActionType,
  params: Record<string, unknown>,
): Promise<void> {
  try {
    await postAction({
      action_type_id: actionType,
      params: JSON.stringify(params),
      is_bundled: false,
    });
  } catch (error) {
    // Anonymous visitors have no user ID. Logging must not interrupt the UI.
    if ((error as any)?.message?.status !== 401) {
      console.error('Failed to log action', error);
    }
  }
}

export function playlistContext(
  playlistId?: string | number | null,
  tempTitle?: string | null,
) {
  return tempTitle
    ? { playlist_type: 'temporary', temp_title: tempTitle }
    : playlistId
    ? { playlist_type: 'published', playlist_id: Number(playlistId) }
    : {};
}
