const BASE_URL = process.env.REACT_APP_BASE_URL;
const AUTH_KEY = process.env.REACT_APP_AUTH_KEY;

var headers = {
  Authorization: AUTH_KEY,
  'Content-Type': 'application/json',
};

async function fetchAPI(
  endpoint,
  data,
  options = { method: 'GET', useAuth: true },
) {
  const { method } = options;
  const requestOptions = {
    method,
    headers,
  };

  if (method === 'POST') {
    requestOptions.data = data;
  }
  debugger;
  return fetch(`${BASE_URL}${endpoint}`, requestOptions)
    .then(response => response.text())
    .then(result => console.log(result))
    .catch(error => console.log('error', error));
}

export async function fetchLoggedInUserDetail() {
  return fetchAPI(`/session`);
}
export async function fetchAction() {
  return fetchAPI(`/action`);
}
export async function fetchPlaylistDetail(playlistID) {
  return fetchAPI(`/playlist/${playlistID}`);
}
export async function fetchPlaylists(limit, offset) {
  return fetchAPI(`/playlist`);
}
export async function fetchFeaturedOERs() {
  return fetchAPI(`/featured`);
}
export async function fetchWikiEnrichments(idArray) {
  var body = JSON.stringify({ ids: idArray });
  return fetchAPI(`/wikichunk_enrichments`, body, { method: 'POST' });
}
export async function fetchOERs(idArray) {
  var body = JSON.stringify({ ids: idArray });

  return fetchAPI(`/oers`, body, { method: 'POST' });
}
