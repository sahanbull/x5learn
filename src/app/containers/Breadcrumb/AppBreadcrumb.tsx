import React from 'react';
import { Layout, Menu, Breadcrumb } from 'antd';
import {
  UserOutlined,
  LaptopOutlined,
  NotificationOutlined,
} from '@ant-design/icons';

const { SubMenu } = Menu;
const { Header, Content, Sider } = Layout;

export function AppBreadcrumb(props) {
  return (
    <Breadcrumb style={{ margin: '16px 0' }}>
      <Breadcrumb.Item>Home</Breadcrumb.Item>
      <Breadcrumb.Item>List</Breadcrumb.Item>
      <Breadcrumb.Item>App</Breadcrumb.Item>
    </Breadcrumb>
  );
}
