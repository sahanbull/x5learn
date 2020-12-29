import { createAsyncThunk, isRejectedWithValue } from '@reduxjs/toolkit';
import { createSlice } from 'utils/@reduxjs/toolkit';
import { fetchPlaylistDetails } from 'app/api/api';
import { cat } from 'shelljs';

// The initial state of the GithubRepoForm container
export const initialState: any = {
  data: null,
  loading: true,
  error: null,
};

export const fetchPlaylistDetailsThunk = createAsyncThunk<any, string | number>(
  'oers/fetchPlaylistDetails',
  async (playlistId, thunkAPI) => {
    try {
      const data = await fetchPlaylistDetails(playlistId);
      return data;
    } catch (e) {
      return thunkAPI.rejectWithValue(e);
    }
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
      const msg = action?.payload?.message;
      state.loading = false;
      state.error = { msg, error: action.error };
      state.data = null;
    },
  },
});

export const { actions, reducer, name: sliceKey } = fetchPlaylistDetailSlice;
