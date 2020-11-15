import React from 'react';
import { Row, Col } from 'antd';
import { OerCard } from './OerCard';

export function OerCardList(props) {
  return (
    <Row gutter={16}>
      <Col span={8}>
        <OerCard />
      </Col>
      <Col span={8}>
        <OerCard />
      </Col>
      <Col span={8}>
        <OerCard />
      </Col>
    </Row>
  );
}
