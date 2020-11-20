import React from 'react';
import { OerCardList } from './OerCardList';
import { useTranslation } from 'react-i18next';
import { fetchFeaturedOer, sliceKey } from '../../ducks/featuredOerSlice';

import { Col, Row, Typography } from 'antd';
import { useSelector } from 'react-redux';
import { OerCard } from './OerCard';

const { Title } = Typography;

export function RecomendedOerList() {
  const { t } = useTranslation();

  const loading = useSelector(state => {
    return state[sliceKey].isLoading;
  });
  const error = useSelector(state => {
    return state[sliceKey].error;
  });
  const featuredData = useSelector(state => {
    return state[sliceKey].data;
  });

  return (
    <div>
      <Title level={4}>{t('oer.recommended', 'Recommended for You')}</Title>
      <OerCardList loading={loading} error={error} data={featuredData} />
    </div>
  );
}
