import os
import tempfile
import pytest
from x5learn_server import app


@pytest.fixture
def client():
    db_fd, app.app.config['DATABASE'] = tempfile.mkstemp()
    app.app.config['TESTING'] = True
    client = app.app.test_client()

    with app.app.app_context():
        app.initiate_login_db()

    yield client

    os.close(db_fd)
    os.unlink(app.app.config['DATABASE'])