import { unwrapResult } from '@reduxjs/toolkit';
import {
  fetchOerEnrichmentThunk,
  selectOerEnrichment,
  sliceKey,
} from 'app/containers/Layout/ducks/oerEnrichmentSlice';
import { useEffect, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { Collapse, Popover, Progress } from 'antd';
import { Menu, Dropdown } from 'antd';
import { EntityDefinitionMenuItem } from './EntityDefinitionMenuItem';
import { ReactComponent as NotesSVG } from 'app/containers/ContentPage/assets/notes.svg';
import styled from 'styled-components/macro';
import { X5MenuTitle } from 'app/containers/SideBar/X5MenuTitle';
import { fetchEntityDefinitionsByIDsThunk } from 'app/containers/Layout/ducks/allEntityDefinitionsSlice';
const { SubMenu } = Menu;
const { Panel } = Collapse;

function expandIcon(props) {
  debugger;
  return <NotesSVG />;
}

const StyledChunks = styled.div`
  display: flex;
`;

const StyledChunk = styled(({ chunk, style, className, ...props }) => {
  const menu = (
    <Menu mode="inline">
      {chunk.entities.map(entity => {
        return (
          <SubMenu
            key={entity.title}
            // title={<X5MenuTitle icon={<></>}>{entity.title}</X5MenuTitle>}
            title={<>{entity.title}</>}
          >
            <EntityDefinitionMenuItem entity={entity} />
          </SubMenu>
        );
      })}
    </Menu>
  );
  const accordion = (
    <Collapse accordion={true}>
      {chunk.entities.map(entity => {
        return (
          <Panel key={entity.title} header={entity.title}>
            <EntityDefinitionMenuItem entity={entity} />
          </Panel>
        );
      })}
    </Collapse>
  );

  const [isHover, setIsHover] = useState(false);
  const dispatch = useDispatch();
  const mouseOverHandler = event => {
    event.preventDefault();
    const entityIds = chunk.entities.map(entity => {
      return entity.id;
    });
    dispatch(fetchEntityDefinitionsByIDsThunk(entityIds));
    setIsHover(true);
  };
  const mouseOutHandler = event => {
    event.preventDefault();
    setIsHover(false);
  };

  return (
    <Dropdown overlay={menu}>
      <div
        // {...props}
        style={style}
        className={className}
        onMouseOver={mouseOverHandler}
        onMouseOut={mouseOutHandler}
      ></div>
    </Dropdown>

    // <Popover content={accordion}>
    //   <div
    //     // {...props}
    //     style={style}
    //     className={className}
    //     onMouseOver={mouseOverHandler}
    //     onMouseOut={mouseOutHandler}
    //     onClick={event => {
    //       event.stopPropagation()
    //       event.preventDefault();
    //     }}
    //   ></div>
    // </Popover>
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
