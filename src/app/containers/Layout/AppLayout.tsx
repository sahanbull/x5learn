import React from 'react';
import { Layout, Menu, Breadcrumb, Row, Col, Divider } from 'antd';
import {
  UserOutlined,
  LaptopOutlined,
  NotificationOutlined,
} from '@ant-design/icons';

import {
  fetchMyPlaylistsMenuThunk,
  sliceKey as playlistMenuSliceKey,
  reducer as playlistMenuReducer,
} from './ducks/myPlaylistsMenuSlice';

import { AppHeader } from '../Header/AppHeader';
import { AppFooter } from '../Footer/AppFooter';

import { AppSideBar } from '../SideBar/AppSideBar';
import { AppBreadcrumb } from '../Breadcrumb/AppBreadcrumb';
import { useInjectReducer } from 'redux-injectors';
const { SubMenu } = Menu;
const { Header, Content, Sider, Footer } = Layout;

export function AppLayout(props) {
  useInjectReducer({ key: playlistMenuSliceKey, reducer: playlistMenuReducer });

  return (
    <Layout>
      <AppHeader></AppHeader>
      <Layout>
        <AppSideBar />
        <Layout style={{ padding: '0 24px 24px' }}>
          {/* <AppBreadcrumb /> */}
          <Content
            className="site-layout-background"
            style={{
              padding: 24,
              margin: 0,
              minHeight: 280,
            }}
          >
            {props.children}
          </Content>
        </Layout>
      </Layout>
      <AppFooter></AppFooter>
    </Layout>
  );
}
