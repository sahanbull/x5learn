import { createAsyncThunk } from '@reduxjs/toolkit';
import { createSlice } from 'utils/@reduxjs/toolkit';
import { fetchLoggedInUserDetail } from 'app/api/api';

// The initial state of the GithubRepoForm container
export const initialState: any = {
  loggedInUser: null,
  loading: true,
  error: null,
};

export const fetchLoggedInUserDetailsThunk = createAsyncThunk(
  'loggedInUserDetails/fetchLoggedInUserDetails',
  async () => {
    const data = await fetchLoggedInUserDetail();
    return data;
  },
);

const fetchLoggedInUserDetailsSlice = createSlice({
  name: 'loggedInUserDetails',
  initialState,
  reducers: {},
  extraReducers: {
    [fetchLoggedInUserDetailsThunk.pending.toString()]: (state: any, action) => {
      state.loggedInUser = null;
      state.loading = true;
    },
    [fetchLoggedInUserDetailsThunk.fulfilled.toString()]: (state: any, action) => {
      state.loading = false;
      state.loggedInUser = action.payload.loggedInUser;
    },
    [fetchLoggedInUserDetailsThunk.rejected.toString()]: (state: any, action) => {
      state.loading = false;
      state.error = action.error;
    },
  },
});

export const { actions, reducer, name: sliceKey } = fetchLoggedInUserDetailsSlice;
