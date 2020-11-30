import React, { useEffect, useReducer } from 'react';
import { Helmet } from 'react-helmet-async';
import { NavBar } from 'app/containers/NavBar';
import { Masthead } from './Masthead';
import { Features } from './Features';
import { PageWrapper } from 'app/components/PageWrapper';
import { useInjectReducer } from 'redux-injectors';
import { useDispatch } from 'react-redux';
import { SearchOerList } from './components/SearchOerList';
import { AppLayout } from 'app/containers/Layout/AppLayout';
import {fetchSearchOerThunk, sliceKey as searchOerSliceKey, reducer as oerSearchReducer } from 'app/pages/SearchPage/ducks/searchOerSlice'
import { useParams } from 'react-router-dom';
 
export function SearchPage() {
  useInjectReducer({ key: searchOerSliceKey, reducer: oerSearchReducer });
  const dispatch = useDispatch();
  const router = useParams()

  useEffect(() => {
    const searchParams = {
      searchTerm:"query to search",
      page:1
    }
    dispatch(fetchSearchOerThunk(searchParams))
  }, [dispatch]);
  return (
    <>
      <Helmet>
        <title>Home Page</title>
        <meta name="description" content="X5 Learn AI based learning" />
      </Helmet>
      <AppLayout>
        <SearchOerList />
      </AppLayout>
    </>
  );
}
