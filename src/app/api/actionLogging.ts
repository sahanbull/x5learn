import { postAction, postActionsBulk } from './api';

function configuredActionType(value: string | undefined) {
  const id = Number(value);
  return Number.isInteger(id) && id > 0 ? id : undefined;
}

// IDs supplied by the existing API; registering action types is a server concern.
export const ActionTypes = {
  OER_OPENED: 1,
  VIDEO_PLAYED: 4,
  VIDEO_PAUSED: 5,
  VIDEO_SEEKED: 6,
  CONTENT_FLOW_CHANGED: 7,
  OER_FEEDBACK: 8,
  VIDEO_STILL_PLAYING: 9,
  TOGGLE_EXPLAINER: 11,
  OPEN_EXPLANATION_POPUP: 13,
  URL_CHANGED: 14,
  USER_LOGIN: 15,
  USER_LOGOUT: 16,
  PDF_OPENED: 17,
  PLAYLIST_ITEM_PREVIOUS: 18,
  NOTE_ADDED: 19,
  TEMP_PLAYLIST_CREATED: 20,
  PLAYLIST_ITEM_ADDED: 21,
  PLAYLIST_PUBLISHED: 22,
  PLAYLIST_SHARE_LINK_COPIED: 23,
  // These events are absent from the supplied catalog. Use existing IDs only.
  PLAYLIST_OPENED: configuredActionType(
    process.env.REACT_APP_ACTION_TYPE_PLAYLIST_OPENED,
  ),
  PLAYLIST_ITEM_SKIPPED: configuredActionType(
    process.env.REACT_APP_ACTION_TYPE_PLAYLIST_ITEM_SKIPPED,
  ),
  TRIGGER_SEARCH: configuredActionType(
    process.env.REACT_APP_ACTION_TYPE_TRIGGER_SEARCH,
  ),
} as const;

export type ActionType = typeof ActionTypes[keyof typeof ActionTypes];

function serializeParams(actionType: number, params: Record<string, unknown>) {
  if ([1, 4, 5, 6, 9, 17].includes(actionType) && 'oer_id' in params) {
    const { oer_id, ...rest } = params;
    return JSON.stringify({ ...rest, oerId: oer_id });
  }
  if (actionType === ActionTypes.OER_FEEDBACK && 'oer_id' in params) {
    const { oer_id, ...rest } = params;
    return JSON.stringify({ ...rest, 'OER id': oer_id });
  }
  return JSON.stringify(params);
}

function reportLoggingError(error: any) {
  // Logging must not interrupt anonymous visitors, navigation or playback.
  if (error?.message?.status !== 401) {
    console.error('Failed to log action', error);
  }
}

export async function logAction(
  actionType: ActionType,
  params: Record<string, unknown>,
): Promise<void> {
  if (actionType === undefined) return;
  try {
    await postAction({
      action_type_id: actionType,
      params: serializeParams(actionType, params),
      is_bundled: false,
    });
  } catch (error) {
    reportLoggingError(error);
  }
}

export async function logActions(
  actions: Array<{ actionType: ActionType; params: Record<string, unknown> }>,
): Promise<void> {
  const configuredActions = actions.filter(
    (
      action,
    ): action is { actionType: number; params: Record<string, unknown> } =>
      action.actionType !== undefined,
  );
  if (configuredActions.length === 0) return;
  try {
    await postActionsBulk({
      action_type_ids: configuredActions.map(action => action.actionType),
      params_list: configuredActions.map(action =>
        serializeParams(action.actionType, action.params),
      ),
    });
  } catch (error) {
    reportLoggingError(error);
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
