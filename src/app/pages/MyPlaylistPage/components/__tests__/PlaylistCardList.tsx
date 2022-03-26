import React from 'react';
import { Row, Col, Empty } from 'antd';
import { PlaylistCard } from './PlaylistCard';
import { WarningOutlined } from '@ant-design/icons';

export function PlaylistCardList(props: {
  loading?: boolean;
  error?: any | null;
  data?: any[] | null;
  playlistID?: any;
}) {
  const { loading, error, data } = props;
  if (loading) {
    return (
      <Row gutter={16}>
        <Col span={8}>
          <PlaylistCard loading={true} />
        </Col>
        <Col span={8}>
          <PlaylistCard loading={true} />
        </Col>
        <Col span={8}>
          <PlaylistCard loading={true} />
        </Col>
      </Row>
    );
  }

  if (error) {
    return (
      <Empty description="An error has occurred" image={<WarningOutlined />} />
    );
  }

  if (!data || data?.length === 0) {
    return <Empty description="No Data" />;
  }

  return (
    <Row gutter={[16, 16]}>
      {data?.map((item, index) => {
        return (
          <Col key={`${index}${item.id}`} span={8}>
            <PlaylistCard playlist={item} />
          </Col>
        );
      })}
    </Row>
  );
}
