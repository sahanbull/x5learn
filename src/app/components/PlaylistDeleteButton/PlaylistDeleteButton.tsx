import { DeleteOutlined } from '@ant-design/icons';
import { unwrapResult } from '@reduxjs/toolkit';
import { Button, Popconfirm } from 'antd';
import { deleteTempPlaylistThunk } from 'app/containers/Layout/ducks/myPlaylistMenu/deleteTempPlaylist';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { useDispatch } from 'react-redux';
import { useHistory } from 'react-router';

export function PlaylistDeleteButton(props) {
  const { playlistName } = props;
  const [visible, setVisible] = React.useState(false);
  const [confirmLoading, setConfirmLoading] = React.useState(false);
  const [title, setTitle] = React.useState('Confirm Delete');
  const dispatch = useDispatch();
  const history = useHistory();
  const { t } = useTranslation();

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
    history.push('/');
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
        {t('playlist.btn_delete')} <DeleteOutlined />
      </Button>
    </Popconfirm>
  );
}
