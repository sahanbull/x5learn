
import React from 'react';
import { Row, Col } from 'antd';
export function X5MenuTitle(props) {
  return (
    <>
      <Row justify="space-between" align="middle">
        <Col>
          <strong> {props.children}</strong>
        </Col>
        <Col>{props.icon}</Col>
      </Row>
    </>
  );
}
