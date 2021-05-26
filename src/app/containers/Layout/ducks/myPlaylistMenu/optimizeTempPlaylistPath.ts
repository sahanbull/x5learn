import { createAction, createAsyncThunk } from '@reduxjs/toolkit';
import { optimizeTempPlaylistPath, updateTempPlaylist } from 'app/api/api';

export const optimizeTempPlaylistPathThunk = createAsyncThunk<any, any>(
  'playlists/optimizeTempPlaylistPath',
  async ({ tempPlaylistName, oerIds }) => {
    const data = await optimizeTempPlaylistPath(tempPlaylistName, oerIds);
    return data;
  },
);

export const acceptOptimizedSequenceAction = createAction<{
  tempPlaylistName;
  optimizedOedIdOrder;
}>('playlists/acceptOptimizedSequence');

// export const undoOptimizedTempPlaylistPathThunk = createAsyncThunk<any, any>(
//   'playlists/undoOptimizedTempPlaylistPathThunk',
//   async ({ saveData }) => {
//     const data = await updateTempPlaylist(saveData.temp_title, saveData);
//     return data;
//   },
// );

export const reducers = {
  [acceptOptimizedSequenceAction.toString()]: (state: any, action) => {
    const { tempPlaylistName, optimizedOedIdOrder } = action.payload;
    state.isUpdating = true;
    const idMap = {};
    const { playlist_items } = state.data;
    playlist_items?.forEach(element => {
      idMap[element.oer_id] = element;
    });


    const newPlaylistMap = optimizedOedIdOrder.map(element => {
      return idMap[element];
    });
    // debugger

    state.data.playlist_items = newPlaylistMap;

    // state.isUpdating = true;

  },
  [optimizeTempPlaylistPathThunk.pending.toString()]: (state: any, action) => {
    //state.data = null;
    state.isUpdating = true;

    // const currArr = state.data.playlist_items;
    // const dict = {};
    // currArr.forEach(element => {
    //   dict[element.data] = element;
    // });
    // const newArr = action.meta.arg.playlist_items.map((oerId, index) => {
    //   const item = dict[oerId];
    //   item.order = index;
    //   return item;
    // });
    // state.data.playlist_items = newArr;
    // state.data.prev_playlist_items = currArr;
  },
  [optimizeTempPlaylistPathThunk.fulfilled.toString()]: (
    state: any,
    action,
  ) => {
    state.isUpdating = false;

    //state.data = action.payload;
  },
  [optimizeTempPlaylistPathThunk.rejected.toString()]: (state: any, action) => {
    state.isUpdating = false;

    // const currArr = state.data.prev_playlist_items;

    // state.data.playlist_items = currArr;
    // delete state.data.prev_playlist_items

    //state.error = action.error;
  },
};
