import React from 'react';
import { Row, Col, Empty } from 'antd';
import { OerCard } from './OerCard';
import { WarningOutlined } from '@ant-design/icons';
import { useTranslation } from 'react-i18next';

const responsiveColWidths = {
  xs: { span: 24 },
  sm: { span: 12 },
  lg: { span: 8 },
};
export function OerCardList(props: {
  loading?: boolean;
  error?: any | null;
  data?: any[] | null;
  playlistID?: any;
}) {
  const { t } = useTranslation();
  const { loading, error, data } = props;


   const handleCardClick = async (item: any) => {
    try {
      const payload = {
        action_type_id: 1,
        params: JSON.stringify({ oer_id: item.id }),
        is_bundled: false,
        action_type_ids: [1],
        params_list: [JSON.stringify({ oer_id: item.id })],
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

      console.log(`Action logged for item ID: ${item.id}`);
    } catch (err) {
      console.error('Failed to log action', err);
    }
  };


  if (loading) {
    return (
      <Row gutter={16}>
        <Col {...responsiveColWidths}>
          <OerCard loading={true} />
        </Col>
        <Col {...responsiveColWidths}>
          <OerCard loading={true} />
        </Col>
        <Col {...responsiveColWidths}>
          <OerCard loading={true} />
        </Col>
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

  if (!data || data?.length === 0) {
    return <Empty description={t('alerts.lbl_load_playlists_no_oers')} />;
  }

  return (
    <Row gutter={[16, 16]}>
      {data?.map(item => {
        return (
          <Col
            key={`${item.id}-${item.last_accessed}`}
            {...responsiveColWidths}
          >
            <OerCard
              card={item}
              playlistID={props.playlistID}
              loading={item.loading}
              onClick={() => handleCardClick(item)}
            />
          </Col>
        );
      })}
    </Row>
  );
}
