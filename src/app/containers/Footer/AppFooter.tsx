import styled from 'styled-components/macro';
import React from 'react';
import { Layout, Menu, Breadcrumb, Row, Col, Divider } from 'antd';
import { X5Logo } from 'app/components/Logo/X5Logo';
const { Footer } = Layout;

export const AppFooter = props => {
  const style = { background: '#000d32', padding: '8px 0' };
  return (
    <Footer style={{ ...style, textAlign: 'center' }}>
      <Divider orientation="left"></Divider>
      <Row gutter={10}>
        <Col className="gutter-row" span={8}>
          <X5Logo white />
        </Col>
        <Col className="gutter-row" span={4}>
          <Menu>
            <Menu.ItemGroup key="g1" title="Go-to">
              <Menu.Item key="1">Products</Menu.Item>
              <Menu.Item key="2">Join</Menu.Item>
              <Menu.Item key="3">Policy</Menu.Item>
              <Menu.Item key="4">Team</Menu.Item>
            </Menu.ItemGroup>
          </Menu>
        </Col>
        <Col className="gutter-row" span={4}>
          <Menu>
            <Menu.ItemGroup key="g1" title="Products">
              <Menu.Item key="1">Recommend</Menu.Item>
              <Menu.Item key="2">Analytics</Menu.Item>
              <Menu.Item key="2">Dicovery</Menu.Item>
              <Menu.Item key="2">Translate</Menu.Item>
              <Menu.Item key="2">Connect</Menu.Item>
              <Menu.Item key="2">Feed</Menu.Item>
            </Menu.ItemGroup>
          </Menu>
        </Col>
        <Col className="gutter-row" span={4}>
          <Menu>
            <Menu.ItemGroup key="g1" title="Contact">
              <Menu.Item key="1">General Enquiries</Menu.Item>
              <Menu.Item key="2">
                Partner Projects and Industrial Relations
              </Menu.Item>
              <Menu.Item key="2">Project Coordination</Menu.Item>
              <Menu.Item key="2">Press Enquiries</Menu.Item>
            </Menu.ItemGroup>
          </Menu>
        </Col>
        <Col className="gutter-row" span={4}>
          <Menu>
            <Menu.ItemGroup key="g1" title="Support">
              <Menu.Item key="1">Cookies</Menu.Item>
              <Menu.Item key="2">Documentation</Menu.Item>
              <Menu.Item key="2">Privacy &amp; Terms</Menu.Item>
            </Menu.ItemGroup>
          </Menu>
        </Col>
      </Row>
    </Footer>
  );
};
