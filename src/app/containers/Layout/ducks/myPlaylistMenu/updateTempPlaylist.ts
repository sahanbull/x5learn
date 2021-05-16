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
    state.isUpdating = true;

    const currArr = state.data.playlist_items;
    const dict = {};
    currArr.forEach(element => {
      dict[element.data] = element;
    });
    const newArr = action.meta.arg.playlist_items.map((oerId, index) => {
      const item = dict[oerId];
      item.order = index;
      return item;
    });
    state.data.playlist_items = newArr;
    state.data.prev_playlist_items = currArr;


  },
  [updateTempPlaylistThunk.fulfilled.toString()]: (state: any, action) => {
    state.isUpdating = false;


    //state.data = action.payload;
  },
  [updateTempPlaylistThunk.rejected.toString()]: (state: any, action) => {
    state.isUpdating = false;

    const currArr = state.data.prev_playlist_items;

    state.data.playlist_items = currArr;
    delete state.data.prev_playlist_items 

    
    //state.error = action.error;
  },
};
