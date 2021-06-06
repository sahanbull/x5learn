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
import { Pagination, Row, Space, Spin } from 'antd';
import {
  fetchSearchOerThunk,
  sliceKey as searchOerSliceKey,
  reducer as oerSearchReducer,
} from './ducks/searchOerSlice';
import { useHistory, useLocation, useParams } from 'react-router-dom';
import { WarningOutlined } from '@ant-design/icons';
import { Typography } from 'antd';
import { ROUTES } from 'routes/routes';
import { useTranslation } from 'react-i18next';

const { Title } = Typography;

function useQuery() {
  return new URLSearchParams(useLocation().search);
}

export function SearchPage() {
  useInjectReducer({ key: searchOerSliceKey, reducer: oerSearchReducer });
  const dispatch = useDispatch();
  const history = useHistory();
  const query = useQuery();
  const { t } = useTranslation();

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
        <title>{t('generic.lbl_search')}</title>
      </Helmet>
      <AppLayout>
        {!searchTerm && <>{t('alerts.lbl_search_no_term_found')}</>}
        {isSearching && (
          <>
            <Spin spinning={isSearching} delay={500}></Spin>
            {t('alerts.lbl_searching_for')} {searchTerm}
          </>
        )}
        {isError && (
          <>
            <WarningOutlined /> {t('alerts.lbl_searching_for_error')}{' '}
            {searchTerm}{' '}
          </>
        )}

        {searchTerm && (
          <>
            {searchResult && total_pages === 0 && oers?.length === 0 && (
              <Title level={2} type="secondary">
                {`${t(
                  'alerts.lbl_no_results_were_found_prefix',
                )} ${searchTerm}, ${'alerts.lbl_no_results_were_found_suffix'}`}
              </Title>
            )}
            {searchResult && (
              <Title level={2} type="secondary">
                {total_pages * oers?.length}{' '}
                {t('alerts.lbl_search_result_suffix')}
              </Title>
            )}
            <SearchOerList />
            <br />
            {searchResult && (
              <Row justify="center">
                <Pagination
                  defaultCurrent={+page}
                  total={total_pages}
                  showSizeChanger={false}
                  onChange={page => {
                    query.set('page', `${page}`);
                    history.push(`${ROUTES.SEARCH}?${query.toString()}`);
                  }}
                />
              </Row>
            )}
          </>
        )}
      </AppLayout>
    </>
  );
}
