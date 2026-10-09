import React from 'react';
import { message } from 'antd';
import { act, fireEvent, render, waitFor } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { HelmetProvider } from 'react-helmet-async';
import { useDispatch, useSelector } from 'react-redux';
import axios from 'axios';
import ReactPlayer from 'react-player';
import { ActionTypes, logAction } from 'app/api/actionLogging';
import { ResourcesPage } from './ResourcesPage';
import { PlaylistsPage } from './PlaylistsPage';
import { ROUTES } from 'routes/routes';

jest.mock('react-redux', () => ({
  useDispatch: jest.fn(),
  useSelector: jest.fn(),
}));
jest.mock('redux-injectors', () => ({ useInjectReducer: jest.fn() }));
jest.mock('react-i18next', () => ({
  useTranslation: () => ({ t: key => key }),
}));
jest.mock('axios', () => ({ get: jest.fn() }));
jest.mock('app/api/actionLogging', () => ({
  ...jest.requireActual('app/api/actionLogging'),
  logAction: jest.fn(),
}));
jest.mock('app/containers/Layout/AppLayout', () => ({
  AppLayout: ({ children }) => children,
}));
jest.mock('app/components/NotesWidget/NotesWidget', () => ({
  NotesWidget: () => null,
}));
jest.mock('app/components/EnrichmentBar/EnrichmentBar', () => ({
  EnrichmentBar: () => null,
}));
jest.mock('./HomePage/components/FeaturedOER/OerCardList', () => ({
  OerCardList: () => null,
}));
jest.mock('app/containers/Layout/ducks/allOERSlice', () => ({
  fetchOERsByIDsThunk: ids => ({ type: 'oers', ids }),
}));
jest.mock('./PlaylistsPage/ducks/fetchPlaylistDetailsThunk', () => ({
  sliceKey: 'playlistDetail',
  reducer: () => ({}),
  fetchPlaylistDetailsThunk: Object.assign(id => ({ type: 'playlist', id }), {
    fulfilled: { match: result => result.type === 'fulfilled' },
  }),
}));
jest.mock('react-player', () => {
  const React = require('react');
  const player = React.forwardRef((props, ref) => {
    React.useImperativeHandle(ref, () => ({
      getCurrentTime: () => 0,
      seekTo: jest.fn(),
    }));
    return React.createElement(
      'button',
      { onClick: props.onPlay },
      'Play video',
    );
  });
  player.canPlay = jest.fn(() => true);
  return { __esModule: true, default: player };
});

const log = logAction as jest.Mock;
const dispatch = jest.fn();
const resource = {
  id: 12,
  title: 'Video',
  url: 'https://www.youtube.com/watch?v=test',
  mediatype: 'video',
  description: '',
  images: [],
  translations: null,
};

beforeEach(() => {
  jest.clearAllMocks();
  jest.spyOn(console, 'log').mockImplementation(() => {});
  jest.spyOn(console, 'error').mockImplementation(() => {});
  jest.spyOn(console, 'warn').mockImplementation(() => {});
  jest.spyOn(message, 'success').mockImplementation(jest.fn());
  jest.spyOn(message, 'error').mockImplementation(jest.fn());
  (useDispatch as jest.Mock).mockReturnValue(dispatch);
  (useSelector as jest.Mock).mockReturnValue({
    data: { id: 7, title: 'Playlist', oerIds: [] },
    loading: false,
    error: null,
  });
  dispatch.mockImplementation(async action => ({
    type: 'fulfilled',
    payload: action.type === 'oers' ? [resource] : {},
  }));
  (axios.get as jest.Mock).mockResolvedValue({
    data: { title: 'Playlist', oerIds: [11, 12, 13] },
  });
  (ReactPlayer.canPlay as jest.Mock).mockReturnValue(true);
  Object.defineProperty(window, 'matchMedia', {
    writable: true,
    value: jest.fn().mockImplementation(() => ({
      matches: false,
      addListener: jest.fn(),
      removeListener: jest.fn(),
    })),
  });
});

afterEach(() => jest.restoreAllMocks());

function renderResource(search = '?playlist=7') {
  const history = { push: jest.fn() };
  const result = render(
    <HelmetProvider>
      <MemoryRouter initialEntries={[`${ROUTES.RESOURCES}/12${search}`]}>
        <ResourcesPage match={{ params: { id: '12' } }} history={history} />
      </MemoryRouter>
    </HelmetProvider>,
  );
  return { ...result, history };
}

it('logs direct resource opens and next/previous item IDs with playlist context', async () => {
  const view = renderResource();
  await waitFor(() =>
    expect(view.getByRole('button', { name: /Next/ })).toBeEnabled(),
  );
  expect(log).toHaveBeenCalledWith(ActionTypes.OER_OPENED, {
    oer_id: 12,
    playlist_type: 'published',
    playlist_id: 7,
  });
  expect(
    log.mock.calls.filter(([type]) => type === ActionTypes.OER_OPENED),
  ).toHaveLength(1);
  fireEvent.click(view.getByRole('button', { name: /Next/ }));
  expect(log).toHaveBeenCalledWith(ActionTypes.PLAYLIST_ITEM_SKIPPED, {
    oer_id: 12,
    playlist_type: 'published',
    playlist_id: 7,
    from: 12,
    to: 13,
  });
  expect(view.history.push).toHaveBeenLastCalledWith(
    `${ROUTES.RESOURCES}/13?playlist=7`,
  );
  fireEvent.click(view.getByRole('button', { name: /Previous/ }));
  expect(log).toHaveBeenCalledWith(ActionTypes.PLAYLIST_ITEM_PREVIOUS, {
    oer_id: 12,
    playlist_type: 'published',
    playlist_id: 7,
    from: 12,
    to: 11,
  });
  fireEvent.click(view.getByRole('button', { name: 'Play video' }));
  expect(log).toHaveBeenCalledWith(ActionTypes.VIDEO_PLAYED, {
    oer_id: 12,
    playlist_type: 'published',
    playlist_id: 7,
    time: 0,
  });
});

it('records native video play, pause and exact seek endpoints', async () => {
  (ReactPlayer.canPlay as jest.Mock).mockReturnValue(false);
  const view = renderResource('');
  await waitFor(() =>
    expect(view.container.querySelector('video')).not.toBeNull(),
  );
  const video = view.container.querySelector('video')!;
  fireEvent.play(video);
  video.currentTime = 5;
  fireEvent.timeUpdate(video);
  fireEvent.pause(video);
  fireEvent.seeking(video);
  video.currentTime = 40;
  fireEvent.timeUpdate(video);
  fireEvent.seeked(video);
  expect(log).toHaveBeenCalledWith(ActionTypes.VIDEO_PAUSED, {
    oer_id: 12,
    time: 5,
  });
  expect(log).toHaveBeenCalledWith(ActionTypes.VIDEO_SEEKED, {
    oer_id: 12,
    from: 5,
    to: 40,
  });
});

it('preserves temporary playlist context and URL encoding when navigating', async () => {
  (axios.get as jest.Mock).mockResolvedValue({
    data: {
      playlist: { title: 'My list' },
      playlist_items: [{ oer_id: 12 }, { oer_id: 13 }],
    },
  });
  const view = renderResource('?mode=temp_playlist&title=My%20list');
  await waitFor(() =>
    expect(view.getByRole('button', { name: /Next/ })).toBeEnabled(),
  );
  fireEvent.click(view.getByRole('button', { name: /Next/ }));
  expect(log).toHaveBeenCalledWith(ActionTypes.PLAYLIST_ITEM_SKIPPED, {
    oer_id: 12,
    playlist_type: 'temporary',
    temp_title: 'My list',
    from: 12,
    to: 13,
  });
  expect(view.history.push).toHaveBeenLastCalledWith(
    `${ROUTES.RESOURCES}/13?mode=temp_playlist&title=My%20list`,
  );
  expect(view.getByRole('button', { name: /Previous/ })).toBeDisabled();
});

function renderPlaylist() {
  return render(
    <HelmetProvider>
      <PlaylistsPage match={{ params: { id: '7' } }} />
    </HelmetProvider>,
  );
}

it('logs playlist opens and successful clipboard copies', async () => {
  const writeText = jest.fn().mockResolvedValue(undefined);
  Object.defineProperty(navigator, 'clipboard', {
    configurable: true,
    value: { writeText },
  });
  const view = renderPlaylist();
  await waitFor(() =>
    expect(log).toHaveBeenCalledWith(ActionTypes.PLAYLIST_OPENED, {
      playlist_type: 'published',
      playlist_id: 7,
    }),
  );
  fireEvent.click(view.getByRole('button', { name: /Share/ }));
  await waitFor(() =>
    expect(log).toHaveBeenCalledWith(ActionTypes.PLAYLIST_SHARE_LINK_COPIED, {
      playlist_type: 'published',
      playlist_id: 7,
      url: window.location.href,
    }),
  );
  expect(writeText).toHaveBeenCalledWith(window.location.href);
});

it('does not record successful copies when clipboard access fails', async () => {
  const writeText = jest.fn().mockRejectedValue(new Error('Denied'));
  Object.defineProperty(navigator, 'clipboard', {
    configurable: true,
    value: { writeText },
  });
  const view = renderPlaylist();
  await act(async () => {
    fireEvent.click(view.getByRole('button', { name: /Share/ }));
  });
  expect(
    log.mock.calls.some(
      ([type]) => type === ActionTypes.PLAYLIST_SHARE_LINK_COPIED,
    ),
  ).toBe(false);
});
