import { createAsyncThunk } from '@reduxjs/toolkit';
import { createSlice } from 'utils/@reduxjs/toolkit';
import { fetchFeaturedOERs } from 'app/api/api-mock';

// The initial state of the GithubRepoForm container
export const initialState: any = {
  username: 'react-boilerplate',
  data: [],
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
    [fetchFeaturedOer.fulfilled.toString()]: (state: any, action) => {
      state.data = action.payload;
      debugger
    },
  },
});

export const { actions, reducer, name: sliceKey } = featuredOerSlice;
