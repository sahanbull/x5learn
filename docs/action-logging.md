# Frontend action logging

The frontend calls the existing action APIs using session credentials. These
changes do not modify backend code, register action types, or migrate stored logs.

The supplied API catalog is used for resource opens (1), video play (4),
pause (5), seek (6), continuing playback (9), ContentFlow changes (7), feedback
(8), explainer toggles (11), explanation popups (13), URL changes (14), login
(15), logout (16), and PDF opens (17). The duplicate IDs 10 and 12 in the
supplied table are not used by new frontend events.

Video, resource, and PDF requests use `oerId`. Playback events include
`positionInSeconds` with fractional precision. Seek events also retain
`from` and `to` in seconds. Feedback params use `OER id` and `user feedback`.
The shared helpers accept internal `oer_id` values and serialize them to these
API keys.

Native video uses seeking/seeked callbacks. YouTube is sampled every 250 ms
because this ReactPlayer version has no user-seek callback. Jumps outside
normal elapsed playback plus a one-second tolerance generate seek events;
very small YouTube seeks within that tolerance cannot be distinguished
reliably from playback. Initial configured start positions do not count as
user seeks. Duplicate callbacks and invalid playback positions are ignored.

Continuing playback is logged at most once every 10 seconds while the position
advances. Paused and stalled playback do not emit heartbeats. Resource and PDF
open events are sent together through the bulk helper when opening the PDF
viewer. URL changes and explanation menu opens use the supplied IDs. Logout
logs ID 16 before redirecting to the existing logout URL; an offline request
can delay that redirect by at most two seconds.

ContentFlow, explainer toggle, and feedback events are available through the
shared helpers; the current React UI has no controls for those settings or
feedback. Existing server login and mutation behavior is unchanged.

## IDs not supplied in the catalog

The supplied table reserves 16 for logout and 17 for PDF open. Playlist-open
and playlist-skip logging therefore cannot reuse those IDs. Search submission
also has no ID in that table. Configure these frontend environment variables
with IDs already supported by the target backend to enable those events:

- `REACT_APP_ACTION_TYPE_PLAYLIST_OPENED`
- `REACT_APP_ACTION_TYPE_PLAYLIST_ITEM_SKIPPED`
- `REACT_APP_ACTION_TYPE_TRIGGER_SEARCH`

Unconfigured events are skipped; the frontend does not invent new action IDs.
Existing previous-item, note, playlist mutation, and share IDs 18–23 are retained.
Playlist params include the published ID or temporary title as before.

## API usage

Single actions use POST `/api/v1/action/`:

```json
{
  "action_type_id": 5,
  "params": "{\"oerId\":12,\"positionInSeconds\":3.976099}",
  "is_bundled": false
}
```

Multiple actions use the provided POST `/api/v1/action/bulk/`:

```json
{
  "action_type_ids": [1, 2],
  "params_list": ["{\"oer_id\":42}", "{}"]
}
```

The client sends matching arrays with JSON-encoded strings, without requiring
`is_bundled` for the bulk endpoint:

```ts
await logActions([
  { actionType: ActionTypes.OER_OPENED, params: { oerId: 42 } },
  { actionType: ActionTypes.PDF_OPENED, params: { oerId: 42 } },
]);
```

Logging failures are caught so playback and navigation can continue. Anonymous
401 responses are ignored. The target API must already expose the supplied bulk
endpoint and catalog; this frontend change does not add them to the local server.

## Verification

```powershell
$env:CI = 'true'
node node_modules/react-scripts/bin/react-scripts.js test --watchAll=false --runInBand --watchman=false --runTestsByPath src/app/api/actionLogging.test.ts src/app/api/actionBulkApi.test.ts src/app/components/VideoPlaybackTracker.test.ts src/app/components/ActionLoggingObserver.test.tsx src/app/components/LogoutRedirect.test.tsx src/app/pages/actionLogging.test.tsx src/app/__tests__/index.test.tsx
npm run checkTs
```

Rebuild the frontend to activate these changes.
