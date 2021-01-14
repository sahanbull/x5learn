import { Action, createAsyncThunk } from '@reduxjs/toolkit';
import { createSlice } from 'utils/@reduxjs/toolkit';
import { fetchPlaylistLicenses } from 'app/api/api';
import { RootState } from 'types';

// The initial state of the GithubRepoForm container
export const initialState: any = {
  data: null,
  loading: true,
  error: null,
};

export const fetchPlaylistLicensesThunk = createAsyncThunk<any>(
  'playlistLicense/fetchPlaylistLicenses',
  async () => {
    const data = await fetchPlaylistLicenses();
    return data;
  },
);

const fetchPlaylistLicenseSlice = createSlice({
  name: 'playlistLicenses',
  initialState,
  reducers: {},
  extraReducers: {
    [fetchPlaylistLicensesThunk.pending.toString()]: (state: any, action) => {
      state.loading = true;
      state.data = null;
      state.error = null;
    },
    [fetchPlaylistLicensesThunk.fulfilled.toString()]: (state: any, action) => {
      state.loading = false;
      state.data = action.payload;
      state.error = null;
    },
    [fetchPlaylistLicensesThunk.rejected.toString()]: (state: any, action) => {
      state.loading = false;
      state.data = null;
      state.error = action.payload;

    },
  },
});

export const { actions, reducer, name: sliceKey } = fetchPlaylistLicenseSlice;
