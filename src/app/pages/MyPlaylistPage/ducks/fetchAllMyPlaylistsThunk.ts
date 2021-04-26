import { createAsyncThunk } from '@reduxjs/toolkit';
import { createSlice } from 'utils/@reduxjs/toolkit';
import { fetchAllMyPlaylists } from 'app/api/api';

// The initial state of the GithubRepoForm container
export const initialState: any = {
  data: null,
  loading: true,
  error: null,
  metadata: null
};

export const fetchAllMyPlaylistsThunk = createAsyncThunk<any, any>(
  'playlist/fetchAllMyPlaylists',
  async ({limit, offset}, thunkAPI) => {
    const data = await fetchAllMyPlaylists(limit, offset);
    return data;
  },
);

const fetchAllMyPlaylistsSlice = createSlice({
  name: 'allMyPlaylists',
  initialState,
  reducers: {},
  extraReducers: {
    [fetchAllMyPlaylistsThunk.pending.toString()]: (state: any, action) => {
      state.data = null;
      state.loading = true;
      state.error = undefined;
    },
    [fetchAllMyPlaylistsThunk.fulfilled.toString()]: (state: any, action) => {
      state.loading = false;
      state.data = action.payload.playlists;
      state.metadata = action.payload.metadata;
      state.error = undefined;
    },
    [fetchAllMyPlaylistsThunk.rejected.toString()]: (state: any, action) => {
      state.loading = false;
      state.error = action.error;
      state.data = null;
    },
  },
});

export const { actions, reducer, name: sliceKey } = fetchAllMyPlaylistsSlice;
