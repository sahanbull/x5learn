import React from 'react';
import { Layout, Menu, Breadcrumb, Input, Space, Button } from 'antd';
import {
  UserOutlined,
  LaptopOutlined,
  AppstoreOutlined,
} from '@ant-design/icons';

import styled from 'styled-components';
import './HeaderSearchBar.less';

const { SubMenu } = Menu;
const { Header, Content, Sider } = Layout;
const { Search } = Input;

export function HeaderSearchBar(props) {
  return (
    <Space align="center" size="middle">
      <Search
        placeholder="Search"
        allowClear
        // enterButton="Search"
        size="large"
      />
      <Button
        size="large"
        icon={<AppstoreOutlined style={{ fontSize: '16px' }} />}
      />
    </Space>
  );
}
