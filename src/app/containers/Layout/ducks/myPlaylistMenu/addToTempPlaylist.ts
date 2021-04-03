import { createAsyncThunk } from '@reduxjs/toolkit';
import { addToTempPlaylist } from 'app/api/api';

export const addToTempPlaylistThunk = createAsyncThunk<any, any>(
  'playlists/addToTempPlaylist',
  async addData => {
    const { playlistName, oerId } = addData;
    const data = await addToTempPlaylist(playlistName, oerId);
    return data;
  },
);

export const reducers = {
  [addToTempPlaylistThunk.pending.toString()]: (state: any, action) => {
    //state.data = null;
    //state.loading = true;
  },
  [addToTempPlaylistThunk.fulfilled.toString()]: (state: any, action) => {
    const {playlistName, oerId} = action.meta.arg
    const item = state.data.find(item => {

      if (item.title === playlistName) {
        const hasOer = item.oerIds.find(currOer=>{
          return currOer === oerId
        })
        if(!hasOer){
          item.oerIds = [...item.oerIds, oerId]
        }
        return true;
      }
      return false;
    });

    //state.loading = false;
    //state.data = action.payload;
  },
  [addToTempPlaylistThunk.rejected.toString()]: (state: any, action) => {
    //state.loading = false;
    //state.error = action.error;
  },
};
