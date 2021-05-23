import React, { useCallback, useEffect, useRef, useState } from 'react';
import { Helmet } from 'react-helmet-async';
import {
  Row,
  Col,
  Card,
  Typography,
  Button,
  Progress,
  Spin,
  Space,
} from 'antd';
import { AppLayout } from 'app/containers/Layout/AppLayout';
import { AntDesignOutlined, UploadOutlined } from '@ant-design/icons';
import { OerCardList } from '../HomePage/components/FeaturedOER/OerCardList';
import { useInjectReducer } from 'redux-injectors';
import { useDispatch, useSelector } from 'react-redux';
import { sliceKey, reducer } from './ducks/fetchPlaylistDetailsThunk';
import {
  sliceKey as notesKey,
  reducer as notesReducer,
} from './ducks/fetchOerNotesThunk';
import {
  sliceKey as relatedOersKey,
  reducer as relatedOersReducer,
} from './ducks/fetchRelatedOersThunk';
import { fetchOERsByIDsThunk } from 'app/containers/Layout/ducks/allOERSlice';
import { Action, AsyncThunkAction, unwrapResult } from '@reduxjs/toolkit';
import { EnrichmentBar } from 'app/components/EnrichmentBar/EnrichmentBar';
import { AddToPlaylistButton } from 'app/components/AddToPlaylistButton/AddToPlaylistButton';
import Avatar from 'antd/lib/avatar/avatar';
import { OerIcon } from 'app/components/OerIcon/OerIcon';
import { NotesWidget } from 'app/components/NotesWidget/NotesWidget';
import { useTranslation } from 'react-i18next';
import { RelatedOersWidget } from 'app/components/RelatedOersWidget/RelatedOersWidget';

const { Title, Text } = Typography;
const { Meta } = Card;

const imageBaseURL = 'https://qa.x5learn.org/files/thumbs/';

const responsiveColWidths = {
  lg: { span: 22 },
};

export function ResourcesPage(props) {
  useInjectReducer({ key: sliceKey, reducer: reducer });
  useInjectReducer({ key: notesKey, reducer: notesReducer });
  useInjectReducer({ key: relatedOersKey, reducer: relatedOersReducer });
  const { t } = useTranslation();
  const dispatch = useDispatch();
  const videoRef = useRef<HTMLVideoElement>(null);
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
      mediatype: 'text' | 'video' | 'audio';
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

  const onPlayLocationChange = ({ posInSec, duration }) => {
    if (videoRef?.current) {
      videoRef.current.currentTime = posInSec;
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
            <Row gutter={[16, 16]} justify="center">
              <Col flex="90%">
                {data.mediatype === 'audio' && (
                  <audio controls style={{ width: '100%', height: '45vh' }}>
                    <source src={data.url} type="audio/mpeg" />
                    Your browser does not support the audio element.
                  </audio>
                )}

                {data.mediatype === 'video' && (
                  <video
                    ref={videoRef}
                    width="100%"
                    style={{ width: '100%', height: '45vh' }}
                    controls
                  >
                    <source src={data.url} type="video/mp4" />
                    Your browser does not support the video tag.
                  </video>
                )}

                {data.mediatype === 'text' && (
                  <object
                    data={data.url}
                    type="application/pdf"
                    style={{ width: '100%', height: '45vh' }}
                  >
                    Your browser does not support the PDF element.
                  </object>
                )}

                <EnrichmentBar
                  oerID={data.id}
                  oer={data}
                  onPlayLocationChange={onPlayLocationChange}
                />
              </Col>
              <Col {...responsiveColWidths}>
                <Card
                  headStyle={{ border: 'none' }}
                  title={<Title level={2}>{data.title}</Title>}
                  extra={
                    <>
                      {/* <Button
                        type="link"
                        shape="round"
                        icon={<UploadOutlined />}
                        size="large"
                      >
                        Bookmark
                      </Button>{' '} */}
                      <AddToPlaylistButton oerId={oerID} />
                    </>
                  }
                >
                  <Space
                    direction="vertical"
                    size={40}
                    style={{ width: '100%' }}
                  >
                    <Meta
                      avatar={
                        <Avatar
                          size={{
                            xs: 24,
                            sm: 32,
                            md: 40,
                            lg: 64,
                            xl: 80,
                          }}
                          icon={<OerIcon mediatype={data?.mediatype} />}
                        />
                      }
                      title={
                        <>
                          <Text strong>
                            {t('playlist.lbl_playlist_provider')}:{' '}
                          </Text>
                          <Text>{data.provider}</Text> {` / `}
                          <Text strong>
                            {t('playlist.lbl_playlist_mediatype')}:{' '}
                          </Text>
                          <Text>{data.mediatype}</Text> {` / `}
                          <Text strong>
                            {t('playlist.lbl_playlist_date')}:{' '}
                          </Text>
                          <Text>
                            {new Date(data.date).toLocaleDateString('en-US', {
                              year: 'numeric',
                              month: 'long',
                              day: 'numeric',
                            })}
                          </Text>
                        </>
                      }
                      description={
                        <Col>
                          {data.description ||
                            t('inspector.lbl_no_description')}
                        </Col>
                      }
                    />
                    <NotesWidget oerID={data?.id} />

                    <RelatedOersWidget oerID={data?.id} />
                  </Space>
                </Card>
              </Col>
            </Row>
          </>
        )}
      </AppLayout>
    </>
  );
}
