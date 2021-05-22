import { createAsyncThunk, createSelector } from '@reduxjs/toolkit';
import { createSlice } from 'utils/@reduxjs/toolkit';
import { deleteOerNote } from 'app/api/api';
import { RootState } from 'types';

export const deleteOerNoteThunk = createAsyncThunk<any, any>(
  'oerNotes/deleteOerNote',
  async ({ noteID, oerID }, thunkAPI) => {
    const data = await deleteOerNote(noteID);
    return data;
  },
);

export const reducers = {
  [deleteOerNoteThunk.pending.toString()]: (state: any, action) => {
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
  [deleteOerNoteThunk.fulfilled.toString()]: (state: any, action) => {
    const { noteID, oerID } = action.meta.arg;
    const oerData = state.data[oerID].data.filter(item => item.id !== noteID);

    const oerState = {
      ...state.data[oerID],
      data: oerData,
    };
    state.data[oerID] = oerState;
    // const oerState = {
    //   data: action.payload,
    //   loading: false,
    //   error: undefined,
    // };
    // state.data[oerID] = oerState;
    // state.loading = false;
    // state.error = undefined;
  },
  [deleteOerNoteThunk.rejected.toString()]: (state: any, action) => {
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
