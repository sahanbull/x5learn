import { createAsyncThunk } from '@reduxjs/toolkit';
import { createSlice } from 'utils/@reduxjs/toolkit';
import { createTempPlaylist, fetchMyPlaylistsMenu } from 'app/api/api';
import { reducers as deleteTempPlaylistReducers } from './myPlaylistMenu/deleteTempPlaylist';
import { reducers as publishTempPlaylistReducers } from './myPlaylistMenu/publishTempPlaylist';
import { reducers as updateTempPlaylistReducers } from './myPlaylistMenu/updateTempPlaylist';
import { reducers as addToTempPlaylistReducers } from './myPlaylistMenu/addToTempPlaylist';

// The initial state of the GithubRepoForm container
export const initialState: any = {
  data: null,
  loading: true,
  error: null,
};

export const fetchMyPlaylistsMenuThunk = createAsyncThunk(
  'playlists/fetchMyPlaylistsMenu',
  async () => {
    const data = await fetchMyPlaylistsMenu();
    return data;
  },
);
export const createTempPlaylistThunk = createAsyncThunk<any, any>(
  'playlists/createTempPlaylist',
  async playlist => {
    const data = await createTempPlaylist(playlist);
    return data;
  },
);

const myPlaylistsMenuSlice = createSlice({
  name: 'myPlaylistsMenu',
  initialState,
  reducers: {},
  extraReducers: {
    [fetchMyPlaylistsMenuThunk.pending.toString()]: (state: any, action) => {
      state.data = null;
      state.loading = true;
    },
    [fetchMyPlaylistsMenuThunk.fulfilled.toString()]: (state: any, action) => {
      state.loading = false;
      state.data = action.payload;
    },
    [fetchMyPlaylistsMenuThunk.rejected.toString()]: (state: any, action) => {
      state.loading = false;
      state.error = action.error;
    },
    ...deleteTempPlaylistReducers,
    ...publishTempPlaylistReducers,
    ...updateTempPlaylistReducers,
    ...addToTempPlaylistReducers,
  },
});

export const { actions, reducer, name: sliceKey } = myPlaylistsMenuSlice;
