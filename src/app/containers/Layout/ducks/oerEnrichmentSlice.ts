import { createAsyncThunk, createSelector } from '@reduxjs/toolkit';
import { createSlice } from 'utils/@reduxjs/toolkit';
import { fetchMyPlaylistsMenu, fetchWikiEnrichments } from 'app/api/api';
import { RootState } from 'types';

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

const slice = createSlice({
  name: 'oerEnrichment',
  initialState,
  reducers: {},
  extraReducers: {
    [fetchOerEnrichmentThunk.pending.toString()]: (state: any, action) => {
      const oerID = action.meta.arg;
      const obj = {
        data: null,
        loading: true,
        error: null,
      };
      state[oerID] = obj;
    },
    [fetchOerEnrichmentThunk.fulfilled.toString()]: (state: any, action) => {
      const oerID = action.meta.arg;
      const obj = {
        data: action.payload[0],
        loading: false,
        error: null,
      };
      state[oerID] = obj;
    },
    [fetchOerEnrichmentThunk.rejected.toString()]: (state: any, action) => {
      const oerID = action.meta.arg;
      const obj = {
        data: null,
        loading: false,
        error: action.error,
      };
      state[oerID] = obj;
    },
  },
});

export const selectOerEnrichment = createSelector(
  [
    (state: RootState) => state[slice.name] || initialState,
    (_, oerID) => oerID,
  ],
  (oerData, oerID) => {
    return oerData[oerID] || initialState;
  },
);

export const { actions, reducer, name: sliceKey } = slice;
