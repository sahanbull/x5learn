import React from 'react';
import { act, render } from '@testing-library/react';
import { ActionTypes, logAction } from 'app/api/actionLogging';
import { LogoutRedirect } from './LogoutRedirect';

jest.mock('app/api/actionLogging', () => ({
  ...jest.requireActual('app/api/actionLogging'),
  logAction: jest.fn(),
}));

beforeEach(() => {
  jest.clearAllMocks();
  jest.useFakeTimers();
});
afterEach(() => jest.useRealTimers());

it('finishes the authenticated logout log before redirecting', async () => {
  let resolve: () => void = () => {};
  (logAction as jest.Mock).mockReturnValue(
    new Promise<void>(done => {
      resolve = done;
    }),
  );
  const redirect = jest.fn();
  render(<LogoutRedirect redirect={redirect} />);
  expect(logAction).toHaveBeenCalledWith(ActionTypes.USER_LOGOUT, {});
  expect(redirect).not.toHaveBeenCalled();
  await act(async () => resolve());
  expect(redirect).toHaveBeenCalledTimes(1);
  act(() => {
    jest.advanceTimersByTime(2000);
  });
  expect(redirect).toHaveBeenCalledTimes(1);
});

it('redirects after two seconds if logging does not finish', () => {
  (logAction as jest.Mock).mockReturnValue(new Promise(() => {}));
  const redirect = jest.fn();
  render(<LogoutRedirect redirect={redirect} />);
  act(() => {
    jest.advanceTimersByTime(2000);
  });
  expect(redirect).toHaveBeenCalledTimes(1);
});

it('does not redirect from an unmounted logout page', async () => {
  (logAction as jest.Mock).mockResolvedValue(undefined);
  const redirect = jest.fn();
  const view = render(<LogoutRedirect redirect={redirect} />);
  view.unmount();
  await act(async () => {});
  act(() => {
    jest.advanceTimersByTime(2000);
  });
  expect(redirect).not.toHaveBeenCalled();
});
