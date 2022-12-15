import React from 'react';
import { OerCardList } from './OerCardList';
import { useTranslation } from 'react-i18next';
import { fetchFeaturedOer, sliceKey } from '../../ducks/featuredOerSlice';

import { Col, Row, Typography, Popover } from 'antd';
import { useSelector } from 'react-redux';
import { OerCard } from './OerCard';
import { selectUnveilAi } from 'app/containers/Header/HeaderSlice';

const { Title } = Typography;

export function RecomendedOerList() {
  const { t } = useTranslation();
  const unveilAi = useSelector(selectUnveilAi);

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
      {unveilAi ? (
        <Popover
          title=""
          content={
            <div style={{ maxWidth: '400px' }}>
              <p>
                By joining forces and connecting your OER site to all existing
                OER sites into the first Global OER Network, we can together
                unleash the equity potential of OER and start the first data
                driven effort capable of understanding and recommending OERs
                across different sites,languages, modalities such as video,
                documents and textbooks.
              </p>
              <a href="http://x5learn.org" target="blank">
                Try it yourself
              </a>
            </div>
          }
          trigger="hover"
        >
          <Title
            style={{ border: '2px solid red', width: 'fit-content' }}
            level={4}
          >
            {t('oer.recommended', 'Recommended for You')}
          </Title>
        </Popover>
      ) : (
        <Title level={4}>{t('oer.recommended', 'Recommended for You')}</Title>
      )}
      <OerCardList loading={loading} error={error} data={featuredData} />
    </div>
  );
}
