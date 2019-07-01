from setuptools import setup

setup(
    name='x5learn',
    version='0.1',
    packages=['x5learn_server', 'test-integration', 'test-integration.x5learn_server', 'test-integration.x5learn_server.db'],
    url='x5learn.org',
    license='',
    author='x5gon',
    author_email='',
    description='',
    install_requires=[
        'Flask>=1.0.2',
        'Flask-Security>=3.0.0',
        'SQLAlchemy>=1.3.1',
        'psycopg2>=2.7.6.1',
        'gunicorn>=19.9.0',
        'fuzzywuzzy>=0.17.0',
        'flask_sqlalchemy',
        'langdetect',
        'flask-restplus',
        'pytest',
        'pytest-flask'
]
)
