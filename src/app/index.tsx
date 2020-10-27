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

import { HomePage } from './containers/HomePage/Loadable';
import { NotFoundPage } from './containers/NotFoundPage/Loadable';

import 'antd/dist/antd.less';
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
        <Route exact path={process.env.PUBLIC_URL + '/'} component={HomePage} />
        <Route
          exact
          path={process.env.PUBLIC_URL + '/playlists'}
          component={HomePage}
        />
        <Route
          exact
          path={process.env.PUBLIC_URL + '/resources'}
          component={HomePage}
        />
        <Route
          exact
          path={process.env.PUBLIC_URL + '/search'}
          component={HomePage}
        />
        <Route
          exact
          path={process.env.PUBLIC_URL + '/playlists/:id'}
          component={HomePage}
        />
        <Route
          exact
          path={process.env.PUBLIC_URL + '/resources/:id'}
          component={HomePage}
        />
        <Route component={NotFoundPage} />
      </Switch>
      <GlobalStyle />
    </BrowserRouter>
  );
}
