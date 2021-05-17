import { createAsyncThunk, isRejectedWithValue } from '@reduxjs/toolkit';
import { createSlice } from 'utils/@reduxjs/toolkit';
import { fetchTempPlaylistDetails } from 'app/api/api';
import { reducers as updateTempPlaylistReducers } from 'app/containers/Layout/ducks/myPlaylistMenu/updateTempPlaylist';
import { reducers as optimizeTempPlaylistPathReducers } from 'app/containers/Layout/ducks/myPlaylistMenu/optimizeTempPlaylistPath';

// The initial state of the GithubRepoForm container
export const initialState: any = {
  data: null,
  loading: true,
  error: null,
  isUpdating: false,
};

export const fetchTempPlaylistDetailsThunk = createAsyncThunk<
  any,
  string | number
>('oers/fetchTempPlaylistDetails', async (playlistTitle, thunkAPI) => {
  try {
    const data = await fetchTempPlaylistDetails(playlistTitle);
    return data;
  } catch (e) {
    return thunkAPI.rejectWithValue(e);
  }
});

const fetchTempPlaylistDetailSlice = createSlice({
  name: 'tempPlaylistDetail',
  initialState,
  reducers: {},
  extraReducers: {
    [fetchTempPlaylistDetailsThunk.pending.toString()]: (
      state: any,
      action,
    ) => {
      state.data = null;
      state.loading = true;
      state.error = undefined;
    },
    [fetchTempPlaylistDetailsThunk.fulfilled.toString()]: (
      state: any,
      action,
    ) => {
      state.loading = false;
      state.data = action.payload;
      state.error = undefined;
    },
    [fetchTempPlaylistDetailsThunk.rejected.toString()]: (
      state: any,
      action,
    ) => {
      const msg = action?.payload?.message;
      state.loading = false;
      state.error = { msg, error: action.error };
      state.data = null;
    },
    ...updateTempPlaylistReducers,
    ...optimizeTempPlaylistPathReducers,
  },
});

export const {
  actions,
  reducer,
  name: sliceKey,
} = fetchTempPlaylistDetailSlice;
