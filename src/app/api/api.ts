import queryString from 'query-string';

const BASE_URL = process.env.REACT_APP_BASE_URL;
const AUTH_KEY: string = process.env.REACT_APP_AUTH_KEY || '';

var headers = new Headers();
headers.append('Authorization', AUTH_KEY);
headers.append('Content-Type', 'application/json');
// headers.append("Access-Control-Request-Headers", '*');
// headers.append("Access-Control-Request-Method", 'POST, GET, OPTIONS, DELETE');

async function fetchAPI(
  endpoint,
  data?,
  options: { method?: string; useAuth?: boolean } = {
    method: 'GET',
    useAuth: true,
  },
) {
  const { method } = options;
  const requestOptions = {
    method,
    headers,
    data,
  };

  if (method === 'POST') {
    requestOptions.data = data;
  }
  return fetch(`${BASE_URL}${endpoint}`, requestOptions)
    .then(response => response.json())
    .then(result => {
      console.log(result);
      return result;
    })
    .catch(error => {
      console.log('error', error);
      throw error;
    });
}

export async function fetchLoggedInUserDetail() {
  return fetchAPI(`/session/`);
  // return require('./mock/loggedInUserDetail.json');
}
export async function fetchAction() {
  return fetchAPI(`/action/`);
  // return require('./mock/loggedInUserDetail.json');
}
export async function fetchPlaylistDetails(playlistID) {
  return fetchAPI(`/playlist/${playlistID}/`);
  // return require('./mock/playlist-24.json');
}
export async function fetchMyPlaylistsMenu(limit?, offset?) {
  // const qs = queryString.stringify({limit, offset})
  // debugger
  // return fetchAPI(`/playlist/?${qs}`);
  return require('./mock/playlists-menu.json');
}
export async function fetchPlaylists(limit?, offset?) {
  const qs = queryString.stringify({ limit, offset });
  return fetchAPI(`/playlist/?${qs}`);
  // return require('./mock/playlist-24.json');
}
export async function fetchFeaturedOERs() {
  return fetchAPI(`/featured/`);
  // const data = await require('./mock/featuredList.json');
  // return data;
}
export async function fetchWikiEnrichments(idArray) {
  var body = JSON.stringify({ ids: idArray });
  return fetchAPI(`/wikichunk_enrichments/`, body, { method: 'POST' });
  // return require('./mock/wiki-enrichment.json');
}
export async function fetchOERs(idArray) {
  // return require('./mock/featuredList.json');
}
export async function fetchSearchOERs({ searchTerm, page }) {
  const qs = queryString.stringify({ text: searchTerm, page });
  return fetchAPI(`/search/?${qs}`);
  //https://x5learn.org/api/v1/search/?text=se&page=1

  // return require('./mock/search-se.json');
}
