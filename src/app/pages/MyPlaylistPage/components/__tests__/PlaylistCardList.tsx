import React from 'react';
import { Row, Col, Empty } from 'antd';
import { WarningOutlined } from '@ant-design/icons';

import { PlaylistCard } from './PlaylistCard';
import './PlaylistCardList.less';

function getPlaylistItemCount(item: any): number {
  // Prefer complete item-ID arrays because they represent the actual playlist.
  const exactItemArrays = [
    item?.oer_ids,
    item?.oerIds,
    item?.playlist_items,
    item?.playlistItems,
  ];

  const exactItems = exactItemArrays.find(value => Array.isArray(value));

  if (exactItems) {
    return exactItems.filter(
      playlistItem => playlistItem !== null && playlistItem !== undefined,
    ).length;
  }

  // Use a backend count when the response does not include complete item IDs.
  const backendCount =
    item?.playlist_item_count ??
    item?.playlistItemCount ??
    item?.item_count ??
    item?.items_count ??
    item?.oer_count;

  const parsedCount = Number(backendCount);

  if (Number.isFinite(parsedCount) && parsedCount >= 0) {
    return parsedCount;
  }

  // Final fallback for responses containing loaded item details.
  const itemDetails =
    item?.playlist_item_data ??
    item?.playlistItemData ??
    item?.items;

  if (Array.isArray(itemDetails)) {
    return itemDetails.filter(
      playlistItem => playlistItem !== null && playlistItem !== undefined,
    ).length;
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
