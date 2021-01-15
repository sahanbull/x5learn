import React, { useEffect } from 'react';
import { Spin, Typography } from 'antd';
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


const { Text, Title } = Typography;

export function MyPlaylistWidget(props: {}) {
  useInjectReducer({
    key: sliceKey,
    reducer: reducer,
  });

  const { data, loading, error } = useSelector((state: RootState) => {
    return state.allMyPlaylists || { data, loading: false, error };
  });
  const dispatch = useDispatch();
  useEffect(() => {
    if (!data) {
      dispatch(fetchAllMyPlaylistsThunk({}));
    }
  });

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
      {/* {data && (
        <Pagination
          defaultCurrent={+page}
          total={total_pages}
          showSizeChanger={false}
          onChange={page => {
            query.set('page', `${page}`);
            history.push(`${ROUTES.SEARCH}?${query.toString()}`);
          }}
        />
      )} */}
    </>
  );
}
