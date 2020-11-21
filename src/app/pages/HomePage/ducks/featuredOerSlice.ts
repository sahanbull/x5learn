import { createAsyncThunk } from '@reduxjs/toolkit';
import { createSlice } from 'utils/@reduxjs/toolkit';
import { fetchFeaturedOERs } from 'app/api/api';

// The initial state of the GithubRepoForm container
export const initialState: any = {
  data: null,
  loading: false,
  error: null,
};

export const fetchFeaturedOer = createAsyncThunk(
  'oers/fetchFeaturedOer',
  async () => {
    const data = await fetchFeaturedOERs();
    return data;
  },
);

const featuredOerSlice = createSlice({
  name: 'featuredOer',
  initialState,
  reducers:{},
  extraReducers: {
    [fetchFeaturedOer.pending.toString()]: (state: any, action) => {
      state.data = null;
      state.loading = true;
    },
    [fetchFeaturedOer.fulfilled.toString()]: (state: any, action) => {
      state.loading = false;
      state.data = action.payload;
    },
    [fetchFeaturedOer.rejected.toString()]: (state: any, action) => {
      state.loading = false;
      state.error = action.error;
    },
  },
});

export const { actions, reducer, name: sliceKey } = featuredOerSlice;
