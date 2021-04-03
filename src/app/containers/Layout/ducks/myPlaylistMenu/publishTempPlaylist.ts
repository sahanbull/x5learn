import { createAsyncThunk } from '@reduxjs/toolkit';
import { publishTempPlaylist } from 'app/api/api';

export const publishTempPlaylistThunk = createAsyncThunk<any, any>(
  'playlists/publishTempPlaylist',
  async playlist => {
    const data = await publishTempPlaylist(playlist.tempTitle, playlist);
    return data;
  },
);

export const reducers = {
  [publishTempPlaylistThunk.pending.toString()]: (state: any, action) => {
    //state.data = null;
    //state.loading = true;
  },
  [publishTempPlaylistThunk.fulfilled.toString()]: (state: any, action) => {
    //state.loading = false;
    //state.data = action.payload;
  },
  [publishTempPlaylistThunk.rejected.toString()]: (state: any, action) => {
    //state.loading = false;
    //state.error = action.error;
  },
};
