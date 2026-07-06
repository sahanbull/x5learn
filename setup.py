from setuptools import setup

setup(
    name='x5learn',
    version='1.0',
    packages=['x5learn_server', 'test-integration', 'test-integration.x5learn_server',
              'test-integration.x5learn_server.db'],
    url='x5learn.org',
    license='',
    author='x5gon',
    author_email='',
    description='',
    install_requires=[
        # Core Flask stack (modern, maintained versions)
        "Flask>=2.3,<3.2",             # works with Flask-Security-Too
        "Werkzeug>=2.3,<4.0",          # compatible with Flask >=2.3
        "flask-security-too>=5.3.0",   # maintained fork
        "flask-sqlalchemy>=3.0.0",
        "Flask-Mailman>=0.3.0",        # drop-in replacement for Flask-Mail (Mail is unmaintained)
        "Flask-WTF>=1.2.1",
        "email-validator>=2.0",
        "flask-cors>=4.0.0",

        # ORM + DB
        "SQLAlchemy>=2.0.0",
        "psycopg2>=2.9.0",

        # Auth + Crypto
        "bcrypt>=4.0.1",
        "msal>=1.30.0",

        # Utilities
        "python-dateutil",
        "isodate",
        "dotenv",
        "fuzzywuzzy>=0.17.0",
        "langdetect",
        "wikipedia",
        "wget",
        "preview_generator",

        # API layer (flask-restplus is dead → move to flask-restx)
        "flask-restx>=1.3.0",  # actively maintained fork of flask-restplus

        # Deployment
        "gunicorn>=20.1.0",

        # Testing
        "pytest",
        "pytest-flask",

        # External APIs
        "google-api-python-client>=2.169.0",
    ]
)
