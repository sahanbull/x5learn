import React, { useEffect, useState } from 'react';
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
  Popconfirm,
} from 'antd';
import { AppLayout } from 'app/containers/Layout/AppLayout';
import { DeleteOutlined, UploadOutlined } from '@ant-design/icons';
import {
  fetchTempPlaylistDetailsThunk,
  sliceKey,
  reducer,
} from './ducks/fetchTempPlaylistDetailsThunk';
import { PlaylistEditFormWidget } from 'app/components/PlaylistForm/PlaylistEditFormWidget';
import { useInjectReducer } from 'redux-injectors';
import { useDispatch, useSelector } from 'react-redux';
import { RootState } from 'types';
import { PlaylistDeleteButton } from 'app/components/PlaylistDeleteButton/PlaylistDeleteButton';
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

export function EditTempPlaylistPage(props) {
  useInjectReducer({ key: sliceKey, reducer: reducer });
  const { t } = useTranslation();
  const dispatch = useDispatch();
  const { data, loading, error } = useSelector((state: RootState) => {
    return state.tempPlaylistDetail;
  });

  const playlistID = props.match?.params?.id;
  useEffect(() => {
    dispatch(fetchTempPlaylistDetailsThunk(playlistID));
  }, [dispatch, playlistID]);

  return (
    <>
      <Helmet>
        <title>
          {t('playlist.lbl_playlist_edit') + ` - ${data?.playlist?.title}`}
        </title>
      </Helmet>
      <AppLayout>
        {loading && <Spin spinning={loading} delay={200}></Spin>}
        {error && <div>{t('alerts.lbl_load_playlist_oers_error')}</div>}

        {data && (
          <>
            <Row gutter={[16, 16]}>
              <Col span={24}>
                <Card
                  headStyle={{ border: 'none' }}
                  extra={
                    <PlaylistDeleteButton
                      playlistName={data?.playlist?.title}
                    />
                  }
                  title={
                    <Title>
                      {t('playlist.lbl_playlist_edit')} -{' '}
                      {data?.playlist?.title}
                    </Title>
                  }
                >
                  <PlaylistEditFormWidget formData={data} />
                </Card>
              </Col>
            </Row>
          </>
        )}
      </AppLayout>
    </>
  );
}
