import React from 'react';
import { Row, Col, Empty } from 'antd';
import { WarningOutlined } from '@ant-design/icons';

import { PlaylistCard } from './PlaylistCard';
import './PlaylistCardList.less';

function getPlaylistItemCount(item: any): number {
  // Prefer an exact count supplied by the backend.
  const backendCount =
    item?.playlist_item_count ??
    item?.playlistItemCount ??
    item?.item_count;

  if (
    backendCount !== undefined &&
    backendCount !== null &&
    Number.isFinite(Number(backendCount))
  ) {
    return Number(backendCount);
  }

  // This normally contains every resource ID in the playlist.
  if (Array.isArray(item?.oerIds)) {
    return item.oerIds.length;
  }

  // Used by some temporary-playlist responses.
  if (Array.isArray(item?.playlist_items)) {
    return item.playlist_items.length;
  }

  // Fallback because this array can contain partially loaded details.
  if (Array.isArray(item?.playlistItemData)) {
    return item.playlistItemData.length;
  }

  return 0;
}

export function PlaylistCardList(props: {
  loading?: boolean;
  error?: any | null;
  data?: any[] | null;
  playlistID?: any;
}) {
  const { loading, error, data } = props;

  if (loading) {
    return (
      <Row gutter={[16, 16]}>
        <Col xs={24} sm={12} lg={8}>
          <PlaylistCard loading />
        </Col>

        <Col xs={24} sm={12} lg={8}>
          <PlaylistCard loading />
        </Col>

        <Col xs={24} sm={12} lg={8}>
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
        const playlistItemCount = getPlaylistItemCount(item);

        return (
          <Col
            key={`${item.id ?? item.title ?? 'playlist'}-${index}`}
            xs={24}
            sm={12}
            lg={8}
          >
            <div className="playlist-card-wrapper">
              <span
                className="playlist-card-item-count"
                title={`${playlistItemCount} playlist items`}
                aria-label={`${playlistItemCount} playlist items`}
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