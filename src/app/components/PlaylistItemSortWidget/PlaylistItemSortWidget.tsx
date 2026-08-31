import { ArrowsAltOutlined, DeleteOutlined, DragOutlined } from '@ant-design/icons';
import { unwrapResult } from '@reduxjs/toolkit';
import { Button, Table, Typography } from 'antd';
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
import { Modal , Input} from 'antd';
import axios from 'axios';


const { TextArea } = Input;
const DragHandle = SortableHandle(() => (
  <DragOutlined style={{ cursor: 'grab', color: '#1DA57A', fontSize: '30px' }} />
));

export const selectAllOers = state => state.allOERs.data;

export const selectOerByID = createSelector(
  [selectAllOers, (_, oerId) => oerId],
  (oers, oerId) => {
    return oers && oers[oerId];
  },
);

const SortableOerCard = ({ oerId, tempPlaylistName, onClick }) => {
  const cardData = useSelector((state: RootState) => {
    return selectOerByID(state, oerId);
  });

  const loading = useSelector((state: RootState) => {
    return state.allOERs.loading;
  });

  return (
    <OerSortableView
      loading={loading}
      card={cardData}
      tempPlaylistName={tempPlaylistName} 
      onClick={() => onClick && onClick(oerId)} // call with oerId or other data
    />
  );
};

const SortableItem = SortableElement(props => <tr {...props} />);
const SortableContainer2 = SortableContainer(props => <tbody {...props} />);

export function PlaylistItemSortWidget({
  playlist_items,
  onItemsReorder,
  isUpdating,
  tempPlaylistName,
  onItemClick,
}) {
  const dispatch = useDispatch();
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [selectedOerId, setSelectedOerId] = useState(null);
  const [modalData, setModalData] = useState({ title: '', description: '' });
  const [modalLoading, setModalLoading] = useState(false);
  const allOers = useSelector(selectAllOers);
  const [{ data, loading, error }, setOERData] = useState<{
    data: any;
    loading: boolean;
    error: any;
  }>({
    data: null,
    loading: true,
    error: null,
  });

  const loadOERIds = async () => {
    setOERData({ data: null, loading: true, error: null });
    const oerIdArray = playlist_items.map(item => item.data);
    try {
      const oerResult = (await dispatch(fetchOERsByIDsThunk(oerIdArray))) as any;
      const resolvedData = await unwrapResult(oerResult);
      setOERData({ data: resolvedData, loading: false, error: null });
    } catch (e) {
      setOERData({ data: null, loading: false, error: e });
    }
  };

  // Reload OER data when playlist_items changes
  useEffect(() => {
    if (playlist_items) {
      loadOERIds();
    }
  }, [playlist_items]);

  // Keep local state synced with props
  const [playlistItems, setPlaylistItems] = useState(playlist_items);
 ;

  useEffect(() => {
    if (playlist_items) {
      setPlaylistItems(playlist_items);
      console.log('Playlist items updated:', playlist_items);
    }
  }, [playlist_items]);

  const onSortEnd = ({ oldIndex, newIndex }) => {
    if (oldIndex !== newIndex) {
      const newData = arrayMove([...playlistItems], oldIndex, newIndex).filter(Boolean);

      // Update local state so UI reflects new order immediately
      setPlaylistItems(newData);

      if (onItemsReorder) {
        onItemsReorder(newData);
      }
    }
  };

  const onOERDelete = oerId => {
    const newData = playlistItems.filter(el => el.oer_id !== oerId);

    setPlaylistItems(newData);

    if (onItemsReorder) {
      onItemsReorder(newData);
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
    // Find the index for sortable element by matching unique 'order' field
    const index = playlistItems.findIndex(
      x => x.order === restProps['data-row-key'],
    );
    return <SortableItem index={index} {...restProps} />;
  };

  
  const showModal = (oerId) => {
    setSelectedOerId(oerId);
    const oer = allOers[oerId];

    if (oer) {
      setModalData({
        title: oer.title || '',
        description: oer.description || '',
      });
    } else {
      setModalData({ title: '', description: '' });
    }

    setIsModalVisible(true);
  };






const handleOk = async () => {
    if (!selectedOerId) return;

    setModalLoading(true);

    try {
      const playlistName = tempPlaylistName;
      const oerId = selectedOerId;

      const url = `${process.env.REACT_APP_BASE_URL}/playlist/${encodeURIComponent(playlistName)}/yt_items/${encodeURIComponent(oerId)}`;

      const payload = {
        title: modalData.title,
        description: modalData.description,
      };

      const response = await axios.put(url, payload, {
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
        },
        withCredentials: true, 
      });

      console.log(`OER ${oerId} updated successfully`, response.data);

      setIsModalVisible(false);

    } catch (err) {
      console.error('Failed to update OER', err);
    } finally {
      setModalLoading(false);
    }
  };






 

  const handleCancel = () => {
    setIsModalVisible(false);
  };

  const columns = [
    {
      title: 'Name',
      dataIndex: 'data',
      className: 'drag-visible',
      render: oerId => (
        <SortableOerCard oerId={oerId} tempPlaylistName={tempPlaylistName} onClick={onItemClick} />
      ),
    },
    {
      title: 'Sort',
      dataIndex: 'order',
      className: 'drag-visible',
      render: () => (!isUpdating ? <DragHandle /> : null),
    },
    {
      title: 'Delete',
      dataIndex: 'data',
      width: 100,
      className: 'drag-visible',
      render: oerId => (
        <Button
          type="link"
          onClick={() => onOERDelete(oerId)}
          loading={isUpdating}
          icon={<DeleteOutlined style={{ fontSize: '28px' }} />}
        />
      ),
    },
    {
      title: 'Edit',
      dataIndex: 'data',
      render: (oerId) => (
        <Button type="primary" onClick={() => showModal(oerId)}>
          Edit
        </Button>
      ),
    },
  ];

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

     <Modal
        title="Edit OER"
        visible={isModalVisible}
        onOk={handleOk}
        onCancel={handleCancel}
        confirmLoading={modalLoading}
      >
        <Input
          value={modalData.title}
          onChange={(e) => setModalData({ ...modalData, title: e.target.value })}
          placeholder="Title"
          style={{ marginBottom: '1rem' }}
        />
        <TextArea
          value={modalData.description}
          onChange={(e) => setModalData({ ...modalData, description: e.target.value })}
          placeholder="Description"
          autoSize={{ minRows: 3 }}
        />
    </Modal>
    </>
  );
}