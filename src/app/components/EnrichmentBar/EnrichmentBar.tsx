import { unwrapResult } from '@reduxjs/toolkit';
import {
  fetchOerEnrichmentThunk,
  selectOerEnrichment,
  sliceKey,
} from 'app/containers/Layout/ducks/oerEnrichmentSlice';
import { useEffect, useRef, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { Collapse, Popover, Progress } from 'antd';
import { Menu, Dropdown } from 'antd';
import { EntityDefinitionMenuItem } from './EntityDefinitionMenuItem';
import { ReactComponent as NotesSVG } from 'app/containers/ContentPage/assets/notes.svg';
import styled from 'styled-components/macro';
import { X5MenuTitle } from 'app/containers/SideBar/X5MenuTitle';
import { fetchEntityDefinitionsByIDsThunk } from 'app/containers/Layout/ducks/allEntityDefinitionsSlice';
import { OerCard } from 'app/pages/HomePage/components/FeaturedOER/OerCard';
import { NodeIndexOutlined } from '@ant-design/icons';
const { SubMenu } = Menu;
const { Panel } = Collapse;

const barHeight = 12;
const toHHMMSS = function (seconds) {
  if (seconds < 0) {
    seconds = 0;
  }
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = Math.round(seconds % 60);
  return [h, m > 9 ? m : h ? '0' + m : m || '0', s > 9 ? s : '0' + s]
    .filter(Boolean)
    .join(':');
};

function expandIcon(props) {
  debugger;
  return <NotesSVG />;
}

const StyledChunks = styled.div`
  display: flex;
`;

const StyledChunk = styled(
  ({
    chunk,
    style,
    className,
    onMouseOver,
    onMouseMove,
    onMouseOut,
    onMouseDown,
    onMouseUp,
    ...props
  }) => {
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
      if (onMouseOver) {
        onMouseOver(event);
      }
      event.preventDefault();
      const entityIds = chunk.entities.map(entity => {
        return entity.id;
      });
      dispatch(fetchEntityDefinitionsByIDsThunk(entityIds));
      setIsHover(true);
    };
    const mouseOutHandler = event => {
      if (onMouseOut) {
        onMouseOut(event);
      }
      event.preventDefault();
      setIsHover(false);
    };
    const mouseMoveHandler = event => {
      if (onMouseMove) {
        onMouseMove(event);
      }
      event.preventDefault();
    };

    const mouseDownHandler = event => {
      if (onMouseDown) {
        onMouseDown(event);
      }
      event.preventDefault();
    };
    const mouseUpHandler = event => {
      if (onMouseUp) {
        onMouseUp(event);
      }
    };

    return (
      <Dropdown overlay={menu}>
        <div
          // {...props}
          style={style}
          className={className}
          onMouseOver={mouseOverHandler}
          onMouseOut={mouseOutHandler}
          onMouseMove={mouseMoveHandler}
          onMouseDown={mouseDownHandler}
          onMouseUp={mouseUpHandler}
          data-chunkIndex={props.dataChunkIndex}
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
  },
)`
  background-color: #ffffff;
  border: solid 2px #999fb2;
  height: ${barHeight}px;
  flex: ${props => {
    return props.chunk.length;
  }};

  &:hover {
    background-color: #bec1ce;
  }
`;

function Throbber({ length }) {
  const [isTooltipShown, setIsTooltipShown] = useState(false);
  const [tooltipText, setTooltipText] = useState('Tool');
  const [tooltipX, setTooltipX] = useState(0);
  const tooltipRef = useRef(null);
  const onMouseMove = event => {
    if (isTooltipShown) {
      const rect = event.target.getBoundingClientRect();
      const toolTipRect = (tooltipRef.current as any).getBoundingClientRect();

      let x = event.clientX - rect.left - toolTipRect.width / 2;
      let pos = event.clientX - rect.left;
      const duration = toHHMMSS((pos / rect.width) * length);
      // if (rect.width > x ) {
      //   x = event.clientX - rect.left - toolTipRect.width;
      // }
      setTooltipText(`${duration}`);
      setTooltipX(x);
    }
  };
  const onMouseOver = event => {
    setIsTooltipShown(true);
  };
  const onMouseOut = event => {
    setIsTooltipShown(false);
  };
  return (
    <>
      <div
        onMouseOver={onMouseOver}
        onMouseMove={onMouseMove}
        onMouseOut={onMouseOut}
        style={{
          marginTop: '10px',
          boxShadow: '0 0 0px 2px #969696',
          width: '100%',
          height: '10px',
          backgroundColor: '#d3e6d6',
          position: 'absolute',
        }}
      >
        <span
          style={{
            position: 'absolute',
            backgroundColor: '#d3e6d6',
            top: '-25px',
            whiteSpace: 'nowrap',
            left: `${tooltipX}px`,
          }}
          ref={tooltipRef}
          hidden={!isTooltipShown}
        >
          <span style={{ padding: '0 5px' }}>{tooltipText}</span>
        </span>
      </div>
    </>
  );
}

export const EnrichmentBar = function (props: {
  oerID;
  oer?;
  onPlayLocationChange?;
}) {
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

  const [isTooltipShown, setIsTooltipShown] = useState(false);
  const [tooltipText, setTooltipText] = useState('Tool');
  const [tooltipX, setTooltipX] = useState(0);
  const tooltipRef = useRef(null);
  const onMouseMove = event => {
    if (isTooltipShown) {
      const rect = event.target.parentNode.getBoundingClientRect();
      const chunkIndex = +event.target.getAttribute('data-chunkindex');

      const toolTipRect = (tooltipRef.current as any).getBoundingClientRect();

      let x = event.clientX - rect.left - toolTipRect.width / 2;
      let pos = event.clientX - rect.left;
      const duration = toHHMMSS(
        (pos / rect.width) * props.oer?.durationInSeconds,
      );
      // if (rect.width > x ) {
      //   x = event.clientX - rect.left - toolTipRect.width;
      // }
      setTooltipText(`${duration}`);
      setTooltipX(x);
    }
  };
  const onMouseOver = event => {
    if (props.oer?.duration) {
      setIsTooltipShown(true);
    }
  };
  const onMouseOut = event => {
    setIsTooltipShown(false);
  };
  const onMouseDown = event => {
    // debugger
  };
  const onMouseUp = event => {
    if (isTooltipShown) {
      const rect = event.target.parentNode.getBoundingClientRect();

      let posInSec = event.clientX - rect.left;
      posInSec = (posInSec / rect.width) * props.oer?.durationInSeconds;
      const duration = toHHMMSS(posInSec);
      // if (rect.width > x ) {
      //   x = event.clientX - rect.left - toolTipRect.width;
      // }
      props.onPlayLocationChange({ posInSec, duration });
    }
  };

  if (data && data.errors) {
    return (
      <StyledChunks
        className={`chunks`}
        style={{ background: '#d9363e24', height: `${barHeight}px` }}
      ></StyledChunks>
    );
  }
  return (
    <div>
      {loading && (
        <Progress
          percent={100}
          status="active"
          showInfo={false}
          style={{ height: `${barHeight}px` }}
        />
      )}
      {data && (
        <>
          <div style={{ position: 'relative' }}>
            <StyledChunks className={`chunks`}>
              {data.chunks &&
                data.chunks.map((chunk, index) => {
                  return (
                    <StyledChunk
                      key={chunk.start}
                      className="chunk"
                      chunk={chunk}
                      dataChunkIndex={index}
                      onMouseOver={onMouseOver}
                      onMouseMove={onMouseMove}
                      onMouseOut={onMouseOut}
                      onMouseDown={onMouseDown}
                      onMouseUp={onMouseUp}
                    ></StyledChunk>
                  );
                })}
            </StyledChunks>
            <span
              style={{
                position: 'absolute',
                backgroundColor: '#ffffff',
                top: '-25px',
                whiteSpace: 'nowrap',
                left: `${tooltipX}px`,
              }}
              ref={tooltipRef}
              hidden={!isTooltipShown}
            >
              <span style={{ padding: '0 5px' }}>{tooltipText}</span>
            </span>
            {/* <Throbber length={props.oer?.durationInSeconds} /> */}
          </div>
        </>
      )}
    </div>
  );
};
