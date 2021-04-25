import { DeleteOutlined } from '@ant-design/icons';
import { unwrapResult } from '@reduxjs/toolkit';
import { Button, Popconfirm } from 'antd';
import { deleteTempPlaylistThunk } from 'app/containers/Layout/ducks/myPlaylistMenu/deleteTempPlaylist';
import React from 'react';
import { useDispatch } from 'react-redux';
import { useHistory } from 'react-router';

export function PlaylistDeleteButton(props) {
  const { playlistName } = props;
  const [visible, setVisible] = React.useState(false);
  const [confirmLoading, setConfirmLoading] = React.useState(false);
  const [title, setTitle] = React.useState('Confirm Delete');
  const dispatch = useDispatch();
  const history = useHistory()

  const showPopconfirm = () => {
    setVisible(true);
  };

  const handleOk = async () => {
    setConfirmLoading(true);

    try {
      const delData = (await dispatch(
        deleteTempPlaylistThunk(playlistName),
      )) as any;

      const result = await unwrapResult(delData);
    } catch (e) {
      setTitle('Something went wrong...');
      setConfirmLoading(false);

      return;
    }
    history.push('/')
    setTitle('Confirm Delete');
    setVisible(false);
    setConfirmLoading(false);

  };

  const handleCancel = () => {

    setVisible(false);
  };

  return (
    <Popconfirm
      title={title}
      visible={visible}
      onConfirm={handleOk}
      okButtonProps={{ loading: confirmLoading }}
      onCancel={handleCancel}
    >
      <Button type="link" htmlType="button" onClick={showPopconfirm}>
        Delete <DeleteOutlined />
      </Button>
    </Popconfirm>
  );
}
