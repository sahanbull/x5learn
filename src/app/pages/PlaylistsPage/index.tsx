import React, { useEffect, useState } from 'react';
import { Helmet } from 'react-helmet-async';
import {
  Alert,
  Button,
  Card,
  Col,
  message,
  Row,
  Spin,
  Typography,
} from 'antd';
import {
  ShareAltOutlined,
  UnorderedListOutlined,
  WarningOutlined,
} from '@ant-design/icons';
import { useInjectReducer } from 'redux-injectors';
import { useDispatch, useSelector } from 'react-redux';
import { unwrapResult } from '@reduxjs/toolkit';
import { useTranslation } from 'react-i18next';

import { AppLayout } from 'app/containers/Layout/AppLayout';
import { fetchOERsByIDsThunk } from 'app/containers/Layout/ducks/allOERSlice';
import { OerCardList } from '../HomePage/components/FeaturedOER/OerCardList';
import {
  fetchPlaylistDetailsThunk,
  sliceKey,
  reducer,
} from './ducks/fetchPlaylistDetailsThunk';

import './PlaylistsPage.less';

const { Paragraph, Text, Title } = Typography;

export function PlaylistsPage(props) {
  useInjectReducer({ key: sliceKey, reducer });

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

  const playlistID = props.match?.params?.id;
  const oerCount = Array.isArray(data?.oerIds) ? data.oerIds.length : 0;

  useEffect(() => {
    dispatch(fetchPlaylistDetailsThunk(playlistID));
  }, [dispatch, playlistID]);

  useEffect(() => {
    if (!data) return;

    const loadOERIds = async () => {
      const ids = Array.isArray(data.oerIds) ? data.oerIds : [];

      if (ids.length === 0) {
        setOERData({ data: [], loading: false, error: null });
        return;
      }

      setOERData({ data: null, loading: true, error: null });

      try {
        const oerResult = (await dispatch(fetchOERsByIDsThunk(ids))) as any;
        const resolvedData = await unwrapResult(oerResult);
        setOERData({ data: resolvedData, loading: false, error: null });
      } catch (loadError) {
        setOERData({ data: null, loading: false, error: loadError });
      }
    };

    loadOERIds();
  }, [data, dispatch]);

  const handleShare = async () => {
    try {
      await navigator.clipboard.writeText(window.location.href);
      message.success('Link copied to clipboard!');
    } catch (shareError) {
      message.error('Unable to copy the playlist link');
    }
  };

  return (
    <>
      <Helmet>
        <title>{data?.title}</title>
        <meta name="description" content={data?.description} />
      </Helmet>

      <AppLayout>
        <main className="x5-published-playlist-page">
          {loading && (
            <div className="x5-playlist-loading" role="status">
              <Spin spinning delay={200} size="large" />
              <Text>Loading playlist...</Text>
            </div>
          )}

          {error && (
            <Alert
              className="x5-playlist-error"
              type="error"
              showIcon
              icon={<WarningOutlined />}
              message={t('alerts.lbl_load_playlist_error')}
              description={error?.msg?.result}
            />
          )}

          {data && (
            <>
              <Card className="x5-playlist-summary-card" bordered={false}>
                <div className="x5-playlist-summary-layout">
                  <div className="x5-playlist-summary-copy">
                    <Text className="x5-playlist-eyebrow">
                      Published playlist
                    </Text>
                    <Title level={1}>{data.title}</Title>
                    <Paragraph>
                      {data.description || 'No playlist description provided.'}
                    </Paragraph>

                    <div className="x5-playlist-metadata">
                      <span className="x5-playlist-meta-item">
                        <UnorderedListOutlined />
                        <strong>{oerCount}</strong>
                        {t('playlist.lbl_playlist_oer_material_count')}
                      </span>

                      {data.last_updated_at && (
                        <span className="x5-playlist-meta-item">
                          <strong>
                            {t('playlist.lbl_playlist_updated_date')}:
                          </strong>
                          {new Date(data.last_updated_at).toLocaleDateString(
                            'en-US',
                            {
                              year: 'numeric',
                              month: 'long',
                              day: 'numeric',
                            },
                          )}
                        </span>
                      )}
                    </div>
                  </div>

                  <Button
                    className="x5-playlist-share-button"
                    size="large"
                    icon={<ShareAltOutlined />}
                    onClick={handleShare}
                  >
                    {t('Share')}
                  </Button>
                </div>
              </Card>

              <section className="x5-playlist-resources-section">
                <div className="x5-playlist-section-heading">
                  <div>
                    <Title level={2}>Playlist resources</Title>
                    <Text>
                      Select a resource to open it and continue through the
                      playlist.
                    </Text>
                  </div>
                  <span className="x5-playlist-resource-count">{oerCount}</span>
                </div>

                <OerCardList {...oerData} playlistID={playlistID} />
              </section>
            </>
          )}
        </main>
      </AppLayout>
    </>
  );
}
