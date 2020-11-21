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
  //   return fetchAPI(`/session`);
  return require('./mock/loggedInUserDetail.json');
}
export async function fetchAction() {
  // return fetchAPI(`/action`);
  return require('./mock/loggedInUserDetail.json');
}
export async function fetchPlaylistDetail(playlistID) {
  // return fetchAPI(`/playlist/${playlistID}`);
  return require('./mock/playlist-24.json');
}
export async function fetchPlaylists(limit, offset) {
  // return fetchAPI(`/playlist`);
  return require('./mock/playlist-24.json');
}
export async function fetchFeaturedOERs() {
  debugger;
  return fetchAPI(`/featured`);
  // const data = await require('./mock/featuredList.json');
  // return data;
}
export async function fetchWikiEnrichments(idArray) {
  // var body = JSON.stringify({ ids: idArray });
  // return fetchAPI(`/wikichunk_enrichments`, body, { method: 'POST' });
  return require('./mock/wiki-enrichment.json');
}
export async function fetchOERs(idArray) {
  // var body = JSON.stringify({ ids: idArray });

  // return fetchAPI(`/oers`, body, { method: 'POST' });
  return require('./mock/featuredList.json');
}
