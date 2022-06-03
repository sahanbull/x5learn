import React, { useCallback, useEffect, useState } from 'react';
import { Input, Button, Row, Col, Select } from 'antd';
import {
  AppstoreOutlined,
  CaretDownOutlined,
  CaretUpOutlined
} from '@ant-design/icons';

import './HeaderSearchBar.less';
import { useHistory, useLocation } from 'react-router-dom';
import { ROUTES } from 'routes/routes';
import queryString from 'query-string';

const { Search } = Input;
const { Option } = Select;

const defaultTypes = ['mp4', 'ogg', 'webm', 'video', 'mov', 'mp3', 'pdf'];
const defaultLanguages = [
  { value: 'en', label: 'English' },
  { value: 'fr', label: 'French' },
  { value: 'es', label: 'Spanish' },
  { value: 'de', label: 'German' },
  { value: 'it', label: 'Italian' },
  { value: 'ru', label: 'Russian' },
  { value: 'ar', label: 'Arabic' },
];
const defaultLicenses = [
  'cc',
  'by',
  'by-nc',
  'by-sa',
  'by-nd',
  'by-nc-nd',
  'by-nc-sa',
];
const defaultProviders = [{ value: '1', label: 'Videolecture.net' }];
let stringArray: any[];
let stringType: string;

function useQuery() {
  return new URLSearchParams(useLocation().search);
}

export function HeaderSearchBar(props) {
  let history = useHistory();
  let query = useQuery();

  const [showAdvansedOptions, setShowAdvansedOptions] = useState(false);
  const [type, setType] = useState(stringArray);
  const [language, setLanguage] = useState(stringArray);
  const [provider, setProvider] = useState(stringType);
  const [licenses, setLicenses] = useState(stringArray);

  const searchHandler = useCallback(
    inputText => {
      setShowAdvansedOptions(false);
      const qs = queryString.stringify({
        q: inputText,
        type: type.join(','),
        language: language.join(','),
        provider,
        licenses: licenses.join(','),
      });
      history.push(`${ROUTES.SEARCH}?${qs}`);
    },
    [history, type, language, provider, licenses],
  );

  useEffect(() => {
    setType(query.get('type')?.toString().toLocaleLowerCase().split(',') || []);
    setLanguage(query.get('language')?.toString().toLocaleLowerCase().split(',') || []);
    setLicenses(query.get('licenses')?.toString().toLocaleLowerCase().split(',') || []);
    setProvider(query.get('provider')?.toString().toLocaleLowerCase() || '');
  }, [history]);

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
            <p style={{ position: 'absolute', left: '10px' }}>Material Type:</p>
            <Select
              mode="multiple"
              placeholder="Please select"
              defaultValue={
                query.get('type')
                  ? query.get('type')?.toString().toLocaleLowerCase().split(',')
                  : []
              }
              style={{ width: '20vw' }}
              loading={false}
              onChange={(value: string[]) => {
                console.log(value);
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
            <p style={{ position: 'absolute', left: '10px' }}>Licenses:</p>
            <Select
              mode="multiple"
              placeholder="Please select"
              defaultValue={
                query.get('licenses')
                  ? query.get('type')?.toString().toLocaleLowerCase().split(',')
                  : []
              }
              style={{ width: '20vw' }}
              loading={false}
              onChange={(value: string[]) => {
                setLicenses(value);
              }}
            >
              {defaultLicenses.map((item: string) => {
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
              mode="multiple"
              placeholder="Please select"
              defaultValue={
                query.get('language')
                  ? query.get('type')?.toString().toLocaleLowerCase().split(',')
                  : []
              }
              style={{ width: '20vw' }}
              loading={false}
              onChange={(value: string[]) => {
                setLanguage(value);
              }}
            >
              {defaultLanguages.map(item => {
                return (
                  <Option key={item.value} value={item.value}>
                    {item.label}
                  </Option>
                );
              })}
            </Select>
          </Col>
          <Col flex="auto">
            <p style={{ position: 'absolute', left: '10px' }}>Provider:</p>
            <Select
              placeholder="Please select"
              defaultValue={
                query.get('provider')?.toString().toLocaleLowerCase() ||
                undefined
              }
              style={{ width: '20vw' }}
              loading={false}
              onChange={value => {
                setProvider(value);
              }}
            >
              {defaultProviders.map(item => {
                return (
                  <Option key={item.value} value={item.value}>
                    {item.label}
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
