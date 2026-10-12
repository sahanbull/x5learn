import { useEffect } from 'react';
import { ActionTypes, logAction } from 'app/api/actionLogging';

function redirectToLogout() {
  window.location.href = '/logout';
}

export function LogoutRedirect({
  redirect = redirectToLogout,
}: {
  redirect?: () => void;
}) {
  useEffect(() => {
    let active = true;
    const finish = () => {
      if (!active) return;
      active = false;
      window.clearTimeout(timeout);
      redirect();
    };
    // Give the authenticated log time to finish without blocking logout offline.
    const timeout = window.setTimeout(finish, 2000);
    Promise.resolve(logAction(ActionTypes.USER_LOGOUT, {})).then(
      finish,
      finish,
    );
    return () => {
      active = false;
      window.clearTimeout(timeout);
    };
  }, [redirect]);
  return null;
}
