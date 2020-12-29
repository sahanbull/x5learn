import React, { useEffect } from 'react';
import { Helmet } from 'react-helmet-async';
import { Row, Col, Card, Typography, Button, Progress } from 'antd';
import { AppLayout } from 'app/containers/Layout/AppLayout';
import { UploadOutlined } from '@ant-design/icons';
import { OerCardList } from '../HomePage/components/FeaturedOER/OerCardList';
import { useInjectReducer } from 'redux-injectors';
import { useDispatch } from 'react-redux';
import {
  fetchPlaylistDetailsThunk,
  sliceKey,
  reducer,
} from './ducks/fetchPlaylistDetailsThunk';

const { Title, Text } = Typography;

export function PlaylistsPage() {
  useInjectReducer({ key: sliceKey, reducer: reducer });
  const dispatch = useDispatch();

  useEffect(() => {
    dispatch(fetchPlaylistDetailsThunk());
  }, [dispatch]);

  return (
    <>
      <Helmet>
        <title>Playlists Page</title>
        <meta name="description" content="X5 Learn AI based learning" />
      </Helmet>
      <AppLayout>
        <Row gutter={16}>
          <Col span={16}>
            <Card
              headStyle={{ border: 'none' }}
              title={<Title level={2}>My Playlist 01</Title>}
              extra={<a href="#">More</a>}
            >
              <p>
                Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec
                porttitor, est ac consectetur tristique, orci urna ultrices
                sapien, nec commod.
              </p>
              <Text strong>17</Text>
              <Text> OER Materials</Text> {` / `}
              <Text strong>Updated: </Text>
              <Text>May 9, 2019</Text>
              <br />
              <Button
                type="primary"
                shape="round"
                icon={<UploadOutlined />}
                size="large"
              >
                Download
              </Button>
            </Card>
          </Col>
          <Col span={8}>
            <Card
              style={{ backgroundColor: '#00ad57', color: `#ffffff` }}
              headStyle={{ border: 'none', color: `#ffffff` }}
              title={`Progress`}
              extra={<a href="#">More</a>}
            >
              <Text style={{ color: `#ffffff` }}>
                {' '}
                You currently <strong>completed 55%</strong> of your learning
                path.
              </Text>
              <br />
              <Progress percent={55} strokeColor={`#008c41`} showInfo={false} />
              <Text style={{ color: `#ffffff` }}>
                {' '}
                Our algorithm has changed the sequence of your items to help you
                learn better!
              </Text>
              <br />
              <Button style={{ color: `#ffffff` }} type="link">
                Undo
              </Button>
            </Card>
          </Col>
        </Row>
        <OerCardList data={[]} />
      </AppLayout>
    </>
  );
}
