import pytest
import json
from x5learn_server import _config
from x5learn_server import models


def test_list_notes_unauthorized(client):
    response = client.get('/api/v1/note/')

    assert response.status_code == 401


def test_create_note_unauthorized(client):
    response = client.post('/api/v1/note/', data=dict(
        oer_id=1,
        text="test string"
    ), follow_redirects=True)

    assert response.status_code == 400


def test_get_note_unauthorized(client):
    response = client.get('/api/v1/note/1')

    assert response.status_code == 401


def test_update_note_unauthorized(client):
    response = client.put('/api/v1/note/1', data=dict(
        oer_id=1,
        text="test string"
    ), follow_redirects=True)

    assert response.status_code == 401


def test_delete_note_unauthorized(client):
    response = client.delete('/api/v1/note/1')

    assert response.status_code == 401


def test_list_actions_unauthorized(client):
    response = client.get('/api/v1/action/')

    assert response.status_code == 401


def test_log_action_unauthorized(client):
    response = client.post('/api/v1/action/', data=dict(
        action_type_id=1,
        params="{}"
    ), follow_redirects=True)

    assert response.status_code == 400


def test_forget_user_unauthorized(client):
    response = client.delete('/api/v1/delete/')

    assert response.status_code == 404


def test_get_definition_unauthorized(client):
    response = client.post('/api/v1/definition/', data=dict(
        titles="{}"
    ), follow_redirects=True)

    assert response.status_code == 401


def test_repository_add(repository):
    note = models.Note(1, "test", 1, False)

    result = repository.add(note)

    assert type(result) is models.Note
    assert result is not None


def test_repository_get(repository):
    result = repository.get(models.Note, 1)

    assert result is not None


def test_repository_get_by_id(repository):
    existing = repository.get(models.Note, 1)

    if (existing is None): 
        note = models.Note(1, "test", 1, False)
        repository.add(note)

    id_to_get = existing[0].id

    result = repository.get_by_id(models.Note, id_to_get)

    assert type(result) is models.Note
    assert result is not None


def test_repository_update(repository):
    existing = repository.get(models.Note, 1)

    if (existing is None):
        note = models.Note(1, "test", 1, False)
        repository.add(note)

    id_to_get = existing[0].id

    note_to_update = repository.get_by_id(models.Note, id_to_get)

    setattr(note_to_update, "text", "update")

    result = repository.update()

    assert result is True


def test_notes_repository_get_notes(notes_repository):
    result = notes_repository.get_notes(1)
    assert result is not None

    result = notes_repository.get_notes(1, 1)
    assert result is not None

    result = notes_repository.get_notes(1, 1, 'asc')
    assert result is not None

    result = notes_repository.get_notes(1, 1, 'asc', 0)
    assert result is not None

    result = notes_repository.get_notes(1, 1, 'asc', 0, 1)
    assert result is not None


def test_actions_repository_get_actions(actions_repository):
    result = actions_repository.get_actions(1)
    assert result is not None

    result = actions_repository.get_actions(1, 1)
    assert result is not None

    result = actions_repository.get_actions(1, 1, 'asc')
    assert result is not None

    result = actions_repository.get_actions(1, 1, 'asc', 0)
    assert result is not None

    result = actions_repository.get_actions(1, 1, 'asc', 0, 1)
    assert result is not None


def test_definitions_repository_get_definitions_list(definitions_repository):
    # Fetching single item in list
    temp_list = ["Sri Lanka"]
    result = definitions_repository.get_definitions_list(temp_list)
    assert result is not None

    # Fetching multiple items in list
    temp_list = ["Colombo", "Kandy"]
    result = definitions_repository.get_definitions_list(temp_list)
    assert result is not None