import React from 'react';
import { Helmet } from 'react-helmet-async';
import { AppLayout } from 'app/containers/Layout/AppLayout';
import { MyPlaylistWidget } from './components/__tests__/MyPlaylistWidget';

export function MyPlaylistsPage() {
  return (
    <>
      <Helmet>
        <title>Playlists Page</title>
        <meta name="description" content="X5 Learn AI based learning" />
      </Helmet>
      <AppLayout>
        <MyPlaylistWidget />
      </AppLayout>
    </>
  );
}
