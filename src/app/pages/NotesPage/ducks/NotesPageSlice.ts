import { createAsyncThunk } from '@reduxjs/toolkit';
import { createSlice } from 'utils/@reduxjs/toolkit';
import { getNotesList } from 'app/api/api';

export const initialState: any = {
  notes: [],
  loading: false,
  error: null,
  currentOffset: 0,
  total: 1,
};

export const getNotesListThunk = createAsyncThunk<any, any>(
  'notesPage/getNotesList',
  async options => {
    const data = await getNotesList(
      options.sort,
      options.limit,
      options.offset,
    );
    return data;
  },
);

const getNotesListSlice = createSlice({
  name: 'notesPage',
  initialState,
  reducers: {},
  extraReducers: {
    [getNotesListThunk.pending.toString()]: (state: any, action) => {
      state.notes = [];
      state.loading = true;
      state.error = null;
    },
    [getNotesListThunk.fulfilled.toString()]: (state: any, action) => {
      state.loading = false;
      state.notes = action.payload.notes;
      state.currentOffset = action.payload.meta.current;
      state.total = action.payload.meta.total;
    },
    [getNotesListThunk.rejected.toString()]: (state: any, action) => {
      state.loading = false;
      state.error = action.error;
    },
  },
});

export const { actions, reducer, name: sliceKey } = getNotesListSlice;
