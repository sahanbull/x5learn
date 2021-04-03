import { createAsyncThunk } from '@reduxjs/toolkit';
import { deleteTempPlaylist } from 'app/api/api';

export const deleteTempPlaylistThunk = createAsyncThunk<any, any>(
  'playlists/deleteTempPlaylist',
  async playlistName => {
    const data = await deleteTempPlaylist(playlistName);
    return data;
  },
);

export const reducers = {
  [deleteTempPlaylistThunk.pending.toString()]: (state: any, action) => {
    //state.data = null;
    //state.loading = true;
  },
  [deleteTempPlaylistThunk.fulfilled.toString()]: (state: any, action) => {
    //state.loading = false;
    //state.data = action.payload;
  },
  [deleteTempPlaylistThunk.rejected.toString()]: (state: any, action) => {
    //state.loading = false;
    //state.error = action.error;
  },
};
