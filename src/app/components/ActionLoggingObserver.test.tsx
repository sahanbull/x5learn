import React from 'react';
import { fireEvent, render } from '@testing-library/react';
import { MemoryRouter, useHistory } from 'react-router-dom';
import { ActionTypes, logAction } from 'app/api/actionLogging';
import { ActionLoggingObserver } from './ActionLoggingObserver';

jest.mock('app/api/actionLogging', () => ({
  ...jest.requireActual('app/api/actionLogging'),
  logAction: jest.fn(),
}));

function Navigation() {
  const history = useHistory();
  return (
    <button onClick={() => history.push('/search?q=brain')}>Search</button>
  );
}

it('records initial URLs and path/query changes once, ignoring unchanged locations', () => {
  const log = logAction as jest.Mock;
  log.mockClear();
  const view = render(
    <MemoryRouter initialEntries={['/create_playlist']}>
      <ActionLoggingObserver />
      <Navigation />
    </MemoryRouter>,
  );
  expect(log).toHaveBeenLastCalledWith(ActionTypes.URL_CHANGED, {
    path: '/create_playlist',
    query: '',
  });
  fireEvent.click(view.getByText('Search'));
  expect(log).toHaveBeenLastCalledWith(ActionTypes.URL_CHANGED, {
    path: '/search',
    query: '?q=brain',
  });
  fireEvent.click(view.getByText('Search'));
  expect(log).toHaveBeenCalledTimes(2);
});
