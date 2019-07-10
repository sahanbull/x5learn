import pytest


def test_list_notes(client):
    response = client.get('/api/v1/note/')

    assert response.status_code == 200


def test_create_note(client):
    response = client.post('/api/v1/note/', data=dict(
        oer_id=1,
        text="test string"
    ), follow_redirects=True)

    assert response.status_code == 201


def test_get_note(client):
    response = client.get('/api/v1/note/1')

    assert response.status_code == 200


def test_update_note(client):
    response = client.put('/api/v1/note/1', data=dict(
        oer_id=1,
        text="test string"
    ), follow_redirects=True)

    assert response.status_code == 201


def test_delete_note(client):
    response = client.delete('/api/v1/note/1')

    assert response.status_code == 201
