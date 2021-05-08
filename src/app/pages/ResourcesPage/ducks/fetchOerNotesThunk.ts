import { createAsyncThunk, createSelector } from '@reduxjs/toolkit';
import { createSlice } from 'utils/@reduxjs/toolkit';
import { fetchOerNotes } from 'app/api/api';
import { RootState } from 'types';

// The initial state of the GithubRepoForm container
export const initialState: any = {
  data: {},
  loading: true,
  error: null,
};

export const fetchOerNotesThunk = createAsyncThunk<any, { oerID: string }>(
  'oerNotes/fetchOerNotes',
  async ({ oerID }, thunkAPI) => {
    const data = await fetchOerNotes(oerID);
    return data;
  },
);

const fetchOerNoteslice = createSlice({
  name: 'oerNotes',
  initialState,
  reducers: {},
  extraReducers: {
    [fetchOerNotesThunk.pending.toString()]: (state: any, action) => {
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
    [fetchOerNotesThunk.fulfilled.toString()]: (state: any, action) => {
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
    [fetchOerNotesThunk.rejected.toString()]: (state: any, action) => {
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

export const selectOerNotes = createSelector(
  [
    (state: RootState) => state[fetchOerNoteslice.name] || initialState,
    (_, oerID) => oerID,
  ],
  (oerData, oerID) => {
    return oerData || initialState;
    // return oerData[oerID] || initialState;
  },
);

export const { actions, reducer, name: sliceKey } = fetchOerNoteslice;
