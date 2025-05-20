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
import ReactPlayer from 'react-player';
import { useLocation } from 'react-router-dom';
import axios from 'axios';
import { ROUTES } from 'routes/routes';


const { Title, Text } = Typography;
const { Meta } = Card;

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


  const query = useQuery();
  function useQuery() {
    return new URLSearchParams(useLocation().search);
  }
  const [playlistItems, setPlaylistItems] = useState([]);
  const mode = query.get('mode');
  const tempPlaylistName = query.get('title');
  const currentOerId = props.match?.params?.id;
  console.log('tempPlaylistName', tempPlaylistName);
  console.log('mode', mode);

  useEffect(() => {
    const fetchPlaylist = async () => {
      try {
        const { data } = await axios.get(`/api/v1/playlist/${tempPlaylistName}`);
        setPlaylistItems(data.playlist_items || []);
        console.log('Fetched playlist data:', data);
      } catch (error) {
        console.error('Error fetching playlist:', error);
      }
    };

    if (mode === 'temp_playlist' && tempPlaylistName) {
      fetchPlaylist();
    }
  }, [mode, tempPlaylistName]);

  const handleNext = () => {
    console.log('handleNext called');
    const currentIndex = playlistItems.findIndex(
      item => String(item.oer_id) === String(currentOerId)
    );
  
    const nextItem = playlistItems[currentIndex + 1];
    console.log('nextItem:', nextItem);
  
    if (nextItem) {
      let pathToNavigateTo = `${ROUTES.RESOURCES}/${nextItem.oer_id}`;
  
      // Append query params if in temp playlist mode
      if (mode === 'temp_playlist' && tempPlaylistName) {
        pathToNavigateTo += `?mode=temp_playlist&title=${encodeURIComponent(tempPlaylistName)}`;
      }
  
      props.history.push(pathToNavigateTo);
    }
  };

  const handlePrevious = () => {
    console.log('handlePrevious called');
    const currentIndex = playlistItems.findIndex(
      item => String(item.oer_id) === String(currentOerId)
    );
  
    const previousItem = playlistItems[currentIndex - 1];
    console.log('previousItem:', previousItem);
  
    if (previousItem) {
      let pathToNavigateTo = `${ROUTES.RESOURCES}/${previousItem.oer_id}`;
  
      if (mode === 'temp_playlist' && tempPlaylistName) {
        pathToNavigateTo += `?mode=temp_playlist&title=${encodeURIComponent(tempPlaylistName)}`;
      }
  
      props.history.push(pathToNavigateTo);
    }
  };
  

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
      translations: any;
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
  useEffect(() => {
    if (data) {
      console.log('OER Data Loaded:', {
        date: data.date,
        description: data.description,
        duration: data.duration,
        durationInSeconds: data.durationInSeconds,
        id: data.id,
        images: data.images,
        material_id: data.material_id,
        mediatype: data.mediatype,
        provider: data.provider,
        title: data.title,
        url: data.url,
        translations: data.translations,
      });
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
                  <>
                    {ReactPlayer.canPlay(data.url) ? (
                      <ReactPlayer
                        url={data.url}
                        controls
                        width="100%"
                        height="45vh"
                        config={{
                          file: {
                            attributes: {
                              ref: videoRef,
                            },
                            tracks: data.translations
                              ? Object.keys(data.translations).map(key => ({
                                  kind: 'subtitles',
                                  src: `data:,${data.translations[key]}`,
                                  srcLang: key,
                                  label: key,
                                  default: false,
                                }))
                              : [],
                          },
                        }}
                      />
                    ) : (
                      <video
                        ref={videoRef}
                        width="100%"
                        style={{ width: '100%', height: '45vh' }}
                        controls
                      >
                        <source src={data.url} type="video/mp4" />
                        {data.translations &&
                          Object.keys(data.translations).map((key, index) => (
                            <track
                              key={index}
                              label={key}
                              kind="subtitles"
                              srcLang={key}
                              src={`data:,${data.translations[key]}`}
                            />
                          ))}
                        Your browser does not support the video tag.
                      </video>
                    )}
                  </>
                )}

                <Space>
                  <Button
                    type="default"
                    onClick={handlePrevious}
                    disabled={
                      playlistItems.findIndex(item => String(item.oer_id) === String(currentOerId)) === 0
                    }
                  >
                    Previous
                  </Button>
                  <Button
                    type="primary"
                    onClick={handleNext}
                    disabled={
                      playlistItems.findIndex(item => String(item.oer_id) === String(currentOerId)) ===
                      playlistItems.length - 1
                    }
                  >
                    Next
                  </Button>
                </Space>

                {data.mediatype === 'text' && (
                  <object
                    data={data.url}
                    type="application/pdf"
                    style={{ width: '100%', height: '80vh' }}
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
                  title={
                    <>
                      <Title level={2}>{data.title}</Title>
                      {mode === 'temp_playlist' && tempPlaylistName && (
                        <Button
                          type="link"
                          onClick={() =>
                            props.history.push(`${ROUTES.PLAYLISTS}/temp/${encodeURIComponent(tempPlaylistName)}`)
                          }
                          style={{ padding: 0, marginTop: 8 }}
                        >
                          Go Back To Playlist
                        </Button>
                      )}
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
