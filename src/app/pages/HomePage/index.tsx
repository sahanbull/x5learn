import React from 'react';
import { Helmet } from 'react-helmet-async';
import { AppLayout } from 'app/containers/Layout/AppLayout';
import { LatestOerList } from './components/FeaturedOER/LatestOerList';
import { RecomendedOerList } from './components/FeaturedOER/RecomendedOerList';

export function HomePage() {
  return (
    <>
      <Helmet>
        <title>Home Page</title>
        <meta name="description" content="X5 Learn AI based learning" />
      </Helmet>
      <AppLayout>
        <RecomendedOerList/>
        <LatestOerList/>
      </AppLayout>
    </>
  );
}
