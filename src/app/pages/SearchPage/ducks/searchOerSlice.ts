import { createAsyncThunk } from '@reduxjs/toolkit';
import { createSlice } from 'utils/@reduxjs/toolkit';
import { fetchSearchOERs } from 'app/api/api';

// The initial state of the GithubRepoForm container
export const initialState: any = {
  data: null,
  loading: true,
  error: null,
};

export const fetchSearchOerThunk = createAsyncThunk(
  'playlists/fetchSearchOer',
  async (searchParams:{ searchTerm: any; page: any}) => {
    const data = await fetchSearchOERs(searchParams);
    return data;
  },
);

const searchOerSlice = createSlice({
  name: 'searchOer',
  initialState,
  reducers: {},
  extraReducers: {
    [fetchSearchOerThunk.pending.toString()]: (state: any, action) => {
      state.data = null;
      state.loading = true;
      state.error = undefined;
    },
    [fetchSearchOerThunk.fulfilled.toString()]: (state: any, action) => {
      state.loading = false;
      state.data = action.payload;
      state.error = undefined;
    },
    [fetchSearchOerThunk.rejected.toString()]: (state: any, action) => {
      state.loading = false;
      state.error = action.error;
    },
  },
});

export const { actions, reducer, name: sliceKey } = searchOerSlice;
