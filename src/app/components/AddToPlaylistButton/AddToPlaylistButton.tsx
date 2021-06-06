import { UploadOutlined } from '@ant-design/icons';
import { unwrapResult } from '@reduxjs/toolkit';
import { Button, Dropdown, Menu, message } from 'antd';
import { SizeType } from 'antd/lib/config-provider/SizeContext';
import { addToTempPlaylistThunk } from 'app/containers/Layout/ducks/myPlaylistMenu/addToTempPlaylist';
import { useTranslation } from 'react-i18next';
import { useDispatch, useSelector } from 'react-redux';

import { RootState } from 'types';

export function AddToPlaylistButton({
  oerId,
  hideLabel = false,
  size = 'large',
}) {
  const dispatch = useDispatch();
  const { t } = useTranslation();
  const { data: tempPlaylists, loading, error } = useSelector(
    (state: RootState) => {
      return state.myPlaylistsMenu;
    },
  );

  const addToPlaylist = async event => {
    event.preventDefault();
    // event.stopImmediatePropagation()
    const playlistName = event.target.getAttribute('data-name');

    try {
      const addedData = (await dispatch(
        addToTempPlaylistThunk({ playlistName, oerId }),
      )) as any;
      const result = unwrapResult(addedData);
      message.success(`Added resource to ${playlistName}`);
    } catch (e) {
      message.error(`Could not add resource to ${playlistName}`);
    }
  };

  const menu = (
    <Menu>
      {tempPlaylists &&
        tempPlaylists.map(playlists => {
          return (
            <Menu.Item key={playlists.title}>
              <a onClick={addToPlaylist} data-name={playlists.title}>
                {playlists.title}
              </a>
            </Menu.Item>
          );
        })}
    </Menu>
  );

  const btnLabel = !hideLabel && t('inspector.btn_add_to_playlist');

  return (
    <Dropdown overlay={menu} placement="bottomRight" trigger={['click']}>
      <Button
        type="primary"
        shape="round"
        icon={<UploadOutlined />}
        size={size as SizeType}
        title={t('inspector.btn_add_to_playlist')}
      >
        {btnLabel}
      </Button>
    </Dropdown>
  );
}
