import React from 'react';
import {
  Layout,
  Menu,
  Breadcrumb,
  Space,
  Button,
  Tag,
  Typography,
  Row,
  PageHeader,
  Col,
} from 'antd';
import {
  UserOutlined,
  LaptopOutlined,
  NotificationOutlined,
} from '@ant-design/icons';
import { X5Logo } from 'app/components/Logo/X5Logo';
import styled from 'styled-components';
import { HeaderSearchBar } from './HeaderSearchBar';
import { HeaderProfileWidget } from '../../components/HeaderProfileWidget/HeaderProfileWidget';

const { SubMenu } = Menu;
const { Header, Content, Sider } = Layout;

const StyledHeader = styled(Header)`
  box-shadow: 0 2px 8px 0 rgba(0, 19, 77, 0.16);
  z-index: 50;
  /* display: flex;
  align-items: center; */
`;

export function AppHeader(props) {
  return (
    <StyledHeader className="header">
      <Row align="middle" justify="space-between">
        <Col span={6}>
          <X5Logo />
        </Col>
        <Col span={12}>
          <HeaderSearchBar />
        </Col>
        <Col span={6} style={{ textAlign: 'right' }}>
          <Button type="link">About</Button>
          <HeaderProfileWidget />
        </Col>
      </Row>
    </StyledHeader>
  );
}
