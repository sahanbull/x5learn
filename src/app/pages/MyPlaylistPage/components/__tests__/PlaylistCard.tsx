import React from 'react';
import { Card, Skeleton, Typography } from 'antd';
import Meta from 'antd/lib/card/Meta';
import { Link } from 'react-router-dom';
import { ROUTES } from 'routes/routes';

const { Text } = Typography;
const cardStyle = { borderRadius: 8, overflow: 'hidden' };

export function PlaylistCard(props: { playlist?; loading?: boolean }) {
  const { loading, playlist } = props;

  let pathToNavigateTo = `${ROUTES.PLAYLISTS}/${playlist?.id}`;
  if (!playlist?.id) {
    pathToNavigateTo = `${ROUTES.PLAYLISTS}/temp/${playlist?.title}`;
  }

  if (loading) {
    return (
      <Card style={cardStyle}>
        <Skeleton active></Skeleton>
      </Card>
    );
  }
  return (
    <Link to={pathToNavigateTo}>
      <Card hoverable bordered={false} style={cardStyle}>
        <Meta
          title={playlist?.title}
          description={
            <>
              <Text strong>Author: </Text>
              {playlist?.author}
              <br />
              <Text strong>Date: </Text>
              {playlist?.last_updated_at}
              <br />
              <Text strong>Description: </Text>
              {playlist?.description}
            </>
          }
        />
      </Card>
    </Link>
  );
}
