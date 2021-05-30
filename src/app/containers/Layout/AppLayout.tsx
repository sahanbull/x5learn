import React from 'react';
import { Layout } from 'antd';

import {
  sliceKey as playlistMenuSliceKey,
  reducer as playlistMenuReducer,
} from './ducks/myPlaylistsMenuSlice';
import {
  sliceKey as oerEnrichmentSliceKey,
  reducer as oerEnrichmentReducer,
} from './ducks/oerEnrichmentSlice';

import { AppHeader } from '../Header/AppHeader';
import { AppFooter } from '../Footer/AppFooter';

import { AppSideBar } from '../SideBar/AppSideBar';
import { useInjectReducer } from 'redux-injectors';
import {
  sliceKey as oerSliceKey,
  reducer as oerReducer,
} from './ducks/allOERSlice';
import {
  sliceKey as playlistLicenseSliceKey,
  reducer as playlistLicenseReducer,
} from './ducks/playlistLicenseSlice';
import {
  sliceKey as entityDefSliceKey,
  reducer as entityDefReducer,
} from './ducks/allEntityDefinitionsSlice';
const { Header, Content, Sider, Footer } = Layout;

export function AppLayout(props) {
  useInjectReducer({ key: playlistMenuSliceKey, reducer: playlistMenuReducer });
  useInjectReducer({ key: oerSliceKey, reducer: oerReducer });
  useInjectReducer({
    key: oerEnrichmentSliceKey,
    reducer: oerEnrichmentReducer,
  });
  useInjectReducer({
    key: playlistLicenseSliceKey,
    reducer: playlistLicenseReducer,
  });
  useInjectReducer({
    key: entityDefSliceKey,
    reducer: entityDefReducer,
  });

  return (
    <Layout>
      <AppHeader></AppHeader>
      <Layout>
        <AppSideBar />
        <Layout>
          {/* <AppBreadcrumb /> */}
          <Content
            className="site-layout-background"
            style={{
              padding: 12,
              minHeight: 280,
            }}
          >
            {props.children}
          </Content>
        </Layout>
      </Layout>
      <AppFooter></AppFooter>
    </Layout>
  );
}
