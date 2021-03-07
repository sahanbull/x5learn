import queryString from 'query-string';

const BASE_URL = process.env.REACT_APP_BASE_URL;
const AUTH_KEY: string = process.env.REACT_APP_AUTH_KEY || '';

// headers.append('Content-Type', 'application/json');
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

  var headers = new Headers();
  headers.append('Authorization', AUTH_KEY);

  const requestOptions = {
    method,
    headers,
    body: data,
  };

  if (method === 'POST') {
    requestOptions.body = data;
    headers.append('Content-Type', 'application/json');
  }

  const response = await fetch(`${BASE_URL}${endpoint}`, requestOptions);
  const jsonResponse = await response.json();
  if (!response.ok) {
    const err = new Error('' + response.status);
    err.message = {
      status: response.status,
      statusText: jsonResponse,
      ...jsonResponse,
    };
    console.log('error', err);
    throw err;
  }
  console.log(jsonResponse);
  return jsonResponse;
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
  return fetchAPI(`/playlist/${playlistID}`);
  // return require('./mock/playlist-24.json');
}
export async function fetchTempPlaylistDetails(playlistTitle) {
  return fetchAPI(`/playlist/${playlistTitle}`);
}
export async function fetchMyPlaylistsMenu(limit?, offset?) {
  const qs = queryString.stringify({
    mode: 'temp_playlists_only',
  });
  return fetchAPI(`/playlist/?${qs}`);

  // return require('./mock/playlists-menu.json');
}
export async function fetchAllMyPlaylists(limit = 5, offset = 0) {
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
  if (idArray.length === 0) {
    return [];
  }
  return fetchAPI(`/oers/`, JSON.stringify({ ids: idArray }), {
    method: 'POST',
  });

  // return require('./mock/featuredList.json');
}
export async function fetchEntityDefinitions(idArray) {
  if (idArray.length === 0) {
    return [];
  }
  const qs = queryString.stringify({
    ids: idArray.join(','),
  });
  return fetchAPI(`/entity_definitions/?${qs}`);

  // return require('./mock/featuredList.json');
}
export async function fetchSearchOERs({ searchTerm, page }) {
  const qs = queryString.stringify({ text: searchTerm, page });
  return fetchAPI(`/search/?${qs}`);
  //https://x5learn.org/api/v1/search/?text=se&page=1

  // return require('./mock/search-se.json');
}
export async function fetchPlaylistLicenses() {
  return fetchAPI(`/license/`);
}

export async function createTempPlaylist(playlist: {
  title?;
  description?;
  license?;
  temp_title;
}) {
  return fetchAPI(
    `/playlist/`,
    JSON.stringify({
      ...playlist,
      is_temp: true,
    }),
    { method: 'POST' },
  );
}
