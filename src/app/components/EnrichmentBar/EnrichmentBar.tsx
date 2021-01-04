import { unwrapResult } from '@reduxjs/toolkit';
import { fetchOerEnrichmentThunk } from 'app/containers/Layout/ducks/oerEnrichmentSlice';
import { useEffect } from 'react';
import { useDispatch } from 'react-redux';
import styled from 'styled-components/macro';

export const EnrichmentBar = function (props: { oerID }) {
  const dispatch = useDispatch();
  const fetchEnrichment = async () => {
    const response = (await dispatch(
      fetchOerEnrichmentThunk(props.oerID),
    )) as any;
    const result = await unwrapResult(response);
    debugger;
    console.log(result);
  };
  useEffect(() => {
    fetchEnrichment();
  });
  return <div>React OER ID = {props.oerID}</div>;
};
