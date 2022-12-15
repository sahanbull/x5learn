import React, { ReactComponentElement, ReactElement, useCallback } from 'react';
import { Card, Row, Skeleton, Space, Typography, Popover } from 'antd';
import { AppstoreOutlined } from '@ant-design/icons';
import Avatar from 'antd/lib/avatar/avatar';
import Meta from 'antd/lib/card/Meta';
import styled from 'styled-components';
import { Link, useHistory, useLocation, useParams } from 'react-router-dom';
import { ROUTES } from 'routes/routes';
import { EnrichmentBar } from 'app/components/EnrichmentBar/EnrichmentBar';
import { OerIcon } from 'app/components/OerIcon/OerIcon';
import { useTranslation } from 'react-i18next';
import { AddToPlaylistButton } from 'app/components/AddToPlaylistButton/AddToPlaylistButton';
import { useSelector } from 'react-redux';
import { selectUnveilAi } from 'app/containers/Header/HeaderSlice';

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
  translations?: any;
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
  /* position: absolute; */
  top: 8px;
  right: 8px;
`;

export function OerCard(props: {
  loading?: boolean;
  card?: OerDao;
  playlistID?: any;
}) {
  const unveilAi = useSelector(selectUnveilAi);
  const { loading, card, playlistID } = props;
  const cardStyle = {
    borderRadius: 8,
    overflow: 'hidden',
  };
  const subTitleStyle = {
    position: 'absolute' as 'absolute',
    fontSize: '12px',
    padding: '8px',
    background: 'black',
    color: 'white',
    opacity: 0.6,
  };

  const unveilAiSubtitleStyle = {
    ...subTitleStyle,
    border: '2px solid red',
  };

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
            {!unveilAi &&
              card?.translations &&
              Object.keys(card.translations).length > 0 && (
                <p style={subTitleStyle}>
                  {`Subtitles: ${Object.keys(card.translations).join(' ')}`}
                </p>
              )}
            {unveilAi &&
              card?.translations &&
              Object.keys(card.translations).length > 0 && (
                <Popover
                  title=""
                  content={
                    <div style={{ maxWidth: '400px' }}>
                      <p>
                        X5GON&#39;s Translate not just translates, but also
                        transcribes any type of content from videos to
                        textbooks. Using cutting-edge machine learning software,
                        our service provides results that come close to human
                        translations. Your text is processed within seconds and
                        has quality is comparable with Google Translate.
                      </p>
                      <a href="#">Try it yourself</a>
                    </div>
                  }
                  trigger="hover"
                >
                  <p style={unveilAiSubtitleStyle}>
                    {`Subtitles: ${Object.keys(card.translations).join(' ')}`}
                  </p>
                </Popover>
              )}
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
          align="middle"
          style={{ position: 'absolute', top: '5px', right: '5px' }}
        >
          <Space size={3} align="start">
            <AddToPlaylistButton
              oerId={card?.id}
              size="small"
              hideLabel={true}
            />
            {card?.duration && <Duration>{card?.duration}</Duration>}
          </Space>
        </Row>
      </Card>
    </Link>
  );
}
