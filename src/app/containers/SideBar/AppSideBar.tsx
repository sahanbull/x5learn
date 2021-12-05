import React, { useState } from 'react';
import { Layout, Menu, Row, Col, Button } from 'antd';
import './AppSideBar.less';
import { X5MenuTitle } from './X5MenuTitle';
import { ReactComponent as BookmarkSVG } from 'app/containers/ContentPage/assets/bookmark.svg';
import { ReactComponent as HistorySVG } from 'app/containers/ContentPage/assets/history.svg';
import { ReactComponent as NotesSVG } from 'app/containers/ContentPage/assets/notes.svg';
import { ReactComponent as ProfileSVG } from 'app/containers/ContentPage/assets/profile.svg';

import { MyPlaylistMenuItems } from './MyPlaylistMenuItems';
import { Link } from 'react-router-dom';
import { ROUTES } from 'routes/routes';

const { Sider } = Layout;

export function AppSideBar(props) {
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
    <Sider
      width={252}
      breakpoint="lg"
      collapsedWidth="0"
      className="site-layout-background"
    >
      <Row
        style={{ flexDirection: 'column', minHeight: '75vh' }}
        justify="space-between"
        align="middle"
      >
        <Menu
          className="x5-main-menu"
          mode="inline"
          inlineIndent={16}
          openKeys={openKeys}
          onOpenChange={onOpenChange}
          style={{ borderRight: 0 }}
        >
          <MyPlaylistMenuItems key="sub1" />
          <Menu.Divider />
          {/* <Menu.Item key="1" style={{ padding: '0 3px 0 16px' }}>
            <Link to={`${ROUTES.PROFILE_PAGE}`}>
              <X5MenuTitle icon={<BookmarkSVG />}>Bookmarks</X5MenuTitle>
            </Link>
          </Menu.Item> */}
          <Menu.Divider />
          <Menu.Item key="2" style={{ padding: '0 3px 0 16px' }}>
            <Link to={`${ROUTES.NOTES_PAGE}`}>
              <X5MenuTitle icon={<NotesSVG />}>Notes</X5MenuTitle>
            </Link>
          </Menu.Item>
          <Menu.Divider />
          <Menu.Item key="3" style={{ padding: '0 3px 0 16px' }}>
            <Link to={`${ROUTES.HISTORY_PAGE}`}>
              <X5MenuTitle icon={<HistorySVG />}>History</X5MenuTitle>
            </Link>
          </Menu.Item>
          <Menu.Divider />
          <Menu.Item key="4" style={{ padding: '0 3px 0 16px' }}>
            <Link to={`${ROUTES.PROFILE_PAGE}`}>
              <X5MenuTitle icon={<ProfileSVG />}>My Profile</X5MenuTitle>
            </Link>
          </Menu.Item>
          <Menu.Divider />
        </Menu>
        <Col flex="auto"></Col>
        <Link to={`${ROUTES.MY_PLAYLISTS_CREATE}`}>
          <Button type="primary">New Playlist +</Button>
        </Link>
        <Col flex="20px"></Col>
      </Row>
    </Sider>
  );
}
