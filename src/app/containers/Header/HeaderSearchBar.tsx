import React from 'react';
import {
  Layout,
  Menu,
  Breadcrumb,
  Input,
  Space,
  Button,
  Row,
  Col,
  Form,
} from 'antd';
import {
  UserOutlined,
  LaptopOutlined,
  AppstoreOutlined,
} from '@ant-design/icons';

import styled from 'styled-components';
import './HeaderSearchBar.less';
import Column from 'antd/lib/table/Column';

const { SubMenu } = Menu;
const { Header, Content, Sider } = Layout;
const { Search } = Input;

export function HeaderSearchBar(props) {
  return (
    <Row align="middle" justify="space-between">
      <Col flex="auto">
        <Search
          style={{ display: 'block' }}
          placeholder="Search"
          allowClear
          // enterButton="Search"
          size="large"
        />
      </Col>
      <Col flex="40px">
        <Button
          size="large"
          icon={<AppstoreOutlined style={{ fontSize: '16px' }} />}
        />
      </Col>
    </Row>
  );
}
