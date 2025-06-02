import React, { ReactComponentElement, ReactElement, useCallback, useEffect } from 'react';
import { Card, Col, Image, Row, Skeleton, Space, Typography } from 'antd';
import Avatar from 'antd/lib/avatar/avatar';
import Meta from 'antd/lib/card/Meta';
import styled from 'styled-components';
import { Link, useHistory, useLocation, useParams } from 'react-router-dom';
import { ROUTES } from 'routes/routes';
import { EnrichmentBar } from 'app/components/EnrichmentBar/EnrichmentBar';
import Title from 'antd/lib/typography/Title';
import { OerIcon } from 'app/components/OerIcon/OerIcon';
import { useTranslation } from 'react-i18next';
import axios from 'axios';
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
  text?: string;
  oer_id?: string;
}

const imageBaseURL = process.env.REACT_APP_IMAGE_BASE_URL;

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
  position: absolute;
  top: 2px;
  right: 2px;
`;

export function OerSortableView(props: {
  loading?: boolean;
  card?: OerDao;
  playlistID?: any;
  notesView?: boolean;
  tempPlaylistName?: string;
  onClick?: () => void;
}) {
   const { loading, card, playlistID, notesView, tempPlaylistName, onClick } = props;
  const cardStyle = { borderRadius: 8, overflow: 'hidden' };
  const history = useHistory();
  const { t } = useTranslation();

  // useEffect(() => {
  //   const fetchPlaylist = async () => {
  //     try {
  //       const { data } = await axios.get(`/api/v1/playlist/${tempPlaylistName}`);
  //       console.log('Fetched playlist data:', data);
  //     } catch (error) {
  //       console.error('Error fetching playlist:', error);
  //     }
  //   };

  //   if (tempPlaylistName) {
  //     fetchPlaylist();
  //   }
  // }, [tempPlaylistName]);

  // console.log('Temp Playlist Name:', tempPlaylistName);
  


  let pathToNavigateTo = `${ROUTES.RESOURCES}/${card?.id}`;
  if (notesView) {
    pathToNavigateTo = `${ROUTES.RESOURCES}/${card?.oer_id}`;
  }
  if (playlistID) {
    pathToNavigateTo += `?playlist=${playlistID}&mode=playlist`;
  } else if (tempPlaylistName) {
    pathToNavigateTo += `?mode=temp_playlist&title=${encodeURIComponent(tempPlaylistName)}`;
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
    console.log("image",imgSrc);
  }
  
  return (
    <>
      <Space align="center">
        <Link
          to={pathToNavigateTo}
          style={{ position: 'relative', display: 'grid' }}
           onClick={onClick}
        >
          <Image
            width={120}
            src={`${card?.images[0]}`}
            placeholder={false}
            preview={false}
            alt={`${card?.title}`}
          />
          <Duration>{card?.duration}</Duration>
        </Link>

        <div>
          {notesView && (
            <>
              <Link to={pathToNavigateTo}>
                <Title level={5}>{card?.text}</Title>
              </Link>
              {card?.title}
            </>
          )}
          {!notesView && (
            <>
              <Link to={pathToNavigateTo}>
                <Title level={5}>{card?.title}</Title>
              </Link>

              <Text strong>{t('playlist.lbl_playlist_provider', 'By')}: </Text>
              {card?.provider}
              <br />

              <Space direction="horizontal" align="center">
                <Text strong>{t('playlist.lbl_playlist_mediatype', 'Type')}: </Text>
                <OerIcon mediatype={card?.mediatype} />

                <span>{card?.mediatype}</span>
              </Space>

              {card?.date && (
                <>
                  {' / '}
                  <Text strong>{t('playlist.lbl_playlist_date', 'Date')}: </Text>
                  {card?.date}
                </>
              )}
            </>
          )}
        </div>
      </Space>
    </>
  );
}
