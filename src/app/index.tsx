/**
 *
 * App
 *
 * This component is the skeleton around the actual pages, and should only
 * contain code that should be seen on all pages. (e.g. navigation bar)
 */

import * as React from 'react';
import { Helmet } from 'react-helmet-async';
import { Switch, Route, BrowserRouter } from 'react-router-dom';

import { GlobalStyle } from '../styles/global-styles';

import { HomePage } from './pages/HomePage/Loadable';
import { PlaylistsPage } from './pages/PlaylistsPage/Loadable';
import { ResourcesPage } from './pages/ResourcesPage/Loadable';
import { SearchPage } from './pages/SearchPage/Loadable';
import { NotFoundPage } from './containers/NotFoundPage/Loadable';
import { ROUTES } from 'routes/routes';
import { CreatePlaylistsPage } from './pages/CreatePlaylistPage/Loadable';
import { PublishPlaylistPage } from './pages/PublishPlaylistPage/Loadable';
import { MyPlaylistsPage } from './pages/MyPlaylistPage/Loadable';

export function App() {
  return (
    <BrowserRouter>
      <Helmet
        titleTemplate="%s - React Boilerplate"
        defaultTitle="React Boilerplate"
      >
        <meta name="description" content="A React Boilerplate application" />
      </Helmet>
      <Switch>
        <Route exact path={'/'} component={HomePage} />
        <Route exact path={ROUTES.HOMEPAGE} component={HomePage} />
        <Route exact path={ROUTES.HOMEPAGE} component={HomePage} />
        <Route exact path={ROUTES.RESOURCES} component={HomePage} />
        <Route exact path={ROUTES.SEARCH} component={SearchPage} />
        <Route exact path={ROUTES.MY_PLAYLISTS} component={MyPlaylistsPage} />
        <Route
          exact
          path={ROUTES.PLAYLISTS_CREATE}
          component={CreatePlaylistsPage}
        />
        <Route
          exact
          path={ROUTES.PLAYLISTS + '/:id/publish'}
          component={PublishPlaylistPage}
        />
        <Route
          exact
          path={ROUTES.PLAYLISTS + '/:id'}
          component={PlaylistsPage}
        />
        <Route
          exact
          path={ROUTES.RESOURCES + '/:id'}
          component={ResourcesPage}
        />
        <Route component={NotFoundPage} />
      </Switch>
      <GlobalStyle />
    </BrowserRouter>
  );
}
