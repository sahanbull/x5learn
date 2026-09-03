import React, { useEffect } from 'react';
import { Button, Empty, Menu, Skeleton, Space } from 'antd';
import { WarningOutlined } from '@ant-design/icons';
import { Link, NavLink } from 'react-router-dom';
import { useDispatch, useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';

import { ReactComponent as PlayListSVG } from 'app/containers/ContentPage/assets/playlist.svg';
import {
  fetchMyPlaylistsMenuThunk,
  sliceKey,
} from 'app/containers/Layout/ducks/myPlaylistsMenuSlice';
import { ROUTES } from 'routes/routes';

import { X5MenuTitle } from './X5MenuTitle';

const { SubMenu } = Menu;

function Loading() {
  return (
    <>
      {[1, 2, 3].map(item => (
        <Menu.Item key={`playlist-loading-${item}`} disabled>
          <Skeleton.Input
            className="x5-playlist-skeleton"
            active
            size="small"
          />
        </Menu.Item>
      ))}
    </>
  );
}

function Error() {
  const { t } = useTranslation();

  return (
    <div className="x5-playlist-state x5-playlist-state--error">
      <Empty
        description={t('alerts.lbl_load_playlists_loading')}
        image={<WarningOutlined />}
      />
    </div>
  );
}

function NoData() {
  const { t } = useTranslation();

  return (
    <div className="x5-playlist-state">
      <Empty description={t('alerts.lbl_playlist_no_temp_playlists')} />
      <Space align="center" direction="vertical" className="x5-playlist-create">
        <Link to={ROUTES.MY_PLAYLISTS_CREATE}>
          <Button type="link">{t('playlist.lbl_create_playlist')}</Button>
        </Link>
      </Space>
    </div>
  );
}

export function MyPlaylistMenuItems({ menuKey = 'sub1', ...props }) {
  const loading = useSelector(state => state[sliceKey].loading);
  const error = useSelector(state => state[sliceKey].error);
  const menuPlaylist = useSelector(state => state[sliceKey].data);

  const dispatch = useDispatch();
  const { t } = useTranslation();

  useEffect(() => {
    if (!menuPlaylist) {
      dispatch(fetchMyPlaylistsMenuThunk());
    }
  }, [menuPlaylist, dispatch]);

  const hasPlaylists = Array.isArray(menuPlaylist) && menuPlaylist.length > 0;
  const hasNoPlaylists = Array.isArray(menuPlaylist) && menuPlaylist.length === 0;

  return (
    <SubMenu
      key={menuKey}
      {...props}
      title={
        <X5MenuTitle icon={<PlayListSVG />}>
          My Published Playlists
        </X5MenuTitle>
      }
    >
      {loading && <Loading />}
      {!loading && error && <Error />}
      {!loading && !error && hasNoPlaylists && <NoData />}

      {!loading &&
        !error &&
        hasPlaylists &&
        menuPlaylist.map(playlistItem => {
          const { id, title } = playlistItem;

          return (
            <Menu.Item key={id || title} className="x5-playlist-item">
              <Link to={`${ROUTES.PLAYLISTS}/temp/${title}`} title={title}>
                {title}
              </Link>
            </Menu.Item>
          );
        })}

      <Menu.Item key="show-all" className="x5-show-all-item">
        <NavLink to={ROUTES.MY_PLAYLISTS}>
          {t('playlist.lbl_playlist_see_all')}
        </NavLink>
      </Menu.Item>
    </SubMenu>
  );
}
