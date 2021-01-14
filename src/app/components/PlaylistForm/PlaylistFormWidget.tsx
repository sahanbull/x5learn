import styled from 'styled-components/macro';
import { Helmet } from 'react-helmet-async';
import {
  Row,
  Col,
  Card,
  Typography,
  Button,
  Progress,
  Spin,
  Form,
  Input,
  Select,
  message,
} from 'antd';
import { AppLayout } from 'app/containers/Layout/AppLayout';
import { UploadOutlined } from '@ant-design/icons';
import { useDispatch, useSelector } from 'react-redux';
import { RootState } from 'types';
import { useEffect, useState } from 'react';
import { fetchPlaylistLicensesThunk } from 'app/containers/Layout/ducks/playlistLicenseSlice';
import { createTempPlaylistThunk } from 'app/containers/Layout/ducks/myPlaylistsMenuSlice';
import { AsyncThunkAction, unwrapResult } from '@reduxjs/toolkit';

const { Option } = Select;
const { TextArea } = Input;
const { Title, Text } = Typography;

const layout = {
  labelCol: { span: 24 },
  wrapperCol: { span: 24 },
};

const tailLayout = {
  wrapperCol: { offset: 0, span: 16 },
};

export function PlaylistFormWidget() {
  const [form] = Form.useForm();

  const { data: licenseData, loading, error } = useSelector(
    (state: RootState) => {
      return state.playlistLicenses;
    },
  );

  const [
    { createStatus, createLoading, createError },
    setCreateStatus,
  ] = useState({
    createStatus: null,
    createLoading: false,
    createError: null,
  });
  const dispatch = useDispatch();

  useEffect(() => {
    if (!licenseData) {
      dispatch(fetchPlaylistLicensesThunk());
    }
  }, [licenseData, dispatch]);

  const onLicenseChange = (value: string) => {
    form.setFieldsValue({ license: value });
  };

  return (
    <Form
      {...layout}
      form={form}
      name="basic"
      onFinish={async values => {
        setCreateStatus({
          createLoading: true,
          createStatus: null,
          createError: null,
        });
        try {
          const createResult = await dispatch(
            createTempPlaylistThunk({ ...values, title: values.temp_title }),
          );
          const createStatus = await unwrapResult(
            createResult as any,
          );
          debugger;
          setCreateStatus({
            createLoading: false,
            createStatus: createResult as any,
            createError: null,
          });
        } catch (err) {
          debugger;
          message.error("Error creating playlist...")
          setCreateStatus({
            createLoading: false,
            createStatus: null,
            createError: null,
          });
        }
      }}
      initialValues={{ remember: true }}
    >
      <Row gutter={[16, 16]}>
        <Col span={12}>
          <Form.Item
            label="Playlist Title"
            name="temp_title"
            rules={[
              {
                required: true,
                message: 'Please input a playlist title',
              },
            ]}
          >
            <Input placeholder="Playlist title" />
          </Form.Item>
        </Col>
        <Col span={12}>
          <Form.Item
            label="License"
            name="license"
            rules={[
              {
                required: true,
                message: 'Please input a valid licence',
              },
            ]}
          >
            {loading && (
              <Progress percent={100} status="active" showInfo={false} />
            )}
            {error && <Text type="danger">Error loading licenses...</Text>}
            {licenseData && (
              <Select
                placeholder="Select License"
                onChange={onLicenseChange}
                allowClear
              >
                {licenseData.map(option => {
                  return (
                    <Option key={option.id} value={option.id}>
                      {option.description}
                    </Option>
                  );
                })}
              </Select>
            )}
          </Form.Item>
        </Col>
      </Row>

      <Row gutter={[16, 16]}>
        <Col span={12}>
          <Form.Item
            label="Name"
            name="name"
            rules={[
              {
                required: true,
                message: 'Please input your name',
              },
            ]}
          >
            <Input placeholder="Your name" />
          </Form.Item>
        </Col>
        <Col span={12}>
          <Form.Item
            label="Surname"
            name="surname"
            rules={[
              {
                required: true,
                message: 'Please input your surname',
              },
            ]}
          >
            <Input placeholder="Your surname" />
          </Form.Item>
        </Col>
      </Row>

      <Row gutter={[16, 16]}>
        <Col span={24}>
          <Form.Item
            label="Description"
            name="description"
            rules={[
              {
                required: true,
                message: 'Please input a description',
              },
            ]}
          >
            <TextArea
              rows={4}
              placeholder="Description"
              autoSize={{ minRows: 3, maxRows: 6 }}
            />
          </Form.Item>
        </Col>
      </Row>

      <Form.Item {...tailLayout}>
        <Button type="primary" htmlType="submit" size="large">
          Create <UploadOutlined />
        </Button>
        {createLoading && (
          <Progress percent={100} status="active" showInfo={false} />
        )}
        {createError && <Text type="danger">Error creating playlist...</Text>}

        <Button type="text" size="large">
          Cancel X
        </Button>
      </Form.Item>
    </Form>
  );
}
