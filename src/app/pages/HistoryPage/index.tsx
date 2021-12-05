import React, { useEffect, useState } from 'react';
import { Helmet } from 'react-helmet-async';
import { Button } from 'antd';
import { AppLayout } from 'app/containers/Layout/AppLayout';
import { useInjectReducer } from 'redux-injectors';
import { useDispatch, useSelector } from 'react-redux';
import {
  sliceKey as loggedInUserDetailsSliceKey,
  reducer as loggedInUserDetailsReducer,
  fetchLoggedInUserDetailsThunk,
} from 'app/containers/Layout/ducks/loggedInUserDetailsSlice';
import { useTranslation } from 'react-i18next';
import { Image } from 'antd';
import { Form, Input, Checkbox, Switch } from 'antd';
import {
  updateProfileThunk,
  sliceKey as updateProfileSliceKey,
  reducer as updateProfileReducer,
} from './ducks/ProfilePageSlice';

export function HistoryPage() {
  const dispatch = useDispatch();

  const { t } = useTranslation();

  return (
    <>
      <Helmet>
        <title>x5learn</title>
      </Helmet>
      <AppLayout className="profile-page">
        <div style={{ padding: '25px' }}>
          <h2>History page</h2>
        </div>
      </AppLayout>
    </>
  );
}
