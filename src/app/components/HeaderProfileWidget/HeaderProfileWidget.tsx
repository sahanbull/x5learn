import React from 'react';
import { useDispatch, useSelector } from 'react-redux';
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
import { sliceKey as loggedInUserDetailsSliceKey } from 'app/containers/Layout/ducks/loggedInUserDetailsSlice';

const { Title, Link, Text } = Typography;
const { SubMenu } = Menu;
const { Header, Content, Sider } = Layout;
const { Search } = Input;

export function HeaderProfileWidget(props) {
  const loggedInUser = useSelector(state => state[loggedInUserDetailsSliceKey].loggedInUser);
  let fullName = 'Please add your name';
  if (loggedInUser && loggedInUser.userProfile && (loggedInUser.userProfile.firstName || loggedInUser.userProfile.lastName)) {
    fullName = `${loggedInUser.userProfile.firstName || ''} ${loggedInUser.userProfile.lastName || ''}`;
  }
  return (
    <>
      <Popover
        placement="bottomLeft"
        title={
          <>
            <Text strong>{fullName}</Text>
            <br />
            <Text>{loggedInUser && loggedInUser.userProfile ? loggedInUser.userProfile.email : ''}</Text>
          </>
        }
        content={
          <>
            <Link href="/profile">My Profile</Link>
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
