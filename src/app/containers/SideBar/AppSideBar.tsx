import React, { useState } from 'react';
import { Layout, Menu, Row, Button } from 'antd';
import { Link } from 'react-router-dom';

import { ReactComponent as HistorySVG } from 'app/containers/ContentPage/assets/history.svg';
import { ReactComponent as NotesSVG } from 'app/containers/ContentPage/assets/notes.svg';
import { ReactComponent as ProfileSVG } from 'app/containers/ContentPage/assets/profile.svg';
import { ROUTES } from 'routes/routes';

import './AppSideBar.less';
import { MyPlaylistMenuItems } from './MyPlaylistMenuItems';
import { X5MenuTitle } from './X5MenuTitle';

const { Sider } = Layout;

export function AppSideBar() {
  const rootSubmenuKeys = ['sub1'];
  const [openKeys, setOpenKeys] = useState(['sub1']);

  const onOpenChange = nextOpenKeys => {
    const latestOpenKey = nextOpenKeys.find(key => !openKeys.includes(key));

    if (!rootSubmenuKeys.includes(latestOpenKey)) {
      setOpenKeys(nextOpenKeys);
      return;
    }

    setOpenKeys(latestOpenKey ? [latestOpenKey] : []);
  };

  return (
    <Sider
      width={252}
      breakpoint="lg"
      collapsedWidth="0"
      className="x5-app-sidebar site-layout-background"
    >
      <Row
        className="x5-sidebar-content"
        justify="space-between"
        align="middle"
      >
        <Menu
          className="x5-main-menu"
          mode="inline"
          inlineIndent={16}
          openKeys={openKeys}
          onOpenChange={onOpenChange}
        >
          <MyPlaylistMenuItems key="sub1" menuKey="sub1" />

          <Menu.Divider />

          <Menu.Item key="notes">
            <Link to={ROUTES.NOTES_PAGE}>
              <X5MenuTitle icon={<NotesSVG />}>Notes</X5MenuTitle>
            </Link>
          </Menu.Item>

          <Menu.Item key="history">
            <Link to={ROUTES.HISTORY_PAGE}>
              <X5MenuTitle icon={<HistorySVG />}>History</X5MenuTitle>
            </Link>
          </Menu.Item>

          <Menu.Item key="profile">
            <Link to={ROUTES.PROFILE_PAGE}>
              <X5MenuTitle icon={<ProfileSVG />}>My Profile</X5MenuTitle>
            </Link>
          </Menu.Item>
        </Menu>

        <div className="x5-sidebar-footer">
          <Link to={ROUTES.MY_PLAYLISTS_CREATE}>
            <Button type="primary" block className="x5-new-playlist-button">
              <span>New Playlist</span>
              <span className="x5-new-playlist-plus" aria-hidden="true">
                +
              </span>
            </Button>
          </Link>
        </div>
      </Row>
    </Sider>
  );
}
