import React from 'react';
import { OerCardList } from './OerCardList';
import { useTranslation } from 'react-i18next';

import { Typography } from 'antd';

const { Title } = Typography;

export function RecomendedOerList() {
  const { t } = useTranslation();

  return (
    <div>
      <Title level={4}>{t('oer.recommended', 'Recommended for You')}</Title>
      <OerCardList />
    </div>
  );
}
