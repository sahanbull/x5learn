import { unwrapResult } from '@reduxjs/toolkit';
import {
  fetchOerEnrichmentThunk,
  selectOerEnrichment,
  sliceKey,
} from 'app/containers/Layout/ducks/oerEnrichmentSlice';
import { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { Progress } from 'antd';

import styled from 'styled-components/macro';

export const EnrichmentBar = function (props: { oerID }) {
  const dispatch = useDispatch();

  // const loading = useSelector(state => {
  //   const oerData = state[sliceKey][props.oerID]
  //   return oerData && oerData.loading;
  // });
  // const error = useSelector(state => {
  //   const oerData = state[sliceKey][props.oerID]
  //   return oerData && oerData.error;
  // });
  // const searchResult: {
  //   current_page: number;
  //   oers: Array<object>;
  //   total_pages: number;
  // } = useSelector(state => {
  //   const oerData = state[sliceKey][props.oerID]
  //   return oerData && oerData.data;
  // });

  const { data, loading, error } = useSelector(state => {
    return selectOerEnrichment(state, props.oerID);
  });

  const fetchEnrichment = async () => {
    const response = (await dispatch(
      fetchOerEnrichmentThunk(props.oerID),
    )) as any;
    const result = await unwrapResult(response);
    console.log(result);
  };
  useEffect(() => {
    fetchEnrichment();
  }, [props.oerID]);
  return (
    <div>
      {loading && <Progress percent={100} status="active" showInfo={false} />}
      {data && (
        <>
          Chunks Loaded - {data.chunks.length} <br />
          Clusters Loaded - {data.clusters.length} <br />
          Mentions Loaded - {Object.keys(data.mentions).length} <br />
        </>
      )}
    </div>
  );
};
