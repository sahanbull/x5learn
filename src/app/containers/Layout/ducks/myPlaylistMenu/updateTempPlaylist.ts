import { createAsyncThunk } from '@reduxjs/toolkit';
import { updateTempPlaylist } from 'app/api/api';

export const updateTempPlaylistThunk = createAsyncThunk<any, any>(
  'playlists/updateTempPlaylist',
  async saveData => {
    const data = await updateTempPlaylist(saveData.temp_title, saveData);
    return data;
  },
);

export const reducers = {
  [updateTempPlaylistThunk.pending.toString()]: (state: any, action) => {
    //state.data = null;
    //state.loading = true;
  },
  [updateTempPlaylistThunk.fulfilled.toString()]: (state: any, action) => {
    //state.loading = false;
    //state.data = action.payload;
  },
  [updateTempPlaylistThunk.rejected.toString()]: (state: any, action) => {
    //state.loading = false;
    //state.error = action.error;
  },
};
