import React, {
  ReactComponentElement,
  ReactElement,
  useCallback,
  useEffect,
} from 'react';
import { Card, Skeleton, Spin, Typography } from 'antd';
import Avatar from 'antd/lib/avatar/avatar';
import Meta from 'antd/lib/card/Meta';
import styled from 'styled-components';
import { Link, useHistory, useLocation, useParams } from 'react-router-dom';
import { ROUTES } from 'routes/routes';
import { EnrichmentBar } from 'app/components/EnrichmentBar/EnrichmentBar';
import { useDispatch, useSelector } from 'react-redux';
import { RootState } from 'types';
import { useInjectReducer } from 'redux-injectors';
import {
  sliceKey,
  reducer,
  fetchAllMyPlaylistsThunk,
} from '../../ducks/fetchAllMyPlaylistsThunk';
import { WarningOutlined } from '@ant-design/icons';

const { Text, Title } = Typography;
const cardStyle = { borderRadius: 8, overflow: 'hidden' };

export function PlaylistCard(props: { playlist?; loading?: boolean }) {
  const { loading, playlist } = props;

  let pathToNavigateTo = `${ROUTES.PLAYLISTS}/${playlist?.id}`;



  if (loading) {
    return (

      <Card style={cardStyle}>
        <Skeleton active></Skeleton>
      </Card>
    );
  }
 
  return (
    <Link to={pathToNavigateTo}>
      <Card
        hoverable
        bordered={false}
        style={cardStyle}
        
      >
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
