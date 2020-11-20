import React from 'react';
import { Card, Skeleton } from 'antd';

export function OerCard(props: { loading?: boolean }) {
  const {loading} = props;
  if (loading) {
    return (
      <Card>
        <Skeleton active></Skeleton>
      </Card>
    );
  }

  return (
    <Card title="Card title" hoverable bordered={false}>
      Card content
    </Card>
  );
}
