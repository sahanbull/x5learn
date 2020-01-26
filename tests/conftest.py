import os
import tempfile
import pytest
import datetime
from x5learn_server import app as _app
from x5learn_server.models import UserLogin, Repository
from x5learn_server import _config


@pytest.fixture(scope='session')
def client():
    db_fd, _app.app.config['DATABASE'] = tempfile.mkstemp()
    _app.app.config['TESTING'] = True
    client = _app.app.test_client()

    with _app.app.app_context():
        _app.initiate_login_db()

    yield client

    os.close(db_fd)
    os.unlink(_app.app.config['DATABASE'])


@pytest.fixture(scope='session')
def repository():
    return _app.repository


@pytest.fixture(scope='session')
def actions_repository():
    return _app.ActionsRepository()


@pytest.fixture(scope='session')
def definitions_repository():
    return _app.DefinitionsRepository()
