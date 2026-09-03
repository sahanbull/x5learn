import React from 'react';
import { Card, Image, Skeleton, Typography } from 'antd';
import styled from 'styled-components';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

import { OerIcon } from 'app/components/OerIcon/OerIcon';
import { ROUTES } from 'routes/routes';

import './OerSortableView.less';

const { Text, Title } = Typography;

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

const Duration = styled.span`
  position: absolute;
  right: 8px;
  bottom: 8px;
  padding: 3px 7px;
  background: rgba(13, 24, 54, 0.9);
  border-radius: 6px;
  color: #ffffff;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.2px;
  line-height: 1.35;
`;

export function OerSortableView(props: {
  loading?: boolean;
  card?: OerDao;
  playlistID?: any;
  notesView?: boolean;
  tempPlaylistName?: string;
  onClick?: () => void;
}) {
  const {
    loading,
    card,
    playlistID,
    notesView,
    tempPlaylistName,
    onClick,
  } = props;
  const { t } = useTranslation();

  let pathToNavigateTo = `${ROUTES.RESOURCES}/${card?.id}`;

  if (notesView) {
    pathToNavigateTo = `${ROUTES.RESOURCES}/${card?.oer_id}`;
  }

  if (playlistID) {
    pathToNavigateTo += `?playlist=${playlistID}&mode=playlist`;
  } else if (tempPlaylistName) {
    pathToNavigateTo += `?mode=temp_playlist&title=${encodeURIComponent(
      tempPlaylistName,
    )}`;
  }

  if (loading) {
    return (
      <Card className="x5-oer-sortable-card x5-oer-sortable-card--loading">
        <Skeleton active paragraph={{ rows: 2 }} />
      </Card>
    );
  }

  const imageSource =
    card?.images?.[0] || '/static/img/thumbnail_unavailable.jpg';

  return (
    <Card className="x5-oer-sortable-card">
      <div className="x5-oer-sortable-content">
        <Link
          to={pathToNavigateTo}
          className="x5-oer-sortable-image-link"
          onClick={onClick}
        >
          <Image
            width="100%"
            height="100%"
            src={imageSource}
            fallback="/static/img/thumbnail_unavailable.jpg"
            placeholder={false}
            preview={false}
            alt={card?.title || 'Resource thumbnail'}
          />
          {card?.duration && <Duration>{card.duration}</Duration>}
        </Link>

        <div className="x5-oer-sortable-details">
          {notesView ? (
            <>
              <Link
                to={pathToNavigateTo}
                className="x5-oer-sortable-title-link"
              >
                <Title level={5}>{card?.text}</Title>
              </Link>
              <Text className="x5-oer-sortable-note-title">
                {card?.title}
              </Text>
            </>
          ) : (
            <>
              <Link
                to={pathToNavigateTo}
                className="x5-oer-sortable-title-link"
              >
                <Title level={5}>{card?.title}</Title>
              </Link>

              <div className="x5-oer-sortable-meta-row">
                <Text strong>
                  {t('playlist.lbl_playlist_provider', 'By')}:
                </Text>
                <Text>{card?.provider || '-'}</Text>
              </div>

              <div className="x5-oer-sortable-meta-row">
                <Text strong>
                  {t('playlist.lbl_playlist_mediatype', 'Type')}:
                </Text>
                <span className="x5-oer-sortable-type">
                  <OerIcon mediatype={card?.mediatype} />
                  <span>{card?.mediatype}</span>
                </span>

                {card?.date && (
                  <>
                    <span className="x5-oer-sortable-separator" />
                    <Text strong>
                      {t('playlist.lbl_playlist_date', 'Date')}:
                    </Text>
                    <Text>{card.date}</Text>
                  </>
                )}
              </div>
            </>
          )}
        </div>
      </div>
    </Card>
  );
}
