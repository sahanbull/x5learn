import { createAsyncThunk } from '@reduxjs/toolkit';
import { createSlice } from 'utils/@reduxjs/toolkit';
import { fetchPlaylistDetails } from 'app/api/api';

// The initial state of the GithubRepoForm container
export const initialState: any = {
  data: null,
  loading: true,
  error: null,
};

export const fetchPlaylistDetailsThunk = createAsyncThunk<any, string | number>(
  'oers/fetchPlaylistDetails',
  async (playlistId, thunkAPI) => {
    const data = await fetchPlaylistDetails(playlistId);
    return data;
  },
);

const fetchPlaylistDetailSlice = createSlice({
  name: 'playlistDetail',
  initialState,
  reducers: {},
  extraReducers: {
    [fetchPlaylistDetailsThunk.pending.toString()]: (state: any, action) => {
      state.data = null;
      state.loading = true;
      state.error = undefined;
    },
    [fetchPlaylistDetailsThunk.fulfilled.toString()]: (state: any, action) => {
      state.loading = false;
      state.data = action.payload;
      state.error = undefined;
    },
    [fetchPlaylistDetailsThunk.rejected.toString()]: (state: any, action) => {
      state.loading = false;
      state.error = action.error;
      state.data = null;
    },
  },
});

export const { actions, reducer, name: sliceKey } = fetchPlaylistDetailSlice;
