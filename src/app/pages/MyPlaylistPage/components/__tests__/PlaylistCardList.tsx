import React from 'react';
import { Row, Col, Empty } from 'antd';
import { WarningOutlined } from '@ant-design/icons';

import { PlaylistCard } from './PlaylistCard';
import './PlaylistCardList.less';

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
          <PlaylistCard loading />
        </Col>

        <Col span={8}>
          <PlaylistCard loading />
        </Col>

        <Col span={8}>
          <PlaylistCard loading />
        </Col>
      </Row>
    );
  }

  if (error) {
    return (
      <Empty
        description="An error has occurred"
        image={<WarningOutlined />}
      />
    );
  }

  if (!data || data.length === 0) {
    return <Empty description="No Data" />;
  }

  return (
    <Row gutter={[16, 16]}>
      {data.map((item, index) => {
        const playlistItemCount = Array.isArray(item.playlistItemData)
          ? item.playlistItemData.length
          : 0;

        return (
          <Col key={`${index}-${item.id || item.title}`} span={8}>
            <div className="playlist-card-wrapper">
              <span
                className="playlist-card-item-count"
                title={`${playlistItemCount} playlist items`}
              >
                {playlistItemCount}
              </span>

              <PlaylistCard playlist={item} />
            </div>
          </Col>
        );
      })}
    </Row>
  );
}