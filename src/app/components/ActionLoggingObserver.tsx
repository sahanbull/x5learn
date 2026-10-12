import { useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import { ActionTypes, logAction } from 'app/api/actionLogging';

export function ActionLoggingObserver() {
  const { pathname, search } = useLocation();
  useEffect(() => {
    void logAction(ActionTypes.URL_CHANGED, { path: pathname, query: search });
  }, [pathname, search]);
  return null;
}
