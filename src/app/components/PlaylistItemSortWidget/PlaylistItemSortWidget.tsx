import { ArrowsAltOutlined } from '@ant-design/icons';
import { unwrapResult } from '@reduxjs/toolkit';
import { Table, Typography } from 'antd';
import { fetchOERsByIDsThunk } from 'app/containers/Layout/ducks/allOERSlice';
import { updateTempPlaylistThunk } from 'app/containers/Layout/ducks/myPlaylistMenu/updateTempPlaylist';
import { OerCard } from 'app/pages/HomePage/components/FeaturedOER/OerCard';
import { OerSortableView } from 'app/pages/HomePage/components/FeaturedOER/OerSortableView';
import { useEffect, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import {
  SortableContainer,
  SortableElement,
  SortableHandle,
  arrayMove,
} from 'react-sortable-hoc';
import { createSelector } from 'reselect';
import { RootState } from 'types';

const DragHandle = SortableHandle(() => (
  <ArrowsAltOutlined style={{ cursor: 'grab', color: '#999' }} />
));

export const selectAllOers = state => state.allOERs.data;
export const selectOerByID = createSelector(
  [selectAllOers, (_, oerId) => oerId],
  (oers, oerId) => {
    return oers && oers[oerId];
  },
);
const SortableOerCard = ({ oerId }) => {
  const cardData = useSelector((state: RootState) => {
    return selectOerByID(state, oerId);
  });

  const loading = useSelector((state: RootState) => {
    return state.allOERs.loading;
  });
  return <OerSortableView loading={loading} card={cardData} />;
};

const columns = [
  {
    title: 'Name',
    dataIndex: 'data',
    className: 'drag-visible',
    
    render: oerId => {
      return (
        <>
          <SortableOerCard oerId={oerId} />
        </>
      );
    },
  },
  {
    title: 'Sort',
    dataIndex: 'order',
    // width: 20,
    className: 'drag-visible',
    render: () => <DragHandle />,
  },
];

const SortableItem = SortableElement(props => <tr {...props} />);
const SortableContainer2 = SortableContainer(props => <tbody {...props} />);

export function PlaylistItemSortWidget({ playlist_items, onItemsReorder }) {
  const dispatch = useDispatch();
  const [{ data, loading, error }, setOERData] = useState({
    data: null,
    loading: true,
    error: null,
  });
  const loadOERIds = async () => {
    setOERData({ data: null, loading: true, error: null });
    const oerIdArray = playlist_items.map(item => {
      return item.data;
    });
    try {
      const oerResult = (await dispatch(
        fetchOERsByIDsThunk(oerIdArray),
      )) as any;
      const resolvedData = await unwrapResult(oerResult);
      setOERData({ data: resolvedData, loading: false, error: null });
    } catch (e) {
      setOERData({ data: null, loading: false, error: e });
    }
  };

  useEffect(() => {
    if (playlist_items) {
      loadOERIds();
    }
  }, []);

  const [playlistItems, setPlaylistItems] = useState(playlist_items);
  const onSortEnd = ({ oldIndex, newIndex }) => {
    const dataSource = playlistItems;
    if (oldIndex !== newIndex) {
      const newData = arrayMove(
        [].concat(dataSource),
        oldIndex,
        newIndex,
      ).filter(el => !!el);
      //   console.log('Sorted items: ', newData.push, data);
      if (onItemsReorder) {
        onItemsReorder(newData);
      }
      setPlaylistItems(newData);
    }
  };

  const DraggableContainer = props => (
    <SortableContainer2
      useDragHandle
      disableAutoscroll
      helperClass="row-dragging"
      onSortEnd={onSortEnd}
      {...props}
    />
  );

  const DraggableBodyRow = ({ className, style, ...restProps }) => {
    const dataSource = playlistItems;
    // function findIndex base on Table rowKey props and should always be a right array index
    const index = dataSource.findIndex(
      x => x.order === restProps['data-row-key'],
    );
    return <SortableItem index={index} {...restProps} />;
  };
  return (
    <>
      <Table
        pagination={false}
        dataSource={playlistItems}
        columns={columns}
        rowKey="order"
        components={{
          body: {
            wrapper: DraggableContainer,
            row: DraggableBodyRow,
          },
        }}
      />
    </>
  );
}
