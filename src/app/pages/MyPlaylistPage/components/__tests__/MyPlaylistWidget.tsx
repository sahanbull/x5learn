import React, { useEffect, useState } from 'react';
import { Pagination, Spin, Typography } from 'antd';
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
          Loading your playlists...
        </>
      )}
      {error && (
        <>
          <WarningOutlined /> Something went wrong...{' '}
        </>
      )}
      {data && (
        <Title level={2} type="secondary">
          My Playlists
        </Title>
      )}
      <PlaylistCardList data={data} loading={loading} error={error} />
      {total_pages > 1 && (
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
      )}
    </>
  );
}
