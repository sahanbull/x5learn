import React, { useCallback, useEffect } from 'react';
import { Helmet } from 'react-helmet-async';
import { AppLayout } from 'app/containers/Layout/AppLayout';
import { LatestOerList } from './components/FeaturedOER/LatestOerList';
import { RecomendedOerList } from './components/FeaturedOER/RecomendedOerList';
import { useInjectReducer } from 'redux-injectors';
import { useDispatch } from 'react-redux';
import { fetchFeaturedOer, sliceKey, reducer } from './ducks/featuredOerSlice';

export function HomePage() {
  useInjectReducer({ key: sliceKey, reducer: reducer });
  const dispatch = useDispatch();

  useEffect(() => {
    dispatch(fetchFeaturedOer());
  }, [dispatch]);
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
