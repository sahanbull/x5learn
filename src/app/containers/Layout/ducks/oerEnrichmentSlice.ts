import { createAsyncThunk } from '@reduxjs/toolkit';
import { createSlice } from 'utils/@reduxjs/toolkit';
import { fetchMyPlaylistsMenu, fetchWikiEnrichments } from 'app/api/api';

// The initial state of the GithubRepoForm container
export const initialState: any = {
  data: null,
  loading: true,
  error: null,
};

export const fetchOerEnrichmentThunk = createAsyncThunk<any, string>(
  'enrichment/fetchOerEnrichment',
  async (oerID, thunkAPI) => {
    const data = await fetchWikiEnrichments([oerID]);
    return data;
  },
);

const myPlaylistsMenuSlice = createSlice({
  name: 'oerEnrichment',
  initialState,
  reducers: {},
  extraReducers: {
    [fetchOerEnrichmentThunk.pending.toString()]: (state: any, action) => {
      state.data = null;
      state.loading = true;
    },
    [fetchOerEnrichmentThunk.fulfilled.toString()]: (state: any, action) => {
      state.loading = false;
      state.data = action.payload;
    },
    [fetchOerEnrichmentThunk.rejected.toString()]: (state: any, action) => {
      state.loading = false;
      state.error = action.error;
    },
  },
});

export const { actions, reducer, name: sliceKey } = myPlaylistsMenuSlice;
