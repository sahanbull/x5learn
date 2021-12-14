import React, { useEffect, useState } from 'react';
import { Helmet } from 'react-helmet-async';
import { AppLayout } from 'app/containers/Layout/AppLayout';
import { useInjectReducer } from 'redux-injectors';
import { useDispatch, useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';
import {
  getNotesListThunk,
  sliceKey,
  reducer,
} from './ducks/NotesPageSlice';
import {
  fetchOERsByIDsThunk,
  sliceKey as oerSliceKey,
  reducer as oerReducer,
} from 'app/containers/Layout/ducks/allOERSlice';
import { OerCardList } from '../HomePage/components/FeaturedOER/OerCardList';
import { Pagination, Row } from 'antd';
import { Table, Tag, Space } from 'antd';
import { OerSortableView } from '../HomePage/components/FeaturedOER/OerSortableView';

const PAGE_LIMIT = 10;

const columns = [
  {
    title: 'Oer',
    key: 'oer',
    render: (text, record) => (
      <OerSortableView loading={record.loading} card={record} />
    ),
  },
  {
    title: 'Note',
    dataIndex: 'text',
    key: 'text',
  },
  {
    title: 'Last Updated',
    dataIndex: 'last_updated_at',
    key: 'last_updated_at',
  },
];

export function NotesPage() {
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

  const notesList = useSelector(state => state[sliceKey].oers);
  const total = useSelector(state => state[sliceKey].total);
  const loading = useSelector(state => state[sliceKey].loading);
  const error = useSelector(state => state[sliceKey].error);
  const currentOffset = useSelector(state => state[sliceKey].currentOffset);
  const allOers = useSelector(state => state[oerSliceKey].data);

  useEffect(() => {
    dispatch(
      getNotesListThunk({ sort: 'asc', limit: PAGE_LIMIT, offset: currentOffset }),
    );
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (notesList && notesList.length > 0) {
      const oerIdArray = notesList.map((oer: { oer_id: any }) => oer.oer_id);
      dispatch(fetchOERsByIDsThunk(oerIdArray));
    }
  }, [dispatch, notesList]);

  let notesOerList = [];
  if (notesList && notesList.length > 0) {
    notesOerList = notesList.map(note => {
      if (allOers && allOers[note.oer_id]) {
        return {
          ...allOers[note.oer_id],
          ...note,
        };
      } else {
        return { ...note, loading: true };
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
          <h2>Notes</h2>
          <Table columns={columns} dataSource={notesOerList} />
          {/* <OerCardList loading={loading} error={error} data={notesOerList} /> */}
        </div>
        <Row justify="center">
          <Pagination
            defaultCurrent={(currentOffset/PAGE_LIMIT) + 1}
            disabled={loading}
            total={total}
            showSizeChanger={false}
            onChange={page => {
              dispatch(
                getNotesListThunk({
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
