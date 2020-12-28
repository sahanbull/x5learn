import React from 'react';
import { Row, Col, Empty } from 'antd';
import { OerCard } from './OerCard';
import { WarningOutlined } from '@ant-design/icons';

export function OerCardList(props: {
  loading?: boolean;
  error?: any | null;
  data?: any[];
}) {
  const { loading, error, data } = props;
  if (loading) {
    return (
      <Row gutter={16}>
        <Col span={8}>
          <OerCard loading={true} />
        </Col>
        <Col span={8}>
          <OerCard loading={true} />
        </Col>
        <Col span={8}>
          <OerCard loading={true} />
        </Col>
      </Row>
    );
  }

  if (error) {
    return (
      <Empty description="An error has occurred" image={<WarningOutlined />} />
    );
  }

  if (!data || data?.length === 0) {
    return <Empty description="No Data" />;
  }

  return (
    <Row gutter={[16, 16]}>
      {data?.map(item => {
        return (
          <Col key={item.id} span={8}>
            <OerCard card={item}/>
          </Col>
        );
      })}
    </Row>
  );
}
