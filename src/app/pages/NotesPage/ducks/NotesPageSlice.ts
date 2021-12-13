import { createAsyncThunk } from '@reduxjs/toolkit';
import { createSlice } from 'utils/@reduxjs/toolkit';
import { getNotesList } from 'app/api/api';

export const initialState: any = {
  oers: [],
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
      state.oers = [];
      state.loading = true;
      state.error = null;
    },
    [getNotesListThunk.fulfilled.toString()]: (state: any, action) => {
      state.loading = false;
      state.oers = action.payload.oers;
      state.currentOffset = action.meta.arg.offset;
      state.total = action.payload.meta.total;
    },
    [getNotesListThunk.rejected.toString()]: (state: any, action) => {
      state.loading = false;
      state.error = action.error;
    },
  },
});

export const { actions, reducer, name: sliceKey } = getNotesListSlice;
