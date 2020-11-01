import React from 'react';
import { Layout, Menu, Breadcrumb, Space } from 'antd';
import {
  UserOutlined,
  LaptopOutlined,
  NotificationOutlined,
} from '@ant-design/icons';
import { X5Logo } from 'app/components/Logo/X5Logo';
import styled from 'styled-components';
import { HeaderSearchBar } from './HeaderSearchBar';

const { SubMenu } = Menu;
const { Header, Content, Sider } = Layout;

const StyledHeader = styled(Header)`
  box-shadow: 0 2px 8px 0 rgba(0, 19, 77, 0.16);
  z-index: 50;
  display: flex;
  align-items: center;
`;

export function AppHeader(props) {
  return (
    <StyledHeader className="header">
      <X5Logo />
      <HeaderSearchBar />
      <Menu theme="dark" mode="horizontal" defaultSelectedKeys={['1']}>
        <Menu.Item key="1">nav 1</Menu.Item>
        <Menu.Item key="2">nav 2</Menu.Item>
        <Menu.Item key="3">nav 3</Menu.Item>
      </Menu>
    </StyledHeader>
  );
}
