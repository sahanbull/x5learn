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
  Popover,
  Image,
  Typography,
} from 'antd';
import {
  UserOutlined,
  LaptopOutlined,
  AppstoreOutlined,
} from '@ant-design/icons';

import styled from 'styled-components';
import Column from 'antd/lib/table/Column';

const { Title, Link, Text } = Typography;
const { SubMenu } = Menu;
const { Header, Content, Sider } = Layout;
const { Search } = Input;

export function HeaderProfileWidget(props) {
  return (
    <>
      <Popover
        placement="bottomLeft"
        title={
          <>
            <Text strong>Name Surname</Text>
            <br />
            <Text>name.surname@email.si</Text>
          </>
        }
        content={
          <>
            <Link href="#">My Profile</Link>
            <br />
            <Link href="/logout">Logout</Link>
          </>
        }
        trigger="click"
      >
        <Button
          style={{ alignItems: 'stretch' }}
          size="large"
          icon={
            <Image preview={false} width={40} src="/static/favicon.ico"></Image>
          }
        />
      </Popover>
    </>
  );
}
