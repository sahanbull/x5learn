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
  Modal,
  message,
} from 'antd';
import { AppLayout } from 'app/containers/Layout/AppLayout';
import { DeleteOutlined, UploadOutlined } from '@ant-design/icons';
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
import { PlaylistPublishFormWidget } from './PlaylistPublishFormWidget';
import { PlaylistItemSortWidget } from '../PlaylistItemSortWidget/PlaylistItemSortWidget';
import { updateTempPlaylistThunk } from 'app/containers/Layout/ducks/myPlaylistMenu/updateTempPlaylist';
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

export function PlaylistEditFormWidget(props: { formData? }) {
  const [form] = Form.useForm();
  const history = useHistory();
  const { t } = useTranslation();

  const { data: licenseData, loading, error } = useSelector(
    (state: RootState) => {
      return state.playlistLicenses;
    },
  );

  const { playlist, playlist_items } = props.formData;
  const dispatch = useDispatch();

  useEffect(() => {
    if (!licenseData) {
      dispatch(fetchPlaylistLicensesThunk());
    }
  }, [licenseData, dispatch]);

  const [isModalVisible, setIsModalVisible] = useState(false);
  const [isUpdating, setIsUpdating] = useState(false);

  const showModal = () => {
    setIsModalVisible(true);
  };

  const onItemsReorder = async newOrder => {
    try {
      const oerIdsArray = newOrder.map(item => {
        return parseInt(item.data);
      });
      setIsUpdating(true);
      const updateOrderCall = (await dispatch(
        updateTempPlaylistThunk({
          ...playlist,
          temp_title: playlist.title,
          playlist_items: oerIdsArray,
        }),
      )) as any;
      const updateOrderResult = await unwrapResult(updateOrderCall);
      setIsUpdating(false);
      message.info(t('alerts.lbl_playlist_update_success'));
    } catch (e) {
      setIsUpdating(false);
      message.error(t('alerts.lbl_playlist_update_error'));
    }
  };

  return (
    <Form
      {...layout}
      form={form}
      name="basic"
      initialValues={{ remember: true }}
    >
      <Row gutter={[16, 16]}>
        <Col span={24}>
          <PlaylistItemSortWidget
            playlist_items={playlist_items}
            onItemsReorder={onItemsReorder}
            isUpdating={isUpdating}
          />
        </Col>
      </Row>

      <Form.Item {...tailLayout}>
        {/* <Button type="primary" htmlType="submit" size="large">
          Save <UploadOutlined />
        </Button> */}
        <Button
          type="primary"
          htmlType="button"
          size="large"
          onClick={showModal}
          disabled={isUpdating}
        >
          {t('playlist.lbl_publish_playlist')} <UploadOutlined />
        </Button>
      </Form.Item>

      <>
        <PlaylistPublishFormWidget
          visible={isModalVisible}
          setIsModalVisible={setIsModalVisible}
          formData={props.formData}
        />
      </>
    </Form>
  );
}
