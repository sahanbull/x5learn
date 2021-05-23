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

  if (method !== 'GET') {
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
    // console.log('error', err);
    throw err;
  }
  // console.log(jsonResponse);
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
export async function fetchOerNotes(oerID) {
  const qs = queryString.stringify({ oer_id: oerID });
  return fetchAPI(`/note/?${qs}`);
}

export async function addOerNote(oerID, note) {
  return fetchAPI(
    `/note/`,
    JSON.stringify({
      oer_id: oerID,
      text: note,
    }),
    {
      method: 'POST',
    },
  );
}
export async function updateOerNote(noteID, note) {
  const qs = queryString.stringify({ text: note });
  return fetchAPI(`/note/${noteID}?${qs}`, JSON.stringify({}), {
    method: 'PUT',
  });
}
export async function deleteOerNote(noteID) {
  return fetchAPI(`/note/${noteID}`, JSON.stringify({}), {
    method: 'DELETE',
  });
}
export async function getOerNote(noteID) {
  return fetchAPI(`/note/${noteID}`);
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
export async function fetchRelatedOers(oerID) {
  const qs = queryString.stringify({ oerId: oerID });
  return fetchAPI(`/recommendations/?${qs}`);
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

export async function deleteTempPlaylist(playlistName) {
  return fetchAPI(`/playlist/${playlistName}`, JSON.stringify({}), {
    method: 'DELETE',
  });
}
export async function publishTempPlaylist(
  temp_title,
  playlist: {
    title?;
    description?;
    license?;
    author;
    playlist_items: Array<number>;
  },
) {
  return fetchAPI(
    `/playlist/`,
    JSON.stringify({
      is_temp: false,
      parent: 0,
      license: 0,
      is_visible: true,
      temp_title,
      ...playlist,
    }),
    { method: 'POST' },
  );
}
export async function updateTempPlaylist(
  temp_title,
  playlist: {
    title?;
    description?;
    license?;
    author;
    playlist_items: Array<number>;
    playlist_item_data;
  },
) {
  return fetchAPI(
    `/playlist/${temp_title}`,
    JSON.stringify({
      is_temp: true,
      parent: 0,
      license: 0,
      is_visible: true,
      temp_title,
      ...playlist,
    }),
    { method: 'PUT' },
  );
}
export async function addToTempPlaylist(playlistName, oerId) {
  return fetchAPI(
    `/playlist/${playlistName}`,
    JSON.stringify({
      oer_id: oerId,
    }),
    { method: 'POST' },
  );
}
export async function optimizeTempPlaylistPath(tempPlaylistName, oerIds) {
  return fetchAPI(
    `/course_optimization/${tempPlaylistName}`,
    JSON.stringify({
      oerIds,
    }),
    { method: 'POST' },
  );
}
export async function getSupportedLangs() {
  return fetchAPI(`/localization/`);
}
export async function getTranslations(lang) {
  return fetchAPI(`/localization/?language=${lang}`, JSON.stringify({}), {
    method: 'POST',
  });
}
