import React, { useCallback, useEffect } from 'react';
import { Helmet } from 'react-helmet-async';
import { AppLayout } from 'app/containers/Layout/AppLayout';
import { LatestOerList } from './components/FeaturedOER/LatestOerList';
import { RecomendedOerList } from './components/FeaturedOER/RecomendedOerList';
import { ApiFilled } from '@ant-design/icons';
import { fetchFeaturedOERs } from 'app/api/api';

export function HomePage() {
  const oerCallBack = useCallback(async () => {
    const data = await fetchFeaturedOERs();
  },[]);
  useEffect( () => {
    oerCallBack();
  }, [oerCallBack]);
  return (
    <>
      <Helmet>
        <title>Home Page</title>
        <meta name="description" content="X5 Learn AI based learning" />
      </Helmet>
      <AppLayout>
        <RecomendedOerList />
        <LatestOerList />
      </AppLayout>
    </>
  );
}
