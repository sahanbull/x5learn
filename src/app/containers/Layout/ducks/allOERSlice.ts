import { Action, createAsyncThunk } from '@reduxjs/toolkit';
import { createSlice } from 'utils/@reduxjs/toolkit';
import { fetchMyPlaylistsMenu, fetchOERs } from 'app/api/api';
import { RootState } from 'types';

// The initial state of the GithubRepoForm container
export const initialState: any = {
  data: null,
  loading: true,
  error: null,
};

export const fetchOERsByIDsThunk = createAsyncThunk<
  any,
  Array<string>,
  { dispatch; getState: () => {} }
>('oers/fetchOERsByIDs', async (oerIDArray, thunkAPI) => {
  const { allOERs } = thunkAPI.getState() as RootState;
  const allOERData = allOERs.data || {};
  const oerMap = {};
  const filteredOERIds = oerIDArray.filter(oerID => {
    if (allOERData[oerID]) {
      oerMap[oerID] = allOERData[oerID];
      return false;
    }
    return true;
  });
  const data = await fetchOERs(filteredOERIds);
  data.forEach((element: { id }) => {
    oerMap[element.id] = element;
  });
  const returnData = oerIDArray.map((id: string | number) => {
    return oerMap[id];
  });
  return returnData;
});

const allOERsSlice = createSlice({
  name: 'allOERs',
  initialState,
  reducers: {},
  extraReducers: {
    [fetchOERsByIDsThunk.pending.toString()]: (state: any, action) => {
      state.loading = true
    },
    [fetchOERsByIDsThunk.fulfilled.toString()]: (state: any, action) => {
      const newOERs: Array<{ id }> = action.payload;
      const stateData = state.data || {};
      newOERs.forEach(oer => {
        stateData[oer.id] = oer;
      });
      state.data = stateData;
      state.loading = false
    },
    [fetchOERsByIDsThunk.rejected.toString()]: (state: any, action) => {
      state.loading = false
    },
  },
});

export const { actions, reducer, name: sliceKey } = allOERsSlice;
