# User action logging

Actions are stored in the existing `action` table with `action_type_id`,
`params` (a JSON object), a UTC `created_at`, and `user_login_id`.
The server supplies `user_login_id` from the authenticated session; callers
cannot choose the actor. Guest actions are not stored.

The application fills missing action types at startup using explicit IDs.
Existing IDs 1–14 and their historical descriptions are preserved. Restart
the Flask application to register IDs 15–23; no schema migration is required.

| Requested event | ID | Description | Params |
| --- | --- | --- | --- |
| Successful login | 15 | User logged in | `user_id`, `authn_via` |
| Playlist opened | 16 | Playlist opened | Playlist context |
| Video/resource opened | 1 | OER card opened | `oer_id`, playlist context |
| Playback started/resumed | 4 | Video played | `oer_id`, `time`, playlist context |
| Playback paused | 5 | Video paused | `oer_id`, `time`, playlist context |
| Video seeked | 6 | Video seeked | `oer_id`, `from`, `to`, playlist context |
| Next button pressed | 17 | Playlist item skipped | `oer_id`, `from`, `to`, playlist context |
| Previous button pressed | 18 | Previous playlist item opened | `oer_id`, `from`, `to`, playlist context |
| Note saved | 19 | Note added | `oer_id`, `note_id` |
| Temporary playlist created | 20 | Temporary playlist created | `temp_title`, `parent`, `playlist_type` |
| Item added | 21 | Item added to playlist | `oer_id`, playlist context |
| Playlist published | 22 | Playlist published | `playlist_id`, `temp_title`, `oer_ids`, `playlist_type` |
| Share link copied | 23 | Playlist share link copied | `url`, playlist context |

Playlist context is `{"playlist_type":"published","playlist_id":7}` or
`{"playlist_type":"temporary","temp_title":"My playlist"}`. Temporary playlists
are identified by their title and authenticated creator because they have no
numeric ID. Resources opened outside a playlist omit playlist context.

Seek `from` and `to` are seconds. Next/previous `from` and `to` are OER item
IDs. Playback `time` is seconds. Note text is not copied into action params.

Login events come from Flask-Security's successful authentication signal,
including password, Microsoft and Google login. Refreshing pages and loading
session details do not generate login events. Successful note and playlist
mutations are recorded on the server, including additions through YouTube/PDF
import, bulk temporary playlist updates and published playlist updates.

Playlist and resource opens are recorded after the page successfully loads;
direct links and next/previous resource navigation are covered. Background
playlist metadata requests do not generate playlist-open events. Share events
are recorded only after clipboard copying succeeds. Logging requests use
session credentials and failures do not interrupt navigation or playback.

Native video uses seeking/seeked events and its last observed playback position.
YouTube does not expose a user-seek callback through this ReactPlayer version:
the player is sampled every 250 ms, and timeline jumps exceeding normal
elapsed playback plus a one-second tolerance are logged. The source position
is the most recent sample; very small YouTube seeks within the tolerance
cannot be distinguished reliably from normal playback. Configured initial
start positions do not count as user seeks.

## API examples

POST `/api/v1/action/`:

```json
{
  "action_type_id": 6,
  "params": "{\"oer_id\":12,\"playlist_type\":\"published\",\"playlist_id\":7,\"from\":5,\"to\":40}",
  "is_bundled": false
}
```

`params` is a JSON-encoded **string** in the request and a JSON object in the
database. Bundles use matching `action_type_ids` and `params_list` arrays.
The entire bundle is validated before any row is added, and stored in one
transaction. Invalid IDs, malformed params, or mismatched bundles return 400;
anonymous requests return 401. Legacy `oerId` is normalized to `oer_id`.

GET `/api/v1/action/?action_type_id=6` returns the current user's seek events.
The existing history endpoint continues to use action type 1.

## Verification

```powershell
$env:CI = 'true'
node node_modules/react-scripts/bin/react-scripts.js test --watchAll=false --runInBand --watchman=false --runTestsByPath src/app/api/actionLogging.test.ts src/app/components/VideoPlaybackTracker.test.ts src/app/pages/actionLogging.test.tsx
.venv\Scripts\python.exe -m pytest test-unit/test_action_logging.py -q -p no:cacheprovider
npm run checkTs
```

The isolated backend tests do not import the application or connect to its
configured database.
