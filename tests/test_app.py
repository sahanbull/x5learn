import pytest
import json
from x5learn_server import _config
from x5learn_server import models


def test_list_actions_unauthorized(client):
    response = client.get('/api/v1/action/')

    assert response.status_code == 401


def test_log_action_unauthorized(client):
    response = client.post('/api/v1/action/', json={'action_type_id': 1, 'params': '{}'}, follow_redirects=True)

    assert response.status_code == 401


def test_forget_user_unauthorized(client):
    response = client.delete('/api/v1/user/forget')

    assert response.status_code == 401


def test_get_definition_unauthorized(client):
    response = client.post('/api/v1/definition/', data=dict(
        titles="{}"
    ), follow_redirects=True)

    assert response.status_code == 401


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
