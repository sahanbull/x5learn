import { createAsyncThunk, createSelector } from '@reduxjs/toolkit';
import { createSlice } from 'utils/@reduxjs/toolkit';
import { fetchRelatedOers } from 'app/api/api';
import { RootState } from 'types';

// The initial state of the GithubRepoForm container
export const initialState: any = {
  data: {},
  loading: true,
  error: null,
};

export const fetchRelatedOersThunk = createAsyncThunk<any, { oerID }>(
  'oers/fetchRelatedOers',
  async ({ oerID }, thunkAPI) => {
    const data = await fetchRelatedOers(oerID);
    return data;
  },
);

const fetchRelatedOerslice = createSlice({
  name: 'relatedOers',
  initialState,
  reducers: {},
  extraReducers: {
    [fetchRelatedOersThunk.pending.toString()]: (state: any, action) => {
      const { oerID } = action.meta.arg;
      const oerState = {
        data: null,
        loading: true,
        error: undefined,
      };
      state.data[oerID] = oerState;
      state.loading = true;
      state.error = undefined;
    },
    [fetchRelatedOersThunk.fulfilled.toString()]: (state: any, action) => {
      const { oerID } = action.meta.arg;
      const oerState = {
        data: action.payload,
        loading: false,
        error: undefined,
      };
      state.data[oerID] = oerState;
      state.loading = false;
      state.error = undefined;
    },
    [fetchRelatedOersThunk.rejected.toString()]: (state: any, action) => {
      const { oerID } = action.meta.arg;
      const oerState = {
        data: null,
        loading: false,
        error: action.error,
      };
      state.data = oerState;
      state.loading = false;
      state.error = undefined;
    },
  },
});

export const selectRelatedOers = createSelector(
  [
    (state: RootState) => state[fetchRelatedOerslice.name] || initialState,
    (_, oerID) => oerID,
  ],
  (oerData, oerID) => {
    return (
      oerData?.data[oerID] || {
        data: null,
        loading: true,
        error: undefined,
      }
    );
  },
);

export const { actions, reducer, name: sliceKey } = fetchRelatedOerslice;
