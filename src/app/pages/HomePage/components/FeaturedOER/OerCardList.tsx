import React from 'react';
import { Col, Empty, Row } from 'antd';
import { WarningOutlined } from '@ant-design/icons';
import { useTranslation } from 'react-i18next';

import { OerCard } from './OerCard';

import './OerCardList.less';

const responsiveColWidths = {
  xs: { span: 24 },
  sm: { span: 12 },
  md: { span: 8 },
  lg: { span: 4 },
  xl: { span: 4 },
  xxl: { span: 4 },
};

export function OerCardList(props: {
  loading?: boolean;
  error?: any | null;
  data?: any[] | null;
  playlistID?: any;
}) {
  const { t } = useTranslation();
  const { loading, error, data, playlistID } = props;

  const handleCardClick = async (item: any) => {
    try {
      const payload = {
        action_type_id: 1,
        params: JSON.stringify({ oerId: item.id }),
        is_bundled: false,
      };

      await fetch(`${process.env.REACT_APP_BASE_URL}/action/`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
        },
        body: JSON.stringify(payload),
        credentials: 'include',
      });
    } catch (clickError) {
      console.error('Failed to log action', clickError);
    }
  };

  if (loading) {
    return (
      <Row className="x5-oer-card-grid" gutter={[20, 20]}>
        {[0, 1, 2, 3].map(index => (
          <Col key={index} {...responsiveColWidths}>
            <div className="x5-oer-card-shell">
              <OerCard loading />
            </div>
          </Col>
        ))}
      </Row>
    );
  }

  if (error) {
    return (
      <Empty
        description={t('alerts.lbl_load_playlist_oers_error')}
        image={<WarningOutlined />}
      />
    );
  }

  if (!data || data.length === 0) {
    return <Empty description={t('alerts.lbl_load_playlists_no_oers')} />;
  }

  return (
    <Row className="x5-oer-card-grid" gutter={[20, 20]}>
      {data.map((item, index) => (
        <Col
          key={`${item.id}-${item.last_accessed || index}`}
          {...responsiveColWidths}
        >
          <div className="x5-oer-card-shell">
            <OerCard
              card={item}
              playlistID={playlistID}
              loading={item.loading}
              onClick={() => handleCardClick(item)}
            />
          </div>
        </Col>
      ))}
    </Row>
  );
}
