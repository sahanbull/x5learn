import os
import msal
from flask import session, url_for

# --- Azure AD Configuration ---
AUTHORITY = f"https://login.microsoftonline.com/{os.environ['AZURE_TENANT_ID']}"
CLIENT_ID = os.environ["AZURE_CLIENT_ID"]
CLIENT_SECRET = os.environ["AZURE_CLIENT_SECRET"]

# OIDC scopes used for user authentication (allowed in authorize URL)
OIDC_SCOPES = ["openid", "profile", "email", "offline_access"]

# If you also need Graph API access, include delegated permissions here.
# For sign-in only, leave this list empty.
API_SCOPES = []  # Example: ["User.Read"]

print("USING ms_auth FROM:", __file__)     # <-- proves which file is imported
print("API_SCOPES =", API_SCOPES)

# ----------------------------------------------------
# Internal helpers for MSAL token management
# ----------------------------------------------------
def _build_cache():
    """Build an in-session token cache."""
    cache = msal.SerializableTokenCache()
    if session.get("msal_cache"):
        cache.deserialize(session["msal_cache"])
    return cache


def _save_cache(cache):
    """Persist the cache back to the session if it changed."""
    if cache.has_state_changed:
        session["msal_cache"] = cache.serialize()


def _build_msal_app(cache=None):
    """Return a configured MSAL ConfidentialClientApplication."""
    return msal.ConfidentialClientApplication(
        CLIENT_ID,
        authority=AUTHORITY,
        client_credential=CLIENT_SECRET,
        token_cache=cache,
    )


# ----------------------------------------------------
# Authentication URL builder
# ----------------------------------------------------
def build_auth_url():
    """Generate the Microsoft login URL (used in /login/azure)."""
    return _build_msal_app().get_authorization_request_url(
        scopes=API_SCOPES,  # okay to include OIDC scopes here
        redirect_uri=url_for("azure_callback", _external=True),
        response_mode="form_post",
    )


# ----------------------------------------------------
# Token acquisition
# ----------------------------------------------------
def acquire_token_by_code(auth_code):
    """
    Exchange authorization code for tokens.
    Do NOT include reserved scopes here.
    """
    print("REDEEMING WITH SCOPES:", API_SCOPES)  # must print [] for sign-in only

    cache = _build_cache()
    app = _build_msal_app(cache)
    # Reserved scopes (openid, profile, offline_access) must be omitted
    result = app.acquire_token_by_authorization_code(
        auth_code,
        scopes=API_SCOPES,  # [] if sign-in only
        redirect_uri=url_for("azure_callback", _external=True),
    )
    _save_cache(cache)
    return result
