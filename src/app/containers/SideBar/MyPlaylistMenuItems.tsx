import React, { useEffect, useState } from 'react';
import {
  Layout,
  Menu,
  Breadcrumb,
  Space,
  Row,
  Col,
  Typography,
  Button,
  Skeleton,
  Empty,
} from 'antd';
import Icon, {
  MailOutlined,
  AppstoreOutlined,
  SettingOutlined,
  WarningOutlined,
} from '@ant-design/icons';
import './AppSideBar.less';
import { ReactComponent as PlayListSVG } from 'app/containers/ContentPage/assets/playlist.svg';
import { X5MenuTitle } from './X5MenuTitle';
import { useDispatch, useSelector } from 'react-redux';
import {
  fetchMyPlaylistsMenuThunk,
  sliceKey,
} from 'app/containers/Layout/ducks/myPlaylistsMenuSlice';
import { Link, NavLink } from 'react-router-dom';
import { ROUTES } from 'routes/routes';
import { useTranslation } from 'react-i18next';
const { SubMenu } = Menu;
const { Header, Content, Sider } = Layout;
const { Text } = Typography;

function Loading({ loading, ...props }) {
  if (loading) {
    const size = 'default';
    const active = true;
    const width = 150;
    const disabled = true;
    return (
      <>
        <Menu.Item key="load2" disabled {...props}>
          <Skeleton.Input style={{ width }} active={active} size={size} />
        </Menu.Item>
        <Menu.Item key="load3" disabled {...props}>
          <Skeleton.Input style={{ width }} active={active} size={size} />
        </Menu.Item>
        <Menu.Item key="load4" disabled {...props}>
          <Skeleton.Input style={{ width }} active={active} size={size} />
        </Menu.Item>
      </>
    );
  }
  return null;
}
function Error({ error }) {
  if (error) {
    return (
      <Empty description="An error has occurred" image={<WarningOutlined />} />
    );
  }
  return null;
}

function NoData({ data }) {
  if (!data || data?.length === 0) {
    return (
      <>
        <Empty description="No temp playlists found" />
        <Space align="center" direction="vertical" style={{ width: '100%' }}>
          <Link to={`${ROUTES.MY_PLAYLISTS_CREATE}`}>
            <Button type="text">Create new playlist</Button>
          </Link>
        </Space>
      </>
    );
  }
  return null;
}

export function MyPlaylistMenuItems(props) {
  const loading = useSelector(state => {
    return state[sliceKey].loading;
  });
  const error = useSelector(state => {
    return state[sliceKey].error;
  });
  const menuPlaylist = useSelector(state => {
    return state[sliceKey].data;
  });

  const dispatch = useDispatch();
  const { t } = useTranslation();

  useEffect(() => {
    if (!menuPlaylist) {
      dispatch(fetchMyPlaylistsMenuThunk());
    }
  }, [menuPlaylist, dispatch]);

  return (
    <SubMenu
      {...props}
      title={
        <X5MenuTitle icon={<PlayListSVG />}>
          {t('playlist.lbl_playlist_my_playlists')}
        </X5MenuTitle>
      }
    >
      {loading && <Loading loading={loading} />}
      {error && <Error error={error} />}
      {menuPlaylist && <NoData data={menuPlaylist} />}

      {menuPlaylist && menuPlaylist.length && (
        <>
          {menuPlaylist.map(playlistItem => {
            const { id, title } = playlistItem;
            return (
              <Menu.Item key={title}>
                <Link to={`${ROUTES.PLAYLISTS}/temp/${title}`}>{title}</Link>
              </Menu.Item>
            );
          })}
        </>
      )}
      <Menu.Item key="show-all">
        <NavLink to={`${ROUTES.MY_PLAYLISTS}`}>
          {t('playlist.lbl_playlist_see_all')}
        </NavLink>
      </Menu.Item>
    </SubMenu>
  );
}
