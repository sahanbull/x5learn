import React, { useState } from 'react';
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
import { useSelector } from 'react-redux';
import { sliceKey } from 'app/containers/Layout/ducks/myPlaylistsMenuSlice';
import { Link } from 'react-router-dom';
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
    return <Empty description="No Data" />;
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

  return (
    <SubMenu
      {...props}
      title={<X5MenuTitle icon={<PlayListSVG />}>My Playlists</X5MenuTitle>}
    >
      {loading && <Loading loading={loading} />}
      {error && <Error error={error} />}
      {menuPlaylist && <NoData data={menuPlaylist} />}

      {menuPlaylist && menuPlaylist.length && (
        <>
          {menuPlaylist.map(playlistItem => {
            const { id, title } = playlistItem;
            return <Menu.Item key={id}><Link to={`/playlist/${id}`}>{title}</Link></Menu.Item>;
          })}
          <Menu.Item key="show-all"><Link to={`/playlist`}>See All</Link></Menu.Item>
        </>
      )}
    </SubMenu>
  );
}
