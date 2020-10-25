import React from 'react';
import { Layout, Menu, Breadcrumb } from 'antd';
import {
  UserOutlined,
  LaptopOutlined,
  NotificationOutlined,
} from '@ant-design/icons';
import { AppHeader } from '../Header/AppHeader';

import { AppSideBar } from '../SideBar/AppSideBar';
import { AppBreadcrumb } from '../Breadcrumb/AppBreadcrumb';
const { SubMenu } = Menu;
const { Header, Content, Sider } = Layout;

export function AppLayout(props) {
  return (
    <Layout>
      <AppHeader></AppHeader>
      <Layout>
        <AppSideBar />
        <Layout style={{ padding: '0 24px 24px' }}>
          <AppBreadcrumb />
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
    </Layout>
  );
}
