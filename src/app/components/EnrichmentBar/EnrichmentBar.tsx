import { unwrapResult } from '@reduxjs/toolkit';
import {
  fetchOerEnrichmentThunk,
  selectOerEnrichment,
  sliceKey,
} from 'app/containers/Layout/ducks/oerEnrichmentSlice';
import { useEffect, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { Progress } from 'antd';
import { Menu, Dropdown } from 'antd';

import styled from 'styled-components/macro';
const { SubMenu } = Menu;

const StyledChunks = styled.div`
  display: flex;
`;

const StyledChunk = styled(({ chunk, ...props }) => {
  const menu = (
    <Menu>
      {chunk.entities.map(entity => {
        return (
          <SubMenu key={entity.title} title={entity.title}>
            <Menu.Item>3rd menu item</Menu.Item>

          </SubMenu>
        );
      })}

    </Menu>
  );

  const [isHover, setIsHover] = useState(false);

  const mouseOverHandler = event => {
    setIsHover(true);
  };
  const mouseOutHandler = event => {
    setIsHover(false);
  };

  return (
    <Dropdown {...props} style={{}} overlay={menu}>
      <div
        // style={{  flex: chunk.length  }}
        onMouseOver={mouseOverHandler}
        onMouseOut={mouseOutHandler}
      ></div>
    </Dropdown>
  );
})`
  background-color: red;
  box-shadow: 0 0 0px 2px #969696;
  height: 10px;
  flex: ${props => {
    return props.chunk.length;
  }};

  &:hover {
    background-color: blue;
  }
`;

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
  }, []);

  if (data && data.errors) {
    return <>Error</>;
  }
  return (
    <div>
      {loading && <Progress percent={100} status="active" showInfo={false} />}
      {data && (
        <>
          Chunks Loaded - {data.chunks.length} <br />
          Clusters Loaded - {data.clusters.length} <br />
          Mentions Loaded - {Object.keys(data.mentions).length} <br />
          <StyledChunks className={`chunks`}>
            {data.chunks &&
              data.chunks.map(chunk => {
                return (
                  <StyledChunk
                    key={chunk.start}
                    className="chunk"
                    chunk={chunk}
                  ></StyledChunk>
                );
              })}
          </StyledChunks>
        </>
      )}
    </div>
  );
};
