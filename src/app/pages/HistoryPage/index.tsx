import React, { useEffect, useState } from 'react';
import { Helmet } from 'react-helmet-async';
import { AppLayout } from 'app/containers/Layout/AppLayout';
import { useInjectReducer } from 'redux-injectors';
import { useDispatch, useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';
import {
  getUserHistoryThunk,
  sliceKey,
  reducer,
} from './ducks/HistoryPageSlice';
import {
  fetchOERsByIDsThunk,
  sliceKey as oerSliceKey,
  reducer as oerReducer,
} from 'app/containers/Layout/ducks/allOERSlice';
import { OerCardList } from '../HomePage/components/FeaturedOER/OerCardList';
import { Pagination, Row } from 'antd';

const PAGE_LIMIT = 10;

export function HistoryPage() {
  const dispatch = useDispatch();
  const { t } = useTranslation();

  useInjectReducer({
    key: sliceKey,
    reducer: reducer,
  });
  useInjectReducer({
    key: oerSliceKey,
    reducer: oerReducer,
  });

  const historyList = useSelector(state => state[sliceKey].oers);
  const total = useSelector(state => state[sliceKey].total);
  const loading = useSelector(state => state[sliceKey].loading);
  const error = useSelector(state => state[sliceKey].error);
  const currentOffset = useSelector(state => state[sliceKey].currentOffset);
  const allOers = useSelector(state => state[oerSliceKey].data);

  useEffect(() => {
    dispatch(
      getUserHistoryThunk({ sort: 'asc', limit: PAGE_LIMIT, offset: currentOffset }),
    );
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (historyList && historyList.length > 0) {
      const oerIdArray = historyList.map((oer: { oer_id: any }) => oer.oer_id);
      dispatch(fetchOERsByIDsThunk(oerIdArray));
    }
  }, [dispatch, historyList]);

  let historyOerList = [];
  if (historyList && historyList.length > 0) {
    historyOerList = historyList.map(history => {
      if (allOers && allOers[history.oer_id]) {
        return {
          ...allOers[history.oer_id],
          last_accessed: history.last_accessed,
        };
      } else {
        return { ...history, loading: true };
      }
    });
  }
  return (
    <>
      <Helmet>
        <title>x5learn</title>
      </Helmet>
      <AppLayout className="profile-page">
        <div style={{ padding: '25px' }}>
          <h2>History</h2>
          <OerCardList loading={loading} error={error} data={historyOerList} />
        </div>
        <Row justify="center">
          <Pagination
            defaultCurrent={(currentOffset/PAGE_LIMIT) + 1}
            disabled={loading}
            total={total}
            showSizeChanger={false}
            onChange={page => {
              dispatch(
                getUserHistoryThunk({
                  sort: 'asc',
                  limit: PAGE_LIMIT,
                  offset: PAGE_LIMIT * (page - 1),
                }),
              );
            }}
          />
        </Row>
      </AppLayout>
    </>
  );
}
