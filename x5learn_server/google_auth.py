import os
from flask import session, url_for
from google_auth_oauthlib.flow import Flow
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token

# --- Google OAuth Configuration ---
GOOGLE_CLIENT_ID = os.environ["GOOGLE_CLIENT_ID"]
GOOGLE_CLIENT_SECRET = os.environ["GOOGLE_CLIENT_SECRET"]

# OIDC scopes used for user sign-in
GOOGLE_SCOPES = [
    "openid",
    "https://www.googleapis.com/auth/userinfo.email",
    "https://www.googleapis.com/auth/userinfo.profile",
]

GOOGLE_CLIENT_CONFIG = {
    "web": {
        "client_id": GOOGLE_CLIENT_ID,
        "client_secret": GOOGLE_CLIENT_SECRET,
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
    }
}


def _build_flow(code_verifier=None):
    """Return a configured OAuth Flow bound to our callback route."""
    return Flow.from_client_config(
        GOOGLE_CLIENT_CONFIG,
        scopes=GOOGLE_SCOPES,
        redirect_uri=url_for("google_callback", _external=True),
        code_verifier=code_verifier,
    )


def build_google_auth_url():
    """Generate the Google sign-in URL (used in /login/google)."""
    flow = _build_flow()
    auth_url, state = flow.authorization_url(
        access_type="online",
        include_granted_scopes="true",
        prompt="select_account",
    )
    # Google now enforces PKCE, so the auto-generated verifier must survive
    # into the callback request (a fresh Flow instance) via the session.
    session["google_oauth_state"] = state
    session["google_oauth_code_verifier"] = flow.code_verifier
    return auth_url


def acquire_google_identity(authorization_response_url):
    """
    Exchange the authorization response for tokens and return the verified
    ID token claims (sub, email, name, ...).
    """
    flow = _build_flow(code_verifier=session.get("google_oauth_code_verifier"))
    flow.state = session.get("google_oauth_state")
    flow.fetch_token(authorization_response=authorization_response_url)

    claims = id_token.verify_oauth2_token(
        flow.credentials._id_token,
        google_requests.Request(),
        GOOGLE_CLIENT_ID,
    )
    return claims
