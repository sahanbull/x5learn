import { PayloadAction, createSelector, createSlice } from '@reduxjs/toolkit';

export const initialState: any = {
  unveilAi: false,
};

const unveilAiSlice = createSlice({
  name: 'header',
  initialState,
  reducers: {
    changeUnveilAi(state, action: PayloadAction<any>) {
      state.unveilAi = action.payload;
    },
  },
});

export const selectUnveilAi = createSelector(
  [(state: any) => state.header || initialState],
  header => header.unveilAi,
);

export const { changeUnveilAi } = unveilAiSlice.actions;
export const reducer = unveilAiSlice.reducer;
export const unveilAiSliceKey = unveilAiSlice.name;
