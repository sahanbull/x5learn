import React, { ReactComponentElement, ReactElement, useCallback } from 'react';
import { Card, Row, Skeleton, Typography } from 'antd';
import Avatar from 'antd/lib/avatar/avatar';
import Meta from 'antd/lib/card/Meta';
import styled from 'styled-components';
import { Link, useHistory, useLocation, useParams } from 'react-router-dom';
import { ROUTES } from 'routes/routes';
import { EnrichmentBar } from 'app/components/EnrichmentBar/EnrichmentBar';
import { OerIcon } from 'app/components/OerIcon/OerIcon';
import { useTranslation } from 'react-i18next';
import { AddToPlaylistButton } from 'app/components/AddToPlaylistButton/AddToPlaylistButton';

const { Text } = Typography;

interface OerDao {
  date?: string;
  description?: string;
  duration?: string;
  durationInSeconds: number;
  id: number;
  images: string[];
  material_id: string;
  mediatype: 'video' | 'audio' | 'pdf';
  provider: string;
  title: string;
  url: string;
}

const imageBaseURL = 'https://qa.x5learn.org/files/thumbs/';

const Duration = styled.span`
  padding: 0px 6px 2px 6px;
  border-radius: 4px;
  background-color: #000d32;
  font-size: 12px;
  font-weight: 600;
  font-stretch: normal;
  font-style: normal;
  line-height: 1.33;
  letter-spacing: 0.3px;
  text-align: center;
  color: #ffffff;
  /* position: absolute; */
  top: 8px;
  right: 8px;
`;

export function OerCard(props: {
  loading?: boolean;
  card?: OerDao;
  playlistID?: any;
}) {
  const { loading, card, playlistID } = props;
  const cardStyle = { borderRadius: 8, overflow: 'hidden' };
  const { t } = useTranslation();
  const history = useHistory();

  let pathToNavigateTo = `${ROUTES.RESOURCES}/${card?.id}`;
  if (playlistID) {
    pathToNavigateTo += `?playlist=${playlistID}`;
  }

  if (loading) {
    return (
      <Card style={cardStyle}>
        <Skeleton active></Skeleton>
      </Card>
    );
  }

  let imgSrc = `/static/img/thumbnail_unavailable.jpg`;
  if (card?.images[0]) {
    imgSrc = `${imageBaseURL}/${card?.images[0]}`;
  }

  return (
    <Link to={pathToNavigateTo}>
      <Card
        hoverable
        bordered={false}
        style={cardStyle}
        cover={
          <>
            <img alt={`${card?.title}`} src={imgSrc} />
            <EnrichmentBar oerID={card?.id} />
          </>
        }
      >
        <Meta
          avatar={
            <Avatar
              shape="circle"
              size={32}
              icon={<OerIcon mediatype={card?.mediatype} />}
              style={{ borderRadius: '50%', backgroundColor: '#f7f8f9' }}
            />
          }
          title={card?.title}
          description={
            <>
              <Text strong>{t('playlist.lbl_playlist_provider')}: </Text>
              {card?.provider}
              <br />
              <Text strong>{t('playlist.lbl_playlist_mediatype')}: </Text>
              {card?.mediatype}
              <br />
              <Text strong>{t('playlist.lbl_playlist_date')}: </Text>
              {card?.date}
            </>
          }
        />
        <Row
          justify="end"
          align="top"
          style={{ position: 'absolute', top: '5px', right: '5px' }}
        >
          <AddToPlaylistButton oerId={card?.id} size="small" hideLabel={true} />
          {card?.duration && <Duration>{card?.duration}</Duration>}
        </Row>
      </Card>
    </Link>
  );
}
