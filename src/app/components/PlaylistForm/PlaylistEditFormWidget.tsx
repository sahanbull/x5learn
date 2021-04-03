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

  const { data: licenseData, loading, error } = useSelector(
    (state: RootState) => {
      return state.playlistLicenses;
    },
  );

  const { playlist, playlist_items } = props.formData;

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

  const [isModalVisible, setIsModalVisible] = useState(false);

  const showModal = () => {
    setIsModalVisible(true);
  };
debugger
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
          history.push(`${ROUTES.PLAYLISTS}/temp/${values.temp_title}`);
        } catch (err) {
          message.error('Error saving playlist...');
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
            label="Playlist Items"
            name="playlist_items1"
            rules={[
              {
                required: false,
                message: 'No items added to playlist',
              },
            ]}
          ></Form.Item>

          {playlist_items && playlist_items.map(item=>{
            return (
              <Typography.Text key={item.data}>{item.data}</Typography.Text>
            )
          })}
        </Col>
      </Row>

      <Form.Item {...tailLayout}>
        <Button type="primary" htmlType="submit" size="large">
          Save <UploadOutlined />
        </Button>
        <Button
          type="primary"
          htmlType="button"
          size="large"
          onClick={showModal}
        >
          Publish... <UploadOutlined />
        </Button>
        {createLoading && (
          <Progress percent={100} status="active" showInfo={false} />
        )}
        {createError && <Text type="danger">Error creating playlist...</Text>}
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
