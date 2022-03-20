import React, { useCallback, useState } from 'react';
import {
  Layout,
  Menu,
  Input,
  Button,
  Row,
  Col,
  Select
} from 'antd';
import {
  AppstoreOutlined,
  CaretDownOutlined,
  CaretUpOutlined
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
const { Option } = Select;

const defaultTypes = ['all', 'text', 'video'];
const defaultLanguages = ['all', 'en', 'fr'];

function useQuery() {
  return new URLSearchParams(useLocation().search);
}

export function HeaderSearchBar(props) {
  let history = useHistory();
  let query = useQuery();

  const [showAdvansedOptions, setShowAdvansedOptions] = useState(false);
  const [type, setType] = useState(defaultTypes[0]);
  const [language, setLanguage] = useState(defaultLanguages[0]);

  const searchHandler = useCallback(
    inputText => {
      setShowAdvansedOptions(false);
      const qs = queryString.stringify({ q: inputText, type, language });
      history.push(`${ROUTES.SEARCH}?${qs}`);
    },
    [history, type, language],
  );

  return (
    <>
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
            icon={
              showAdvansedOptions ? (
                <CaretUpOutlined style={{ fontSize: '16px' }} />
              ) : (
                <CaretDownOutlined style={{ fontSize: '16px' }} />
              )
            }
            onClick={() => setShowAdvansedOptions(!showAdvansedOptions)}
          />
        </Col>
        <Col flex="40px">
          <Button
            size="large"
            icon={<AppstoreOutlined style={{ fontSize: '16px' }} />}
          />
        </Col>
      </Row>
      {showAdvansedOptions && (
        <Row
          style={{ position: 'absolute', background: 'white', width: '46vw' }}
        >
          <Col flex="auto">
            <p style={{ position: 'absolute', left: '10px' }}>Type:</p>
            <Select
              defaultValue={query.get('type')?.toString().toLocaleLowerCase()}
              style={{ width: '20vw' }}
              loading={false}
              onChange={value => {
                setType(value);
              }}
            >
              {defaultTypes.map((item: string) => {
                return (
                  <Option key={item} value={item}>
                    {item.toUpperCase()}
                  </Option>
                );
              })}
            </Select>
          </Col>
          <Col flex="auto">
            <p style={{ position: 'absolute', left: '10px' }}>Language:</p>
            <Select
              defaultValue={query
                .get('language')
                ?.toString()
                .toLocaleLowerCase()}
              style={{ width: '20vw' }}
              loading={false}
              onChange={value => {
                setLanguage(value);
              }}
            >
              {defaultLanguages.map((item: string) => {
                return (
                  <Option key={item} value={item}>
                    {item.toUpperCase()}
                  </Option>
                );
              })}
            </Select>
          </Col>
        </Row>
      )}
    </>
  );
}
