import { createAsyncThunk } from '@reduxjs/toolkit';
import { createSlice } from 'utils/@reduxjs/toolkit';
import { updateProfile } from 'app/api/api';

export const initialState: any = {
  loading: false,
  error: null,
};

export const updateProfileThunk = createAsyncThunk<any, any>(
  'profilePage/updateProfile',
  async values => {
    const data = await updateProfile(values);
    return data;
  },
);

const updateProfileSlice = createSlice({
  name: 'profilePage',
  initialState,
  reducers: {},
  extraReducers: {
    [updateProfileThunk.pending.toString()]: (state: any, action) => {
      state.loading = true;
    },
    [updateProfileThunk.fulfilled.toString()]: (state: any, action) => {
      state.loading = false;
    },
    [updateProfileThunk.rejected.toString()]: (state: any, action) => {
      state.loading = false;
      state.error = action.error;
    },
  },
});

export const { actions, reducer, name: sliceKey } = updateProfileSlice;
