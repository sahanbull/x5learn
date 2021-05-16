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
import { useTranslation } from 'react-i18next';

const { Title, Text } = Typography;

export function PlaylistsPage(props) {
  useInjectReducer({ key: sliceKey, reducer: reducer });
  const dispatch = useDispatch();
  const { t } = useTranslation();
  const { data, loading, error } = useSelector((state: any) => {
    return state.playlistDetail;
  });
  const [oerData, setOERData] = useState<{
    data: null | any[];
    loading: boolean;
    error: null | any;
  }>({
    data: null,
    loading: true,
    error: null,
  });

  const loadOERIds = async () => {
    setOERData({ data: null, loading: true, error: null });
    try {
      const oerResult = (await dispatch(
        fetchOERsByIDsThunk(data.oerIds),
      )) as any;
      const resolvedData = await unwrapResult(oerResult);
      setOERData({ data: resolvedData, loading: false, error: null });
    } catch (e) {
      setOERData({ data: null, loading: false, error: data.payload });
    }
  };

  const playlistID = props.match?.params?.id;
  useEffect(() => {
    dispatch(fetchPlaylistDetailsThunk(playlistID));
  }, [dispatch, playlistID]);

  useEffect(() => {
    if (data) {
      loadOERIds();
    }
  }, [data]);

  return (
    <>
      <Helmet>
        <title>{data?.title}</title>
        <meta name="description" content={data?.description} />
      </Helmet>
      <AppLayout>
        {loading && <Spin spinning={loading} delay={200}></Spin>}
        {error && <div>{t('alerts.lbl_load_playlist_error')}</div>}
        {error && error.msg && error.msg.result}
        {data && (
          <>
            <Row gutter={[16, 16]}>
              <Col span={24}>
                <Card
                  headStyle={{ border: 'none' }}
                  title={<Title level={2}>{data.title}</Title>}
                  extra={<></>}
                >
                  <p>{data.description}</p>
                  <Text strong>{data.oerIds.length}</Text>
                  <Text>
                    {' '}
                    {t('playlist.lbl_playlist_oer_material_count')}
                  </Text>{' '}
                  {` / `}
                  <Text strong>
                    {t('playlist.lbl_playlist_updated_date')}:{' '}
                  </Text>
                  <Text>
                    {new Date(data.last_updated_at).toLocaleDateString(
                      'en-US',
                      { year: 'numeric', month: 'long', day: 'numeric' },
                    )}
                  </Text>
                  <br />
                </Card>
              </Col>
              {/* <Col span={8}>
                <Card
                  style={{ backgroundColor: '#00ad57', color: `#ffffff` }}
                  headStyle={{ border: 'none', color: `#ffffff` }}
                  title={`Progress`}
                  extra={<a href="#">More</a>}
                >
                  <Text style={{ color: `#ffffff` }}>
                    {' '}
                    You currently <strong>completed 55%</strong> of your
                    learning path.
                  </Text>
                  <br />
                  <Progress
                    percent={55}
                    strokeColor={`#008c41`}
                    showInfo={false}
                  />
                  <Text style={{ color: `#ffffff` }}>
                    {' '}
                    Our algorithm has changed the sequence of your items to help
                    you learn better!
                  </Text>
                  <br />
                  <Button style={{ color: `#ffffff` }} type="link">
                    Undo
                  </Button>
                </Card>
              </Col> */}
            </Row>
            <br />
            <OerCardList {...oerData} playlistID={playlistID} />
          </>
        )}
      </AppLayout>
    </>
  );
}
