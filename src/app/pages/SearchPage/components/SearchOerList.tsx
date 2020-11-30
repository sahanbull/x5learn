import React from 'react';
import { OerCardList } from './../../HomePage/components/FeaturedOER/OerCardList';
import { useTranslation } from 'react-i18next';
import { fetchSearchOerThunk, sliceKey } from '../ducks/searchOerSlice';

import { Col, Row, Typography } from 'antd';
import { useSelector } from 'react-redux';
import { OerCard } from '../../HomePage/components/FeaturedOER/OerCard';

const { Title } = Typography;

export function SearchOerList() {
  const { t } = useTranslation();

  const loading = useSelector(state => {
    return state[sliceKey].loading;
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
