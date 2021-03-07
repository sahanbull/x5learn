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
import { RootState } from 'types';
import { useSelector } from 'react-redux';
import { MyPlaylistWidget } from './components/__tests__/MyPlaylistWidget';

const { Option } = Select;
const { TextArea } = Input;
const { Title, Text } = Typography;

export function MyPlaylistsPage(props) {
  return (
    <>
      <Helmet>
        <title>Playlists Page</title>
        <meta name="description" content="X5 Learn AI based learning" />
      </Helmet>
      <AppLayout>
    
          <MyPlaylistWidget />
        
      </AppLayout>
    </>
  );
}
