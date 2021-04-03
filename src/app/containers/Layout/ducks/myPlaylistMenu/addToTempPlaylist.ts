import { createAsyncThunk } from '@reduxjs/toolkit';
import { addToTempPlaylist } from 'app/api/api';

export const addToTempPlaylistThunk = createAsyncThunk<any, any>(
  'playlists/addToTempPlaylist',
  async addData => {
    const data = await addToTempPlaylist(addData);
    return data;
  },
);

export const reducers = {
  [addToTempPlaylistThunk.pending.toString()]: (state: any, action) => {
    //state.data = null;
    //state.loading = true;
  },
  [addToTempPlaylistThunk.fulfilled.toString()]: (state: any, action) => {
    //state.loading = false;
    //state.data = action.payload;
  },
  [addToTempPlaylistThunk.rejected.toString()]: (state: any, action) => {
    //state.loading = false;
    //state.error = action.error;
  },
};
