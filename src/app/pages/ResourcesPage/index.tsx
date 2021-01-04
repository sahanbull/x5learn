import React, { useCallback, useEffect, useState } from 'react';
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

const imageBaseURL = 'https://qa.x5learn.org/files/thumbs/';

export function ResourcesPage(props) {
  useInjectReducer({ key: sliceKey, reducer: reducer });
  const dispatch = useDispatch();
  const oerID = props.match?.params?.id;

  const [oerData, setOERData] = useState<{
    data: {
      date: string;
      description: string;
      duration: string;
      durationInSeconds: number;
      id: number | string;
      images: string[];
      material_id: number | string;
      mediatype: 'text' | 'video';
      provider: string;
      title: string;
      url: string;
    } | null;
    loading: boolean;
    error: null | any;
  }>({
    data: null,
    loading: true,
    error: null,
  });

  const loadOERIdDetails = async _oerID => {
    setOERData({ data: null, loading: true, error: null });
    try {
      const oerResult = (await dispatch(fetchOERsByIDsThunk([_oerID]))) as any;
      const resolvedData = await unwrapResult(oerResult);
      setOERData({ data: resolvedData[0], loading: false, error: null });
    } catch (e) {
      setOERData({ data: null, loading: false, error: e });
    }
  };

  useEffect(() => {
    loadOERIdDetails(oerID);
  }, [dispatch, oerID]);

  // useEffect(() => {
  //   if (data) {
  //     loadOERIds();
  //   }
  // }, [data]);
  const { data, loading, error } = oerData;
  return (
    <>
      <Helmet>
        <title>{data?.title}</title>
        <meta name="description" content={data?.description} />
      </Helmet>
      <AppLayout>
        {loading && <Spin spinning={loading} delay={200}></Spin>}
        {data && (
          <>
            <Row gutter={[16, 16]}>
              <Col>
                {data.mediatype === 'video' && (
                  <video width="100%" controls>
                    <source src={data.url} type="video/mp4" />
                    Your browser does not support the video tag.
                  </video>
                )}

                {data.mediatype === 'text' && (
                  <img
                    width="100%"
                    alt={data.title}
                    src={`${imageBaseURL}/${data?.images[0]}`}
                  />
                )}
              </Col>
              <Col>
                <Card
                  headStyle={{ border: 'none' }}
                  title={<Title level={2}>{data.title}</Title>}
                  extra={
                    <>
                      <Button
                        type="primary"
                        shape="round"
                        icon={<UploadOutlined />}
                        size="large"
                      >
                        Bookmark
                      </Button>{' '}
                      <Button
                        type="primary"
                        shape="round"
                        icon={<UploadOutlined />}
                        size="large"
                      >
                        Add to Playlist
                      </Button>
                    </>
                  }
                >
                  <Text strong>By: </Text>
                  <Text>{data.provider}</Text> {` / `}
                  <Text strong>Language: </Text>
                  <Text>{data.mediatype}</Text> {` / `}
                  <Text strong>Date: </Text>
                  <Text>
                    {new Date(data.date).toLocaleDateString('en-US', {
                      year: 'numeric',
                      month: 'long',
                      day: 'numeric',
                    })}
                  </Text>
                  <br />
                  <p>{data.description}</p>
                </Card>
              </Col>
            </Row>
          </>
        )}
      </AppLayout>
    </>
  );
}
