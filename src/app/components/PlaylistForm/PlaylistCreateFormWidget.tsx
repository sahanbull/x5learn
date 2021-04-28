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
import {
  createTempPlaylistThunk,
  fetchMyPlaylistsMenuThunk,
} from 'app/containers/Layout/ducks/myPlaylistsMenuSlice';
import { AsyncThunkAction, unwrapResult } from '@reduxjs/toolkit';
import { useHistory } from 'react-router-dom';
import { ROUTES } from 'routes/routes';
import { useTranslation } from 'react-i18next';

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

export function PlaylistCreateFormWidget() {
  const [form] = Form.useForm();
  const { t } = useTranslation();
  const history = useHistory();

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
          const newTempPlaylist = {
            parent: 0,
            is_visible: true,
            playlist_items: [],
            title: values.temp_title,
            ...values,
          };
          const createResult = await dispatch(
            createTempPlaylistThunk(newTempPlaylist),
          );
          const createStatus = await unwrapResult(createResult as any);
          await dispatch(fetchMyPlaylistsMenuThunk());
          setCreateStatus({
            createLoading: false,
            createStatus: createResult as any,
            createError: null,
          });
          history.push(
            `${ROUTES.PLAYLISTS}/temp/${encodeURI(values.temp_title)}`,
          );
        } catch (err) {
          message.error(t('alerts.lbl_temp_playlist_create_error'));
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
        <Col span={24}>
          <Form.Item
            label={`${t('playlist.lbl_playlist_new')} ${t(
              'playlist.lbl_playlist_title',
            )}`}
            name="temp_title"
            rules={[
              {
                required: true,
                message: t('alerts.lbl_validate_playlist_name_required'),
              },
            ]}
          >
            <Input
              placeholder={`${t('playlist.lbl_playlist_new')} ${t(
                'playlist.lbl_playlist_title',
              )}`}
            />
          </Form.Item>
        </Col>
      </Row>

      <Form.Item {...tailLayout}>
        <Button type="primary" htmlType="submit" size="large" loading={createLoading}>
          {t('playlist.lbl_create_playlist')} <UploadOutlined />
        </Button>
        {createError && (
          <Text type="danger">
            {t('alerts.lbl_temp_playlist_create_error')}
          </Text>
        )}
      </Form.Item>
    </Form>
  );
}
