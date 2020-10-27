import styled from 'styled-components/macro';
import React from 'react';
import { Layout, Menu, Breadcrumb, Row, Col, Divider } from 'antd';
const { Footer } = Layout;

export const AppFooter = props => {
  const style = { background: '#0092ff', padding: '8px 0' };
  return (
    <Footer style={{ textAlign: 'center' }}>
      <Divider orientation="left"></Divider>
      <Row gutter={16}>
        <Col className="gutter-row" span={6}>
          <div style={style}>col-6</div>
        </Col>
        <Col className="gutter-row" span={6}>
          <div style={style}>col-6</div>
        </Col>
        <Col className="gutter-row" span={6}>
          <div style={style}>col-6</div>
        </Col>
        <Col className="gutter-row" span={6}>
          <div style={style}>col-6</div>
        </Col>
      </Row>
    </Footer>
  );
};
