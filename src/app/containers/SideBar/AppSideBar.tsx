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
} from 'antd';
import Icon, {
  MailOutlined,
  AppstoreOutlined,
  SettingOutlined,
} from '@ant-design/icons';
import './AppSideBar.less';
import { X5MenuTitle } from './X5MenuTitle';
import { ReactComponent as BookmarkSVG } from 'app/containers/ContentPage/assets/bookmark.svg';
import { ReactComponent as HistorySVG } from 'app/containers/ContentPage/assets/history.svg';
import { ReactComponent as NotesSVG } from 'app/containers/ContentPage/assets/notes.svg';
import { ReactComponent as PlayListSVG } from 'app/containers/ContentPage/assets/playlist.svg';
import { ReactComponent as ProfileSVG } from 'app/containers/ContentPage/assets/profile.svg';

import { MyPlaylistMenuItems } from './MyPlaylistMenuItems';
import { useDispatch } from 'react-redux';
import { fetchMyPlaylistsMenuThunk } from '../Layout/ducks/myPlaylistsMenuSlice';
import { Link } from 'react-router-dom';
import { ROUTES } from 'routes/routes';

const { SubMenu } = Menu;
const { Header, Content, Sider } = Layout;
const { Text } = Typography;

export function AppSideBar(props) {
  const dispatch = useDispatch();

  useEffect(() => {
    dispatch(fetchMyPlaylistsMenuThunk());
  }, [dispatch]);

  const rootSubmenuKeys = ['sub1', 'sub2', 'sub4'];
  const [openKeys, setOpenKeys] = useState(['sub1']);

  const onOpenChange = openKeys => {
    const latestOpenKey = openKeys.find(key => openKeys.indexOf(key) === -1);
    if (rootSubmenuKeys.indexOf(latestOpenKey) === -1) {
      setOpenKeys(openKeys);
    } else {
      setOpenKeys(latestOpenKey ? [latestOpenKey] : []);
    }
  };

  return (
    <Sider width={252} className="site-layout-background">
      <Row
        style={{ flexDirection: 'column', minHeight: '75vh' }}
        justify="space-between"
        align="middle"
      >
        <Menu
          className="x5-main-menu"
          mode="inline"
          inlineIndent={32}
          openKeys={openKeys}
          onOpenChange={onOpenChange}
          style={{ borderRight: 0 }}
        >
          <MyPlaylistMenuItems key="sub1" />
          <Menu.Divider />
          <SubMenu
            key="sub2"
            title={<X5MenuTitle icon={<BookmarkSVG />}>Bookmarks</X5MenuTitle>}
          >
            <Menu.Item key="5">Option 5</Menu.Item>
            <Menu.Item key="6">Option 6</Menu.Item>
            <SubMenu
              key="sub3"
              title={<X5MenuTitle icon={<NotesSVG />}>Notes</X5MenuTitle>}
            >
              <Menu.Item key="7">Option 7</Menu.Item>
              <Menu.Item key="8">Option 8</Menu.Item>
            </SubMenu>
          </SubMenu>
          <Menu.Divider />
          <SubMenu
            key="sub4"
            title={<X5MenuTitle icon={<NotesSVG />}>Notes</X5MenuTitle>}
          >
            <Menu.Item key="9">Option 9</Menu.Item>
            <Menu.Item key="10">Option 10</Menu.Item>
            <Menu.Item key="11">Option 11</Menu.Item>
            <Menu.Item key="12">Option 12</Menu.Item>
          </SubMenu>
          <Menu.Divider />
          <SubMenu
            key="sub5"
            title={<X5MenuTitle icon={<HistorySVG />}>History</X5MenuTitle>}
          >
            <Menu.Item key="13">Option 9</Menu.Item>
            <Menu.Item key="14">Option 10</Menu.Item>
            <Menu.Item key="15">Option 11</Menu.Item>
            <Menu.Item key="16">Option 12</Menu.Item>
          </SubMenu>
          <Menu.Divider />
          <SubMenu
            key="sub6"
            title={<X5MenuTitle icon={<ProfileSVG />}>My Profile</X5MenuTitle>}
          >
            <Menu.Item key="17">Option 9</Menu.Item>
            <Menu.Item key="18">Option 10</Menu.Item>
            <Menu.Item key="19">Option 11</Menu.Item>
            <Menu.Item key="20">Option 12</Menu.Item>
          </SubMenu>
          <Menu.Divider />
        </Menu>
        <Col flex="auto"></Col>
        <Link to={`${ROUTES.PLAYLISTS}/create`}>
          <Button type="primary">New Playlist +</Button>
        </Link>
        <Col flex="20px"></Col>
      </Row>
    </Sider>
  );
}
