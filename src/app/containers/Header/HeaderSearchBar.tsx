import React, { useCallback } from 'react';
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
import { useHistory, useLocation, useParams } from 'react-router-dom';
import { ROUTES } from 'routes/routes';
import queryString from 'query-string';

const { SubMenu } = Menu;
const { Header, Content, Sider } = Layout;
const { Search } = Input;

function useQuery() {
  return new URLSearchParams(useLocation().search);
}

export function HeaderSearchBar(props) {
  let history = useHistory();
  let query = useQuery();

  const searchHandler = useCallback(
    inputText => {
      const qs = queryString.stringify({ q: inputText });
      history.push(`${ROUTES.SEARCH}?${qs}`);
    },
    [history],
  );

  return (
    <Row align="middle" wrap={false} justify="space-between">
      <Col flex="auto">
        <Search
          onSearch={searchHandler}
          style={{ display: 'block' }}
          placeholder="Search"
          allowClear
          defaultValue={query.get('q')?.toString()}
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
