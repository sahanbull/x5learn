import { createAsyncThunk } from '@reduxjs/toolkit';
import { createSlice } from 'utils/@reduxjs/toolkit';
import { fetchMyPlaylistsMenu } from 'app/api/api';

// The initial state of the GithubRepoForm container
export const initialState: any = {
  data: null,
  loading: true,
  error: null,
};

export const fetchMyPlaylistsMenuThunk = createAsyncThunk(
  'playlists/fetchMyPlaylistsMemu',
  async () => {
    const data = await fetchMyPlaylistsMenu(5);
    return data;
  },
);

const myPlaylistsMenuSlice = createSlice({
  name: 'myPlaylistsMemu',
  initialState,
  reducers:{},
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
  },
});

export const { actions, reducer, name: sliceKey } = myPlaylistsMenuSlice;
