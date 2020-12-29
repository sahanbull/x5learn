import React, { useEffect, useState } from 'react';
import { Helmet } from 'react-helmet-async';
import { Row, Col, Card, Typography, Button, Progress, Spin } from 'antd';
import { AppLayout } from 'app/containers/Layout/AppLayout';
import { UploadOutlined } from '@ant-design/icons';
import { OerCardList } from '../HomePage/components/FeaturedOER/OerCardList';
import { useInjectReducer } from 'redux-injectors';
import { useDispatch, useSelector } from 'react-redux';
import {
  fetchPlaylistDetailsThunk,
  sliceKey,
  reducer,
} from './ducks/fetchPlaylistDetailsThunk';
import { fetchOERsByIDsThunk } from 'app/containers/Layout/ducks/allOERSlice';
import { Action, AsyncThunkAction, unwrapResult } from '@reduxjs/toolkit';

const { Title, Text } = Typography;

export function ResourcesPage(props) {
  useInjectReducer({ key: sliceKey, reducer: reducer });
  const dispatch = useDispatch();
  const oerID = props.match?.params?.id;

  const [oerData, setOERData] = useState<{
    data: null | any[];
    loading: boolean;
    error: null | any;
  }>({
    data: null,
    loading: true,
    error: null,
  });

  const loadOERIdDetails = async () => {
    setOERData({ data: null, loading: true, error: null });
    try {
      const oerResult = (await dispatch(fetchOERsByIDsThunk([oerID]))) as any;
      const resolvedData = await unwrapResult(oerResult);
      setOERData({ data: resolvedData[0], loading: false, error: null });
    } catch (e) {
      setOERData({ data: null, loading: false, error: e });
    }
  };

  useEffect(() => {
    loadOERIdDetails();
  }, [dispatch, oerID]);

  // useEffect(() => {
  //   if (data) {
  //     loadOERIds();
  //   }
  // }, [data]);

  return (
    <>
      <Helmet>
        <title>Playlists Page</title>
        <meta name="description" content="X5 Learn AI based learning" />
      </Helmet>
      <AppLayout>
        {oerData.loading && (
          <Spin spinning={oerData.loading} delay={200}></Spin>
        )}
        {oerData.data && (
          <>
            <Row gutter={[16, 16]}>Row</Row>
          </>
        )}
      </AppLayout>
    </>
  );
}
