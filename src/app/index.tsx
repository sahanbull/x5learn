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
import { SearchPage } from './pages/SearchPage/Loadable';
import { NotFoundPage } from './containers/NotFoundPage/Loadable';
import { ROUTES } from 'routes/routes';

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
        <Route
          exact
          path={ROUTES.PLAYLISTS + '/:id'}
          component={PlaylistsPage}
        />
        <Route exact path={ROUTES.RESOURCES + '/:id'} component={HomePage} />
        <Route component={NotFoundPage} />
      </Switch>
      <GlobalStyle />
    </BrowserRouter>
  );
}
