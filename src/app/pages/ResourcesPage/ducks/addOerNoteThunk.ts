import { createAsyncThunk, createSelector } from '@reduxjs/toolkit';
import { createSlice } from 'utils/@reduxjs/toolkit';
import { addOerNote, fetchOerNotes } from 'app/api/api';
import { RootState } from 'types';


export const addOerNoteThunk = createAsyncThunk<any, any>(
  'oerNotes/addOerNote',
  async ({ oerID, noteText }, thunkAPI) => {
    const data = await addOerNote(oerID, noteText);
    const fetchData = await fetchOerNotes(oerID);
    return fetchData;
  },
);

export const reducers = {
  [addOerNoteThunk.pending.toString()]: (state: any, action) => {
    // const { oerID } = action.meta.arg;
    // const oerState = {
    //   data: null,
    //   loading: true,
    //   error: undefined,
    // };
    // state.data[oerID] = oerState;
    // state.loading = true;
    // state.error = undefined;
  },
  [addOerNoteThunk.fulfilled.toString()]: (state: any, action) => {
    const { oerID } = action.meta.arg;
    const oerState = {
      ...state.data[oerID],
      data: action.payload,
      loading: false,
      error: undefined,
    };
    state.data[oerID] = oerState;
    // state.loading = false;
    // state.error = undefined;
  },
  [addOerNoteThunk.rejected.toString()]: (state: any, action) => {
    // const { oerID } = action.meta.arg;
    // const oerState = {
    //   data: null,
    //   loading: false,
    //   error: action.error,
    // };
    // state.data = oerState;
    // state.loading = false;
    // state.error = undefined;
  },
};
