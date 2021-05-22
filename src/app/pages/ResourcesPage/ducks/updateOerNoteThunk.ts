import { createAsyncThunk, createSelector } from '@reduxjs/toolkit';
import { createSlice } from 'utils/@reduxjs/toolkit';
import { updateOerNote } from 'app/api/api';
import { RootState } from 'types';

export const updateOerNoteThunk = createAsyncThunk<
  any,
  { oerID; noteID; noteText }
>('oerNotes/updateOerNote', async ({ oerID, noteID, noteText }, thunkAPI) => {
  const data = await updateOerNote(noteID, noteText);
  return data;
});

export const reducers = {
  [updateOerNoteThunk.pending.toString()]: (state: any, action) => {
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
  [updateOerNoteThunk.fulfilled.toString()]: (state: any, action) => {
    const { noteID, oerID, noteText } = action.meta.arg;
    const oerData = state.data[oerID].data.map(item => {
      if (item.id === noteID) {
        item.text = noteText;
        return item;
      }
      return item;
    });

    const oerState = {
      ...state.data[oerID],
      data: oerData,
    };
    state.data[oerID] = oerState;
    // const { oerID } = action.meta.arg;
    // const oerState = {
    //   data: action.payload,
    //   loading: false,
    //   error: undefined,
    // };
    // state.data[oerID] = oerState;
    // state.loading = false;
    // state.error = undefined;
  },
  [updateOerNoteThunk.rejected.toString()]: (state: any, action) => {
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
