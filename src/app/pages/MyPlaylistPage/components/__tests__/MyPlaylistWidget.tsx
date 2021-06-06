import React, { useEffect, useState } from 'react';
import { Pagination, Row, Spin, Typography } from 'antd';
import { useDispatch, useSelector } from 'react-redux';
import { RootState } from 'types';
import { useInjectReducer } from 'redux-injectors';
import {
  sliceKey,
  reducer,
  fetchAllMyPlaylistsThunk,
} from '../../ducks/fetchAllMyPlaylistsThunk';
import { WarningOutlined } from '@ant-design/icons';
import { PlaylistCardList } from './PlaylistCardList';
import { useHistory, useLocation } from 'react-router';
import { ROUTES } from 'routes/routes';
import { useTranslation } from 'react-i18next';

const { Text, Title } = Typography;

function useQuery() {
  return new URLSearchParams(useLocation().search);
}

export function MyPlaylistWidget(props: {}) {
  useInjectReducer({
    key: sliceKey,
    reducer: reducer,
  });
  const limit = 10;
  const query = useQuery();
  const history = useHistory();
  const page = query.get('page')?.toString() || '1';
  const { t } = useTranslation();

  const { data, loading, error, metadata } = useSelector((state: RootState) => {
    return state.allMyPlaylists || { data, loading: false, error, metadata };
  });

  const totalItems = metadata?.total || 0;
  const total_pages = Math.ceil(totalItems / limit);
  const dispatch = useDispatch();

  // const loadPlaylists

  useEffect(() => {
    const offset = limit * (+page - 1);
    dispatch(fetchAllMyPlaylistsThunk({ limit, offset }));
  }, [page, dispatch]);

  return (
    <>
      {loading && (
        <>
          <Spin spinning={loading} delay={500}></Spin>
          {t('alerts.lbl_load_playlists_loading')}
        </>
      )}
      {error && (
        <>
          <WarningOutlined /> {t('alerts.lbl_load_playlists_error')}
        </>
      )}
      {data && (
        <Title level={2} type="secondary">
          {t('playlist.lbl_playlist_my_playlists')}
        </Title>
      )}
      <PlaylistCardList data={data} loading={loading} error={error} />
      
        {total_pages > 1 && (
          <Row justify="center">
          <Pagination
            defaultCurrent={+page}
            disabled={loading}
            total={totalItems}
            showSizeChanger={false}
            onChange={page => {
              query.set('page', `${page}`);
              history.push(`${ROUTES.MY_PLAYLISTS}?${query.toString()}`);
            }}
          />
          </Row>
        )}
      
    </>
  );
}
