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
  const searchResult: {
    current_page: number;
    oers: Array<object>;
    total_pages: number;
  } = useSelector(state => {
    return state[sliceKey].data;
  });

  const { current_page, oers, total_pages } = searchResult || {};

  return (
    <div>
      <Title level={4}>{t('oer.search_result', 'Search Result')}</Title>
      <OerCardList loading={loading} error={error} data={oers} />
    </div>
  );
}
