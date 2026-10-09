"""Stable action IDs shared with the browser (see docs/action-logging.md)."""
from enum import IntEnum


class ActionTypes(IntEnum):
    OER_OPENED = 1
    VIDEO_PLAYED = 4
    VIDEO_PAUSED = 5
    VIDEO_SEEKED = 6
    USER_LOGIN = 15
    PLAYLIST_OPENED = 16
    PLAYLIST_ITEM_SKIPPED = 17
    PLAYLIST_ITEM_PREVIOUS = 18
    NOTE_ADDED = 19
    TEMP_PLAYLIST_CREATED = 20
    PLAYLIST_ITEM_ADDED = 21
    PLAYLIST_PUBLISHED = 22
    PLAYLIST_SHARE_LINK_COPIED = 23


ACTION_DESCRIPTIONS = {
    1: 'OER card opened',
    2: 'OER marked as favorite (no longer in use)',
    3: 'OER unmarked as favorite (no longer in use)',
    4: 'Video played',
    5: 'Video paused',
    6: 'Video seeked',
    7: 'ContentFlow setting changed',
    8: 'Feedback on OER content',
    9: 'Video still playing',
    10: 'OverviewType selected',
    11: 'ToggleExplainer',
    12: 'OpenExplanationPopup',
    13: 'TriggerSearch',
    14: 'UrlChanged',
    15: 'User logged in',
    16: 'Playlist opened',
    17: 'Playlist item skipped',
    18: 'Previous playlist item opened',
    19: 'Note added',
    20: 'Temporary playlist created',
    21: 'Item added to playlist',
    22: 'Playlist published',
    23: 'Playlist share link copied',
}


def seed_action_types(db_session, action_type_model):
    """Fill missing IDs explicitly without changing historical descriptions."""
    for action_id, description in ACTION_DESCRIPTIONS.items():
        if db_session.get(action_type_model, action_id) is None:
            action_type = action_type_model(description)
            action_type.id = action_id
            db_session.add(action_type)
    db_session.commit()


def parse_action_payload(payload):
    """Validate the complete request before storing any single or bundled action."""
    import json

    if not isinstance(payload, dict):
        raise ValueError('Action payload must be an object')
    if payload.get('is_bundled', False):
        action_ids = payload.get('action_type_ids')
        params_list = payload.get('params_list')
        if (not isinstance(action_ids, list) or not isinstance(params_list, list)
                or not action_ids or len(action_ids) != len(params_list)):
            raise ValueError('Matching action_type_ids and params_list are required')
    else:
        action_ids = [payload.get('action_type_id')]
        params_list = [payload.get('params', '{}')]

    actions = []
    for action_id, raw_params in zip(action_ids, params_list):
        if type(action_id) is not int or action_id not in ACTION_DESCRIPTIONS:
            raise ValueError('Unknown action type id')
        try:
            params = json.loads(raw_params)
        except (TypeError, ValueError):
            raise ValueError('Params must be a JSON object encoded as a string')
        if not isinstance(params, dict):
            raise ValueError('Params must be a JSON object encoded as a string')
        # Older clients used oerId; keep history filtering consistent.
        if 'oerId' in params and 'oer_id' not in params:
            params['oer_id'] = params.pop('oerId')
        actions.append((action_id, params))
    return actions
