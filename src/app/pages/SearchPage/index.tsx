import React, { useEffect, useReducer } from 'react';
import { Helmet } from 'react-helmet-async';
import { NavBar } from 'app/containers/NavBar';
import { Masthead } from './Masthead';
import { Features } from './Features';
import { PageWrapper } from 'app/components/PageWrapper';
import { useInjectReducer } from 'redux-injectors';
import { useDispatch, useSelector } from 'react-redux';
import { SearchOerList } from './components/SearchOerList';
import { AppLayout } from 'app/containers/Layout/AppLayout';
import { Pagination, Spin } from 'antd';
import {
  fetchSearchOerThunk,
  sliceKey as searchOerSliceKey,
  reducer as oerSearchReducer,
} from './ducks/searchOerSlice';
import { useHistory, useLocation, useParams } from 'react-router-dom';
import { WarningOutlined } from '@ant-design/icons';
import { Typography } from 'antd';
import { ROUTES } from 'routes/routes';

const { Title } = Typography;

function useQuery() {
  return new URLSearchParams(useLocation().search);
}

export function SearchPage() {
  useInjectReducer({ key: searchOerSliceKey, reducer: oerSearchReducer });
  const dispatch = useDispatch();
  const history = useHistory();
  const query = useQuery();

  const isSearching = useSelector(state => {
    return state[searchOerSliceKey].loading;
  });
  const isError = useSelector(state => {
    return state[searchOerSliceKey].error;
  });
  const searchResult: {
    current_page: number;
    oers: Array<object>;
    total_pages: number;
  } = useSelector(state => {
    return state[searchOerSliceKey].data;
  });

  const { current_page, oers, total_pages } = searchResult || {};

  const searchTerm: string = query.get('q')?.toString() || '';
  const page = query.get('page')?.toString() || '1';

  useEffect(() => {
    const searchParams = {
      searchTerm,
      page,
    };
    dispatch(fetchSearchOerThunk(searchParams));
  }, [dispatch, page, searchTerm]);
  return (
    <>
      <Helmet>
        <title>Home Page</title>
        <meta name="description" content="X5 Learn AI based learning" />
      </Helmet>
      <AppLayout>
        {!searchTerm && <>No Search Term Found</>}
        {isSearching && (
          <>
            <Spin spinning={isSearching} delay={500}></Spin>
            Searching for {searchTerm}
          </>
        )}
        {isError && (
          <>
            <WarningOutlined /> Something went wrong searching for {searchTerm}{' '}
          </>
        )}
        {searchResult && (
          <Title level={2} type="secondary">
            {total_pages * oers.length} Open Educational Resources Found
          </Title>
        )}
        <SearchOerList />
        {searchResult && (
          <Pagination
            defaultCurrent={+page}
            total={total_pages}
            showSizeChanger={false}
            onChange={page => {
              query.set('page', `${page}`);
              history.push(`${ROUTES.SEARCH}?${query.toString()}`);
            }}
          />
        )}
      </AppLayout>
    </>
  );
}
