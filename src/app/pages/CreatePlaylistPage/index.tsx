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
} from 'antd';
import { AppLayout } from 'app/containers/Layout/AppLayout';
import { UploadOutlined } from '@ant-design/icons';
import { PlaylistCreateFormWidget } from 'app/components/PlaylistForm/PlaylistCreateFormWidget';
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

export function CreatePlaylistsPage(props) {
  const {t} = useTranslation()
  const error: null | { msg: object } = null,
    loading = false,
    data = { title: '', description: '', oerIds: [], last_updated_at: '' };

  return (
    <>
      <Helmet>
        <title>{t('playlist.lbl_create_playlist')}</title>
        <meta name="description" content="X5 Learn AI based learning" />
      </Helmet>
      <AppLayout>
        {loading && <Spin spinning={loading} delay={200}></Spin>}
        {error && <div>{t('alerts.lbl_error_loading')}</div>}

        {data && (
          <>
            <Row gutter={[16, 16]}>
              <Col span={24}>
                <Card
                  headStyle={{ border: 'none' }}
                  title={<Title>{t('playlist.lbl_create_playlist')}</Title>}
                >
                  <PlaylistCreateFormWidget />
                </Card>
              </Col>
            </Row>
          </>
        )}
      </AppLayout>
    </>
  );
}
