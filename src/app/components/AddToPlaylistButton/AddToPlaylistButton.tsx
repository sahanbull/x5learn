import { UploadOutlined } from '@ant-design/icons';
import { unwrapResult } from '@reduxjs/toolkit';
import { Button, Dropdown, Menu, message } from 'antd';
import { addToTempPlaylistThunk } from 'app/containers/Layout/ducks/myPlaylistMenu/addToTempPlaylist';
import { useDispatch, useSelector } from 'react-redux';
import { RootState } from 'types';

export function AddToPlaylistButton({ oerId }) {
  const dispatch = useDispatch();
  const { data: tempPlaylists, loading, error } = useSelector(
    (state: RootState) => {
      return state.myPlaylistsMenu;
    },
  );

  const addToPlaylist = async event => {
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

  return (
    <Dropdown overlay={menu} placement="bottomRight">
      <Button
        type="primary"
        shape="round"
        icon={<UploadOutlined />}
        size="large"
      >
        Add to Playlist
      </Button>
    </Dropdown>
  );
}
