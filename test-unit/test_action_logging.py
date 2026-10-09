"""Isolated action tests: no application import or configured database access."""
import ast
import json
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import MagicMock

import pytest
from sqlalchemy import Column, Integer, String, create_engine
from sqlalchemy.orm import declarative_base, Session

from x5learn_server.action_logging import (
    ACTION_DESCRIPTIONS, ActionTypes, parse_action_payload, seed_action_types,
)

ROOT = Path(__file__).resolve().parents[1]


def load_app_functions(*names, **globals_):
    # The legacy app initializes its configured database on import. Extract its
    # actual route/helper definitions to exercise them without touching that DB.
    tree = ast.parse((ROOT / 'x5learn_server/app.py').read_text(encoding='utf-8'))
    definitions = [node for node in tree.body if getattr(node, 'name', None) in names]
    for definition in definitions:
        definition.decorator_list = []
        for node in ast.walk(definition):
            if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                node.decorator_list = []
    namespace = {'ActionTypes': ActionTypes, 'json': json, **globals_}
    exec(compile(ast.Module(body=definitions, type_ignores=[]), 'app.py', 'exec'), namespace)
    return namespace


def test_seed_ids_are_explicit_repeatable_and_preserve_existing_descriptions():
    base = declarative_base()

    class ActionType(base):
        __tablename__ = 'action_type'
        id = Column(Integer, primary_key=True)
        description = Column(String)

        def __init__(self, description):
            self.description = description

    engine = create_engine('sqlite://')
    base.metadata.create_all(engine)
    with Session(engine) as session:
        existing = ActionType('Historical description')
        existing.id = 10
        session.add(existing)
        session.commit()
        seed_action_types(session, ActionType)
        seed_action_types(session, ActionType)
        rows = session.query(ActionType).all()
        assert {row.id for row in rows} == set(ACTION_DESCRIPTIONS)
        assert session.get(ActionType, 10).description == 'Historical description'
        assert session.get(ActionType, 15).description == 'User logged in'
        assert session.get(ActionType, 23).description == 'Playlist share link copied'


@pytest.mark.parametrize('payload', [
    None, {}, {'action_type_id': True}, {'action_type_id': 99},
    {'action_type_id': 4, 'params': '{'},
    {'action_type_id': 4, 'params': '[]'},
    {'is_bundled': True},
    {'is_bundled': True, 'action_type_ids': [4, 5], 'params_list': ['{}']},
    {'is_bundled': True, 'action_type_ids': [4, 5], 'params_list': ['{}', 'invalid']},
])
def test_rejects_invalid_actions_and_entire_invalid_bundles(payload):
    with pytest.raises(ValueError):
        parse_action_payload(payload)


def test_parses_bundles_and_normalizes_legacy_oer_ids():
    assert parse_action_payload({
        'is_bundled': True,
        'action_type_ids': [4, 6],
        'params_list': ['{"oerId":12}', '{"oer_id":12,"from":5,"to":40}'],
    }) == [(4, {'oer_id': 12}), (6, {'oer_id': 12, 'from': 5, 'to': 40})]


def test_login_records_authenticated_user_id_and_method():
    db = MagicMock()
    action = MagicMock()
    user = SimpleNamespace(is_authenticated=True, get_old_id=lambda: '42')
    module = load_app_functions(
        '_record_action', 'log_user_login', db_session=db, Action=action,
    )
    module['log_user_login'](None, user, authn_via=['password'])
    action.assert_called_once_with(15, {'user_id': 42, 'authn_via': ['password']}, '42')
    db.add.assert_called_once_with(action.return_value)
    db.commit.assert_called_once()


def test_anonymous_actions_are_not_recorded():
    db = MagicMock()
    module = load_app_functions(
        '_record_action', db_session=db, Action=MagicMock(),
        current_user=SimpleNamespace(is_authenticated=False),
    )
    module['_record_action'](4, {'oer_id': 12})
    db.add.assert_not_called()
    db.commit.assert_not_called()


def test_action_endpoint_validates_bundle_before_adding_any_rows():
    record = MagicMock()
    db = MagicMock()
    api = SimpleNamespace(payload={
        'is_bundled': True, 'action_type_ids': [4, 5],
        'params_list': ['{}', 'invalid'],
    })
    module = load_app_functions(
        'ActionList', Resource=object, api=api, db_session=db,
        current_user=SimpleNamespace(is_authenticated=True),
        parse_action_payload=parse_action_payload, _record_action=record,
    )
    result, status = module['ActionList']().post()
    assert status == 400
    record.assert_not_called()
    db.commit.assert_not_called()


def test_action_endpoint_uses_session_identity_and_commits_valid_bundle_once():
    db = MagicMock()
    action = MagicMock()
    api = SimpleNamespace(payload={
        'is_bundled': True, 'action_type_ids': [4, 6],
        'params_list': ['{"user_id":999,"oer_id":12}', '{"from":5,"to":30}'],
    })
    module = load_app_functions(
        'ActionList', '_record_action', Resource=object, api=api,
        db_session=db, Action=action, parse_action_payload=parse_action_payload,
        current_user=SimpleNamespace(is_authenticated=True, get_old_id=lambda: '42'),
    )
    _, status = module['ActionList']().post()
    assert status == 201
    assert all(call.args[2] == '42' for call in action.call_args_list)
    assert db.add.call_count == 2
    db.commit.assert_called_once()


def test_note_creation_logs_saved_note_id_without_note_text():
    db = MagicMock()
    record = MagicMock()
    module = load_app_functions(
        'NotesList', Resource=object, db_session=db, _record_action=record,
        current_user=SimpleNamespace(is_authenticated=True, get_old_id=lambda: '42'),
        api=SimpleNamespace(payload={'oer_id': 12, 'text': 'Private note'}),
        Note=lambda *args: SimpleNamespace(id=8, oer_id=12),
    )
    _, status = module['NotesList']().post()
    assert status == 201
    record.assert_called_once_with(
        ActionTypes.NOTE_ADDED, {'oer_id': 12, 'note_id': 8}, commit=False,
    )
    db.flush.assert_called_once()
    db.commit.assert_called_once()


def test_temp_creation_logs_creation_and_inherited_item_ids():
    db = MagicMock()
    repository = MagicMock()
    repository.get.return_value = [SimpleNamespace(oer_id=12)]
    record = MagicMock()
    module = load_app_functions(
        '_add_temporary_playlist', repository=repository, db_session=db,
        _record_action=record, Temp_Playlist=MagicMock(), Playlist_Item=object,
    )
    module['_add_temporary_playlist']('My playlist', 1, '42', 7)
    assert record.call_args_list[0].args[0] == ActionTypes.TEMP_PLAYLIST_CREATED
    assert record.call_args_list[1].args == (
        ActionTypes.PLAYLIST_ITEM_ADDED,
        {'playlist_type': 'temporary', 'temp_title': 'My playlist', 'oer_id': 12},
    )
    db.commit.assert_called_once()


@pytest.mark.parametrize('found', [True, False])
def test_item_addition_logs_only_when_playlist_exists(found):
    db = MagicMock()
    playlist = SimpleNamespace(data='{"playlist_items":[]}')
    db.query.return_value.filter.return_value.filter.return_value.one_or_none.return_value = (
        playlist if found else None
    )
    record = MagicMock()
    repository = MagicMock()
    repository.get_by_id.return_value = SimpleNamespace(data={'title': 'Video'})
    module = load_app_functions(
        '_add_oer_to_playlist', db_session=db, repository=repository,
        Temp_Playlist=SimpleNamespace(title='title', creator='creator'),
        current_user=SimpleNamespace(get_old_id=lambda: '42'), _record_action=record,
        Oer=object,
    )
    assert module['_add_oer_to_playlist']('My playlist', 12) is found
    if found:
        record.assert_called_once_with(
            ActionTypes.PLAYLIST_ITEM_ADDED,
            {'playlist_type': 'temporary', 'temp_title': 'My playlist', 'oer_id': 12},
            commit=False,
        )
        assert json.loads(playlist.data)['playlist_items'] == [12]
    else:
        record.assert_not_called()


@pytest.mark.parametrize('new_items,expected_additions', [([13, 12], []), ([12, 14, 13], [14])])
def test_published_update_logs_additions_without_logging_reorders(new_items, expected_additions):
    record = MagicMock()
    repository = MagicMock()
    repository.get_by_id.return_value = SimpleNamespace(id=7)
    repository.get.return_value = [
        SimpleNamespace(oer_id=12, data={'title': 'Custom title'}),
        SimpleNamespace(oer_id=13, data={}),
    ]
    module = load_app_functions(
        'Playlist_Single', Resource=object, _record_action=record,
        repository=repository, Playlist=object, Playlist_Item=MagicMock(),
        current_user=SimpleNamespace(is_authenticated=True, get_old_id=lambda: '42'),
        api=SimpleNamespace(payload={
            'playlist_items': new_items, 'playlist_items_order': list(range(len(new_items))),
            'title': 'Published', 'description': '', 'author': '',
            'license': 1, 'parent': None, 'is_visible': True,
        }),
    )
    _, status = module['Playlist_Single']().put(7)
    assert status == 201
    assert [call.args[1]['oer_id'] for call in record.call_args_list] == expected_additions
    assert all(call.args[1]['playlist_id'] == 7 for call in record.call_args_list)
    items = module['Playlist_Item'].call_args_list
    assert next(call.args[3] for call in items if call.args[1] == 12) == {'title': 'Custom title'}


@pytest.mark.parametrize('new_items,expected_additions', [([13, 12], []), ([12, 14, 13], [14])])
def test_temporary_update_logs_additions_without_logging_reorders(new_items, expected_additions):
    record = MagicMock()
    db = MagicMock()
    playlist = SimpleNamespace(title='Draft', data='{"playlist_items":[12,13]}')
    db.query.return_value.filter.return_value.filter.return_value.one_or_none.return_value = playlist
    module = load_app_functions(
        'Temp_Playlist_Single', Resource=object, _record_action=record, db_session=db,
        repository=MagicMock(), Temp_Playlist=SimpleNamespace(title='title', creator='creator'),
        current_user=SimpleNamespace(is_authenticated=True, get_old_id=lambda: '42'),
        api=SimpleNamespace(payload={'title': 'Draft', 'playlist_items': new_items}),
    )
    _, status = module['Temp_Playlist_Single']().put('Draft')
    assert status == 201
    assert [call.args[1]['oer_id'] for call in record.call_args_list] == expected_additions


def test_publish_logs_published_id_and_original_temp_title():
    record = MagicMock()
    module = load_app_functions(
        'Playlists', Resource=object, _record_action=record,
        current_user=SimpleNamespace(is_authenticated=True, get_old_id=lambda: '42'),
        api=SimpleNamespace(payload={
            'is_temp': False, 'title': 'Published', 'temp_title': 'Draft',
            'description': '', 'author': '', 'parent': None,
            'is_visible': True, 'playlist_items': [12, 13],
        }),
        _DEFAULT_LICENSE=1,
        _add_published_playlist=lambda *args: SimpleNamespace(id=7, title='Published'),
        _create_oer_record_for_playlist=lambda playlist: SimpleNamespace(url='share'),
        repository=MagicMock(), TempPlaylistRepository=MagicMock(), UserLogin=object,
        _send_confirmation_email_for_published_playlist=MagicMock(),
    )
    assert module['Playlists']().post() == 7
    record.assert_called_once_with(ActionTypes.PLAYLIST_PUBLISHED, {
        'playlist_type': 'published', 'playlist_id': 7,
        'temp_title': 'Draft', 'oer_ids': [12, 13],
    })
