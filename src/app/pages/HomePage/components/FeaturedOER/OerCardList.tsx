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
            />
          </Col>
        );
      })}
    </Row>
  );
}
