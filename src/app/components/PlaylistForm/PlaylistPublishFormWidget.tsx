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
  Modal,
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
import { publishTempPlaylistThunk } from 'app/containers/Layout/ducks/myPlaylistMenu/publishTempPlaylist';
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

export function PlaylistPublishFormWidget(props: {
  formData?;
  visible: boolean;
  setIsModalVisible: (a: boolean) => void;
}) {
  const [form] = Form.useForm();
  const history = useHistory();
  const { t } = useTranslation();

  const { data: licenseData, loading, error } = useSelector(
    (state: RootState) => {
      return state.playlistLicenses;
    },
  );

  const [isLoading, setIsLoading] = useState(false);
  const { playlist, playlist_items } = props.formData;

  const dispatch = useDispatch();

  useEffect(() => {
    if (!licenseData) {
      dispatch(fetchPlaylistLicensesThunk());
    }
  }, [licenseData, dispatch]);

  const onLicenseChange = (value: string) => {
    form.setFieldsValue({ license: value });
  };

  const handleOk = async () => {
    try {
      const validate = await form.validateFields();
      const formData = (form as any).getFieldValue();
      setIsLoading(true);
      const publishResponse = (await dispatch(
        publishTempPlaylistThunk({
          tempTitle: formData.temp_title,
          playlist_items: playlist_items.map(item => {
            return parseInt(item.oer_id);
          }),
          ...formData,
          is_temp: false,
        }),
      )) as any;
      const publishResult = await unwrapResult(publishResponse);
      message.success(t('alerts.lbl_publish_playlist_success'));
      history.push(`/playlist/${publishResult}`);
      await dispatch(fetchMyPlaylistsMenuThunk());
      setIsLoading(false);
      props.setIsModalVisible(false);
    } catch (e) {
      setIsLoading(false);
      message.error(t('alerts.lbl_publish_playlist_error'));
    }
  };

  const handleCancel = () => {
    props.setIsModalVisible(false);
  };

  return (
    <Modal
      title={t('playlist.lbl_publish_playlist')}
      visible={props.visible}
      confirmLoading={isLoading}
      cancelButtonProps={{ disabled: isLoading }}
      okText={t('generic.btn_publish')}
      cancelText={t('generic.btn_cancel')}
      onOk={handleOk}
      onCancel={handleCancel}
    >
      <Form
        {...layout}
        form={form}
        name="basic"
        initialValues={{ ...playlist, temp_title: playlist.title }}
      >
        <Row gutter={[16, 16]}>
          <Col span={24}>
            <Form.Item
              label={t('playlist.lbl_playlist_title')}
              name="title"
              rules={[
                {
                  required: true,
                  message: t('alerts.lbl_playlist_title_required_msg'),
                },
              ]}
            >
              <Input
                placeholder={t('alerts.lbl_playlist_title_input_placeholder')}
                defaultValue={playlist.title}
              />
            </Form.Item>
          </Col>
        </Row>

        <Row gutter={[16, 16]}>
          <Col span={12}>
            <Form.Item
              label={t('playlist.lbl_playlist_author')}
              name="author"
              rules={[
                {
                  required: true,
                  message: t('alerts.lbl_playlist_author_required_msg'),
                },
              ]}
            >
              <Input
                placeholder={t('alerts.lbl_playlist_author_input_placeholder')}
                defaultValue={playlist.creator}
              />
            </Form.Item>
          </Col>
          <Col span={12}>
            <Form.Item
              label={t('playlist.lbl_playlist_license')}
              name="license"
              rules={[
                {
                  required: true,
                  message: t('alerts.lbl_playlist_license_required_msg'),
                },
              ]}
            >
              {loading && (
                <Progress percent={100} status="active" showInfo={false} />
              )}
              {error && (
                <Text type="danger">
                  {t('alerts.lbl_license_types_load_error')}
                </Text>
              )}
              {licenseData && (
                <Select
                  placeholder={t(
                    'alerts.lbl_playlist_license_input_placeholder',
                  )}
                  onChange={onLicenseChange}
                  defaultValue={playlist.license}
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
          <Col span={24}>
            <Form.Item
              label={t('playlist.lbl_playlist_description')}
              name="description"
              rules={[
                {
                  required: true,
                  message: t('alerts.lbl_playlist_description_required_msg'),
                },
              ]}
            >
              <TextArea
                rows={4}
                placeholder={t(
                  'alerts.lbl_playlist_description_input_placeholder',
                )}
                autoSize={{ minRows: 3, maxRows: 6 }}
                defaultValue={playlist.description}
              />
            </Form.Item>
          </Col>
        </Row>

        <Form.Item {...tailLayout}></Form.Item>
      </Form>
    </Modal>
  );
}
