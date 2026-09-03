import React, { useEffect } from 'react';
import {
  Alert,
  Pagination,
  Row,
  Spin,
  Typography,
} from 'antd';
import { WarningOutlined } from '@ant-design/icons';
import { useDispatch, useSelector } from 'react-redux';
import { useHistory, useLocation } from 'react-router';
import { useInjectReducer } from 'redux-injectors';

import { ROUTES } from 'routes/routes';
import { RootState } from 'types';

import {
  sliceKey,
  reducer,
  fetchAllMyPlaylistsThunk,
} from '../../ducks/fetchAllMyPlaylistsThunk';
import { PlaylistCardList } from './PlaylistCardList';
import { useTranslation } from 'react-i18next';

import './MyPlaylistWidget.less';

const { Paragraph, Text, Title } = Typography;
const PAGE_SIZE = 10;

function useQuery() {
  return new URLSearchParams(useLocation().search);
}

export function MyPlaylistWidget(props: {}) {
  useInjectReducer({
    key: sliceKey,
    reducer,
  });

  const query = useQuery();
  const history = useHistory();
  const dispatch = useDispatch();
  const { t } = useTranslation();

  const requestedPage = Number(query.get('page'));
  const currentPage = requestedPage > 0 ? requestedPage : 1;

  const playlistState = useSelector(
    (state: RootState) => state.allMyPlaylists,
  );

  const data = playlistState?.data;
  const tempPlaylists = playlistState?.temp_playlists;
  const loading = playlistState?.loading || false;
  const error = playlistState?.error;
  const metadata = playlistState?.metadata;

  const totalItems = metadata?.total || 0;
  const totalPages = Math.ceil(totalItems / PAGE_SIZE);

  const handleCardClick = async (item: any) => {
    try {
      const payload = {
        action_type_id: 1,
        params: JSON.stringify({ oer_id: item.id }),
        is_bundled: false,
      };

      await fetch(`${process.env.REACT_APP_BASE_URL}/action/`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
        },
        body: JSON.stringify(payload),
        credentials: 'include',
      });

      console.log(`Action logged for item ID: ${item.id}`);
    } catch (err) {
      console.error('Failed to log action', err);
    }
  };

  useEffect(() => {
    const offset = PAGE_SIZE * (currentPage - 1);
    dispatch(fetchAllMyPlaylistsThunk({ limit: PAGE_SIZE, offset }));
  }, [currentPage, dispatch]);

  void handleCardClick;

  return (
    <main className="x5-playlist-widget">
      <header className="x5-playlist-header">
        <div className="x5-playlist-header-content">
          <Text className="x5-playlist-eyebrow">Your Library</Text>

          <Title level={1}>My Playlists</Title>

          <Paragraph>
            Manage your published playlists and continue working on content
            that is still under development.
          </Paragraph>
        </div>
      </header>

      {loading && (
        <div className="x5-playlist-feedback" role="status">
          <Spin spinning delay={500} />
          <Text>{t('alerts.lbl_load_playlists_loading')}</Text>
        </div>
      )}

      {error && (
        <Alert
          className="x5-playlist-alert"
          type="error"
          showIcon
          icon={<WarningOutlined />}
          message={t('alerts.lbl_load_playlists_error')}
        />
      )}

      <section className="x5-playlist-section">
        <div className="x5-playlist-section-heading">
          <div>
            <Title level={2}>Published Playlists</Title>
            <Text>
              Content that is currently published and available in your
              library.
            </Text>
          </div>
        </div>

        <PlaylistCardList
          data={data}
          loading={loading}
          error={error}
        />
      </section>

      <section className="x5-playlist-section">
        <div className="x5-playlist-section-heading">
          <div>
            <Title level={2}>Under Development</Title>
            <Text>
              Continue editing playlists that have not been published yet.
            </Text>
          </div>
        </div>

        <PlaylistCardList
          data={tempPlaylists}
          loading={loading}
          error={error}
        />
      </section>

      {totalPages > 1 && (
        <Row className="x5-playlist-pagination" justify="center">
          <Pagination
            current={currentPage}
            pageSize={PAGE_SIZE}
            disabled={loading}
            total={totalItems}
            showSizeChanger={false}
            onChange={nextPage => {
              query.set('page', `${nextPage}`);
              history.push(
                `${ROUTES.MY_PLAYLISTS}?${query.toString()}`,
              );
            }}
          />
        </Row>
      )}
    </main>
  );
}