import { Action, createAsyncThunk, createSelector } from '@reduxjs/toolkit';
import { createSlice } from 'utils/@reduxjs/toolkit';
import { fetchEntityDefinitions } from 'app/api/api';
import { RootState } from 'types';

// The initial state of the GithubRepoForm container
export const initialState: any = {
  data: {},
  // loading: true,
  // error: null,
};

export const fetchEntityDefinitionsByIDsThunk = createAsyncThunk<
  any,
  Array<string>,
  { dispatch; getState: () => {} }
>(
  'entityDefs/fetchEntityDefinitionsByIDs',
  async (entityDefIDArray, thunkAPI) => {
    const { allEntityDefs } = thunkAPI.getState() as RootState;

    const allEntityDefData = allEntityDefs.data || {};
    const entityDefMap = {};
    const filteredEntityDefIds = entityDefIDArray.filter(entityDefID => {
      if (allEntityDefData[entityDefID] && allEntityDefData[entityDefID].data) {
        entityDefMap[entityDefID] = allEntityDefData[entityDefID].data;
        return false;
      }
      return true;
    });
    const data = await fetchEntityDefinitions(filteredEntityDefIds);
    filteredEntityDefIds.forEach(id => {
      entityDefMap[id] = data[id];
    });
    // const returnData = entityDefIDArray.map((id: string | number) => {
    //   return entityDefMap[id];
    // });
    return entityDefMap;
  },
);

const slice = createSlice({
  name: 'allEntityDefs',
  initialState,
  reducers: {},
  extraReducers: {
    [fetchEntityDefinitionsByIDsThunk.pending.toString()]: (
      state: any,
      action,
    ) => {
      const entityDefIds: Array<string> = action.meta.arg;
      entityDefIds.forEach(entityDefId => {
        let entityDef = state.data[entityDefId] || {};
        if (!entityDef.data) {
          entityDef = {
            loading: true,
            error: undefined,
            data: undefined,
          };
        }
        state.data[entityDefId] = entityDef;
      });
    },
    [fetchEntityDefinitionsByIDsThunk.fulfilled.toString()]: (
      state: any,
      action,
    ) => {
      const newEntityDefinitions: object = action.payload;
      const stateData = state.data || {};
      Object.entries(newEntityDefinitions).forEach(entityDef => {
        let entity = stateData[entityDef[0]] || {};

        entity = { loading: false, error: undefined, data: entityDef[1] };
        stateData[entityDef[0]] = entity;
      });
    },
    [fetchEntityDefinitionsByIDsThunk.rejected.toString()]: (
      state: any,
      action,
    ) => {
      const entityDefIds: Array<string> = action.meta.arg;
      entityDefIds.forEach(entityDefId => {
        let entityDef = state.data[entityDefId] || {};
        if (!entityDef.data) {
          entityDef = {
            loading: false,
            error: 'Something went wrong',
            data: undefined,
          };
        }
        state.data[entityDefId] = entityDef;
      });
    },
  },
});

export const selectEntityDefinition = createSelector(
  [
    (state: RootState) => state[slice.name].data || initialState,
    (_, entityDefID) => entityDefID,
  ],
  (entityDefData, entityDefID) => {
    return entityDefData[entityDefID] || { loading: true };
  },
);

export const { actions, reducer, name: sliceKey } = slice;
