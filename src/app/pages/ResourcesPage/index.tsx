import React, { useEffect, useRef, useState } from 'react';
import { Helmet } from 'react-helmet-async';
import {
  Row,
  Col,
  Card,
  Typography,
  Button,
  Spin,
} from 'antd';
import { AppLayout } from 'app/containers/Layout/AppLayout';
import {
  ArrowLeftOutlined,
  LeftOutlined,
  RightOutlined,
} from '@ant-design/icons';
import { useInjectReducer } from 'redux-injectors';
import { useDispatch } from 'react-redux';
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
import { unwrapResult } from '@reduxjs/toolkit';
import { EnrichmentBar } from 'app/components/EnrichmentBar/EnrichmentBar';
import { OerIcon } from 'app/components/OerIcon/OerIcon';
import { NotesWidget } from 'app/components/NotesWidget/NotesWidget';
import { useTranslation } from 'react-i18next';
import ReactPlayer from 'react-player';
import { useLocation } from 'react-router-dom';
import axios from 'axios';
import { ROUTES } from 'routes/routes';
import styled from 'styled-components/macro';

const { Title, Text } = Typography;

const responsiveColWidths = {
  lg: { span: 22 },
};

const parseStartTime = (value: string | null) => {
  if (!value) return 0;

  const normalized = decodeURIComponent(value).toLowerCase().trim();
  if (/^\d+s?$/.test(normalized)) {
    return parseInt(normalized.replace('s', ''), 10) || 0;
  }

  const match = normalized.match(
    /^(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s)?$/,
  );
  if (!match) return 0;

  const hours = parseInt(match[1] || '0', 10);
  const minutes = parseInt(match[2] || '0', 10);
  const seconds = parseInt(match[3] || '0', 10);
  return hours * 3600 + minutes * 60 + seconds;
};

const getStartTimeFromUrl = (url?: string) => {
  if (!url) return 0;

  try {
    const parsedUrl = new URL(url, 'https://localhost');
    const hashParams = new URLSearchParams(
      parsedUrl.hash.startsWith('#') ? parsedUrl.hash.slice(1) : parsedUrl.hash,
    );
    return parseStartTime(
      parsedUrl.searchParams.get('t') ||
        parsedUrl.searchParams.get('start') ||
        hashParams.get('t') ||
        hashParams.get('start'),
    );
  } catch (error) {
    const match = url.match(/[?&#](?:t|start)=([^&#]+)/i);
    return parseStartTime(match?.[1] || null);
  }
};

const getYouTubePlaybackUrl = (url?: string) => {
  if (!url) return '';

  const match = url.match(
    /(?:youtube\.com\/(?:.*[?&]v=|shorts\/|embed\/)|youtu\.be\/)([^&?/]+)/i,
  );

  return match?.[1]
    ? `https://www.youtube.com/watch?v=${match[1]}`
    : url;
};

const ResourcePageShell = styled.div`
  width: 100%;
  max-width: 1240px;
  margin: 0 auto;

  .playlist-view-header {
    margin-bottom: 20px;
    padding: 24px 26px;
    overflow: hidden;
    background: linear-gradient(135deg, #f8faff 0%, #f3f6fc 100%);
    border: 1px solid #e4eaf3;
    border-radius: 16px;
    box-shadow: 0 7px 24px rgba(35, 48, 79, 0.06);
  }

  .playlist-view-eyebrow {
    display: block;
    margin-bottom: 5px;
    color: #526ba9;
    font-size: 11px;
    font-weight: 700;
    letter-spacing: 1px;
    text-transform: uppercase;
  }

  .playlist-view-title.ant-typography {
    margin: 0;
    color: #202939;
    font-size: 29px;
    font-weight: 700;
    letter-spacing: -0.45px;
    line-height: 1.25;
  }

  .playlist-view-count {
    display: block;
    margin-top: 7px;
    color: #7a8497;
    font-size: 13px;
  }

  .playlist-navigation {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
    margin-top: 20px;
    padding-top: 18px;
    border-top: 1px solid #dfe5ee;
  }

  .playlist-navigation .ant-btn {
    display: inline-flex;
    height: 42px;
    align-items: center;
    justify-content: center;
    border-radius: 10px;
    font-weight: 600;
  }

  .playlist-back-button.ant-btn {
    min-width: 150px;
    color: #344054;
    background: #ffffff;
    border-color: #dbe2ec;
    box-shadow: 0 2px 7px rgba(35, 48, 79, 0.05);
  }

  .playlist-page-controls {
    display: flex;
    align-items: center;
    gap: 10px;
  }

  .playlist-page-controls .ant-btn {
    min-width: 118px;
  }

  .playlist-position {
    display: inline-flex;
    min-width: 72px;
    height: 34px;
    align-items: center;
    justify-content: center;
    padding: 0 10px;
    color: #667085;
    font-size: 12px;
    font-weight: 600;
    background: #ffffff;
    border: 1px solid #e1e6ee;
    border-radius: 9px;
  }

  .resource-media-panel {
    overflow: hidden;
    background: #101828;
    border: 1px solid #e0e5ed;
    border-radius: 15px;
    box-shadow: 0 8px 25px rgba(35, 48, 79, 0.09);
  }

  .resource-media-panel audio,
  .resource-media-panel video,
  .resource-media-panel iframe {
    display: block;
  }

  .resource-details-card.ant-card {
    overflow: hidden;
    border-color: #e4e9f1;
    border-radius: 15px;
    box-shadow: 0 6px 20px rgba(35, 48, 79, 0.055);
  }

  .resource-details-card .ant-card-head {
    min-height: auto;
    padding: 0 22px;
    background: #fbfcfe;
  }

  .resource-details-card .ant-card-head-title {
    padding: 19px 0 15px;
  }

  .resource-details-card .ant-card-head-title .ant-typography {
    margin: 0;
    color: #273142;
    font-size: 22px;
  }

  .resource-details-card .ant-card-body {
    padding: 22px;
  }

  .resource-summary {
    display: flex;
    flex-direction: column;
    gap: 18px;
  }

  .resource-meta-row {
    display: flex;
    align-items: center;
    flex-wrap: wrap;
    gap: 8px;
  }

  .resource-meta-icon {
    display: inline-flex;
    width: 38px;
    height: 38px;
    align-items: center;
    justify-content: center;
    margin-right: 3px;
    color: #405b9e;
    background: #eef3ff;
    border: 1px solid #dce5f8;
    border-radius: 11px;
  }

  .resource-meta-chip {
    display: inline-flex;
    min-height: 34px;
    align-items: center;
    gap: 5px;
    padding: 6px 10px;
    color: #667085;
    font-size: 12px;
    background: #f8fafc;
    border: 1px solid #e5e9f0;
    border-radius: 9px;
  }

  .resource-meta-chip strong {
    color: #344054;
    font-weight: 650;
  }

  .resource-content-section {
    padding: 20px;
    background: #ffffff;
    border: 1px solid #e5eaf1;
    border-radius: 13px;
  }

  .resource-notes-section {
    background: #f9fbff;
    border-color: #dfe7f5;
  }

  .resource-section-heading {
    margin-bottom: 14px;
    padding-bottom: 12px;
    border-bottom: 1px solid #edf0f4;
  }

  .resource-section-heading h3 {
    margin: 0 0 3px;
    color: #273142;
    font-size: 16px;
    font-weight: 700;
  }

  .resource-section-heading p {
    margin: 0;
    color: #8791a2;
    font-size: 12px;
    line-height: 1.5;
  }

  .resource-description {
    margin: 0;
    color: #566174;
    font-size: 14px;
    line-height: 1.75;
    text-align: left;
    white-space: pre-line;
    overflow-wrap: anywhere;
  }

  .resource-notes-section .ant-input,
  .resource-notes-section .ant-input-affix-wrapper {
    border-color: #dbe3ef;
    border-radius: 10px;
  }

  .resource-notes-section textarea.ant-input {
    min-height: 96px;
    padding: 11px 13px;
    line-height: 1.6;
    resize: vertical;
  }

  .resource-notes-section .ant-btn {
    border-radius: 9px;
    font-weight: 600;
  }

  .resource-notes-section .ant-list-item {
    margin-bottom: 10px;
    padding: 13px 14px;
    background: #ffffff;
    border: 1px solid #e4e9f1;
    border-radius: 10px;
  }

  .resource-notes-section .ant-comment-inner {
    padding: 0;
  }

  @media (max-width: 767px) {
    .playlist-view-header {
      padding: 20px 16px;
    }

    .playlist-view-title.ant-typography {
      font-size: 24px;
    }

    .playlist-navigation {
      flex-direction: column;
      align-items: stretch;
    }

    .playlist-back-button.ant-btn {
      width: 100%;
    }

    .playlist-page-controls {
      display: grid;
      grid-template-columns: 1fr auto 1fr;
    }

    .playlist-page-controls .ant-btn {
      min-width: 0;
    }
  }
`;

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
  const [playlistItems, setPlaylistItems] = useState<any[]>([]);
  const [playlistTitle, setPlaylistTitle] = useState('');
  const mode = query.get('mode');
  const tempPlaylistName = query.get('title');
  const publishedPlaylistId = query.get('playlist');
  const currentOerId = props.match?.params?.id;
  console.log('tempPlaylistName', tempPlaylistName);
  console.log('mode', mode);

  useEffect(() => {
    const fetchPlaylist = async () => {
      try {
        const { data } = await axios.get(`/api/v1/playlist/${tempPlaylistName}`);
        setPlaylistItems(data.playlist_items || []);
        setPlaylistTitle(data.playlist?.title || tempPlaylistName || 'Playlist');
        console.log('Fetched playlist data:', playlistItems);
      } catch (error) {
        console.error('Error fetching playlist:', error);
      }
    };


    const fetchPublishedPlaylist = async () => {
      try {
        if (!publishedPlaylistId) {
          console.warn('No playlist ID found in URL.');
          return;
        }

        const { data } = await axios.get(
          `/api/v1/playlist/${publishedPlaylistId}`,
        );
        console.log('Fetched published playlist data:', data);

        setPlaylistTitle(data.playlist?.title || data.title || 'Playlist');

        const formattedOerIds = Array.isArray(data.playlist_items)
          ? data.playlist_items
          : (Array.isArray(data.oerIds) ? data.oerIds : []).map(
              (id, index) => ({
                playlist_id: null,
                oer_id: id,
                order: index,
                data: id,
              }),
            );

        setPlaylistItems(formattedOerIds);
        console.log('Formatted OER IDs:', formattedOerIds);
      } catch (error) {
        console.error('Error fetching published playlist:', error);
      }
    };

    if (mode === 'temp_playlist' && tempPlaylistName) {
      fetchPlaylist();
    } else if (!mode && !tempPlaylistName) {
      fetchPublishedPlaylist();
    }
  }, [mode, tempPlaylistName, publishedPlaylistId]);

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
      } else if (publishedPlaylistId) {
        pathToNavigateTo += `?playlist=${encodeURIComponent(
          publishedPlaylistId,
        )}`;
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
      } else if (publishedPlaylistId) {
        pathToNavigateTo += `?playlist=${encodeURIComponent(
          publishedPlaylistId,
        )}`;
      }
  
      props.history.push(pathToNavigateTo);
    }
  };

  const handleBackToPlaylist = () => {
    if (mode === 'temp_playlist' && tempPlaylistName) {
      props.history.push(
        `${ROUTES.PLAYLISTS}/temp/${encodeURIComponent(tempPlaylistName)}`,
      );
      return;
    }

    if (publishedPlaylistId) {
      props.history.push(`${ROUTES.PLAYLISTS}/${publishedPlaylistId}`);
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
  const videoStartTime = getStartTimeFromUrl(data?.url);
  const isYouTubeVideo = Boolean(
    data?.url && /(?:youtube\.com|youtu\.be)/i.test(data.url),
  );
  const playbackUrl = isYouTubeVideo
    ? getYouTubePlaybackUrl(data?.url)
    : data?.url || '';
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

  const currentPlaylistIndex = playlistItems.findIndex(
    item => String(item.oer_id) === String(currentOerId),
  );
  const isPlaylistView = Boolean(
    (mode === 'temp_playlist' && tempPlaylistName) || publishedPlaylistId,
  );
  const resolvedPlaylistTitle =
    playlistTitle || tempPlaylistName || 'Playlist';
  const hasPrevious = currentPlaylistIndex > 0;
  const hasNext =
    currentPlaylistIndex >= 0 &&
    currentPlaylistIndex < playlistItems.length - 1;

  return (
    <>
      <Helmet>
        <title>{data?.title}</title>
        <meta name="description" content={data?.description} />
      </Helmet>
      <AppLayout>
        <ResourcePageShell>
          {loading && <Spin spinning={loading} delay={200}></Spin>}
          {data && (
            <>
              {isPlaylistView && (
                <header className="playlist-view-header">
                  <Text className="playlist-view-eyebrow">Now viewing</Text>
                  <Title level={1} className="playlist-view-title">
                    {resolvedPlaylistTitle}
                  </Title>
                  <Text className="playlist-view-count">
                    {playlistItems.length}{' '}
                    {playlistItems.length === 1 ? 'resource' : 'resources'} in
                    this playlist
                  </Text>

                  <nav
                    className="playlist-navigation"
                    aria-label="Playlist navigation"
                  >
                    <Button
                      className="playlist-back-button"
                      icon={<ArrowLeftOutlined />}
                      onClick={handleBackToPlaylist}
                    >
                      Back to Playlist
                    </Button>

                    <div className="playlist-page-controls">
                      <Button
                        icon={<LeftOutlined />}
                        onClick={handlePrevious}
                        disabled={!hasPrevious}
                      >
                        Previous
                      </Button>

                      <span className="playlist-position">
                        {currentPlaylistIndex >= 0
                          ? currentPlaylistIndex + 1
                          : 0}{' '}
                        / {playlistItems.length}
                      </span>

                      <Button
                        type="primary"
                        onClick={handleNext}
                        disabled={!hasNext}
                      >
                        Next <RightOutlined />
                      </Button>
                    </div>
                  </nav>
                </header>
              )}

            <Row gutter={[16, 16]} justify="center">
              <Col flex="90%">
                <div className="resource-media-panel">
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
                        key={`${data.id}-${videoStartTime}`}
                        url={playbackUrl}
                        controls
                        width="100%"
                        height="45vh"
                        onReady={player => {
                          if (!isYouTubeVideo && videoStartTime > 0) {
                            player.seekTo(videoStartTime, 'seconds');
                          }
                        }}
                        config={{
                          youtube: {
                            playerVars: {
                              start: videoStartTime,
                              playsinline: 1,
                            },
                          },
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
                        onLoadedMetadata={() => {
                          if (videoRef.current && videoStartTime > 0) {
                            videoRef.current.currentTime = videoStartTime;
                          }
                        }}
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

                {data.mediatype === 'text' && (
                  <object
                    data={data.url}
                    type="application/pdf"
                    style={{ width: '100%', height: '80vh' }}
                  >
                    Your browser does not support the PDF element.
                  </object>
                )}
                </div>

                <EnrichmentBar
                  oerID={data.id}
                  oer={data}
                  onPlayLocationChange={onPlayLocationChange}
                />
              </Col>
              <Col {...responsiveColWidths}>
                <Card
                  className="resource-details-card"
                  headStyle={{ border: 'none' }}
                  title={
                    <>
                      <Title level={2}>{data.title}</Title>
                     
                    </>
                  }
                >
                  <div className="resource-summary">
                    <div className="resource-meta-row">
                      <span className="resource-meta-icon">
                        <OerIcon mediatype={data?.mediatype} />
                      </span>

                      <span className="resource-meta-chip">
                        <strong>
                          {t('playlist.lbl_playlist_provider')
                            .charAt(0)
                            .toUpperCase() +
                            t('playlist.lbl_playlist_provider').slice(1)}:
                        </strong>
                        {data.provider
                          ? data.provider.charAt(0).toUpperCase() +
                            data.provider.slice(1)
                          : 'Unknown'}
                      </span>

                      <span className="resource-meta-chip">
                        <strong>
                          {t('playlist.lbl_playlist_mediatype')
                            .charAt(0)
                            .toUpperCase() +
                            t('playlist.lbl_playlist_mediatype').slice(1)}:
                        </strong>
                        {data.mediatype
                          ? data.mediatype.charAt(0).toUpperCase() +
                            data.mediatype.slice(1)
                          : 'Unknown'}
                      </span>

                      {data.date && (
                        <span className="resource-meta-chip">
                          <strong>
                            {t('playlist.lbl_playlist_date')
                              .charAt(0)
                              .toUpperCase() +
                              t('playlist.lbl_playlist_date').slice(1)}:
                          </strong>
                          {new Date(data.date).toLocaleDateString('en-US', {
                            year: 'numeric',
                            month: 'long',
                            day: 'numeric',
                          })}
                        </span>
                      )}
                    </div>

                    <section className="resource-content-section">
                      <div className="resource-section-heading">
                        <h3>Description</h3>
                        <p>Information about this resource.</p>
                      </div>
                      <p className="resource-description">
                        {data.description ||
                          t('inspector.lbl_no_description')}
                      </p>
                    </section>

                    <section className="resource-content-section resource-notes-section">
                      <div className="resource-section-heading">
                        <h3>Notes</h3>
                        <p>Add and review notes for this resource.</p>
                      </div>
                      <NotesWidget oerID={data?.id} />
                    </section>

                    {/* <RelatedOersWidget oerID={data?.id} /> */}
                  </div>
                </Card>
              </Col>
            </Row>
          </>
        )}
        </ResourcePageShell>
      </AppLayout>
    </>
  );
}
