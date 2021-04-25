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
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

const { SubMenu } = Menu;
const { Header, Content, Sider } = Layout;

const StyledHeader = styled(Header)`
  box-shadow: 0 2px 8px 0 rgba(0, 19, 77, 0.16);
  z-index: 50;
  padding: 0 32px;
  /* display: flex;
  align-items: center; */
`;

export function AppHeader(props) {
  const { t } = useTranslation();
  return (
    <StyledHeader className="header">
      <Row align="middle" justify="space-between">
        <Col span={6}>
          <Link to={`/`}>
            <X5Logo />
          </Link>
        </Col>
        <Col span={12}>
          <HeaderSearchBar />
        </Col>
        <Col span={6} style={{ textAlign: 'right' }}>
          <Button type="link">{t('about_us.lbl_about_us')}</Button>
          <HeaderProfileWidget />
        </Col>
      </Row>
    </StyledHeader>
  );
}
