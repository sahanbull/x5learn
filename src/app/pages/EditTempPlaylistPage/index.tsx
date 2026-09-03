import React, { useEffect } from 'react';
import { Helmet } from 'react-helmet-async';
import { Alert, Card, Col, Row, Spin, Typography } from 'antd';
import { WarningOutlined } from '@ant-design/icons';
import { useInjectReducer } from 'redux-injectors';
import { useDispatch, useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';

import { PlaylistDeleteButton } from 'app/components/PlaylistDeleteButton/PlaylistDeleteButton';
import { PlaylistEditFormWidget } from 'app/components/PlaylistForm/PlaylistEditFormWidget';
import { AppLayout } from 'app/containers/Layout/AppLayout';
import { RootState } from 'types';

import {
  fetchTempPlaylistDetailsThunk,
  sliceKey,
  reducer,
} from './ducks/fetchTempPlaylistDetailsThunk';

import './EditTempPlaylistPage.less';

const { Text, Title } = Typography;

export function EditTempPlaylistPage(props) {
  useInjectReducer({ key: sliceKey, reducer });

  const { t } = useTranslation();
  const dispatch = useDispatch();
  const { data, loading, error } = useSelector((state: RootState) => {
    return state.tempPlaylistDetail;
  });

  const playlistID = props.match?.params?.id;

  useEffect(() => {
    dispatch(fetchTempPlaylistDetailsThunk(playlistID));
  }, [dispatch, playlistID]);

  return (
    <>
      <Helmet>
        <title>
          {t('playlist.lbl_playlist_edit') + ` - ${data?.playlist?.title}`}
        </title>
      </Helmet>

      <AppLayout>
        <main className="x5-edit-temp-playlist-page">
          {loading && (
            <div className="x5-edit-temp-playlist-loading" role="status">
              <Spin spinning delay={200} size="large" />
              <Text>Loading playlist...</Text>
            </div>
          )}

          {error && (
            <Alert
              className="x5-edit-temp-playlist-alert"
              type="error"
              showIcon
              icon={<WarningOutlined />}
              message={t('alerts.lbl_load_playlist_oers_error')}
            />
          )}

          {data && (
            <Row gutter={[16, 16]}>
              <Col span={24}>
                <Card
                  className="x5-edit-temp-playlist-card"
                  extra={
                    <PlaylistDeleteButton
                      playlistName={data?.playlist?.title}
                    />
                  }
                  title={
                    <div className="x5-edit-temp-playlist-heading">
                      <Text>Playlist workspace</Text>
                      <Title level={2}>
                        {t('playlist.lbl_playlist_edit')} -{' '}
                        {data?.playlist?.title}
                      </Title>
                    </div>
                  }
                >
                  <PlaylistEditFormWidget formData={data} />
                </Card>
              </Col>
            </Row>
          )}
        </main>
      </AppLayout>
    </>
  );
}
