import { createAsyncThunk } from '@reduxjs/toolkit';
import { createSlice } from 'utils/@reduxjs/toolkit';
import { getUserHistory, fetchOERs } from 'app/api/api';
import { RootState } from 'types';

export const initialState: any = {
  oers: [],
  loading: false,
  error: null,
  currentOffset: 0,
  total: 1,
};

export const getUserHistoryThunk = createAsyncThunk<any, any>(
  'historyPage/getUserHistory',
  async options => {
    const data = await getUserHistory(
      options.sort,
      options.limit,
      options.offset,
    );
    return data;
  },
);

const getUserHistorySlice = createSlice({
  name: 'historyPage',
  initialState,
  reducers: {},
  extraReducers: {
    [getUserHistoryThunk.pending.toString()]: (state: any, action) => {
      state.oers = [];
      state.loading = true;
      state.error = null;
    },
    [getUserHistoryThunk.fulfilled.toString()]: (state: any, action) => {
      state.loading = false;
      state.oers = action.payload.oers;
      state.currentOffset = action.meta.arg.offset;
      state.total = action.payload.meta.total;
    },
    [getUserHistoryThunk.rejected.toString()]: (state: any, action) => {
      state.loading = false;
      state.error = action.error;
    },
  },
});

export const { actions, reducer, name: sliceKey } = getUserHistorySlice;
