const {
  when,
  whenDev,
  whenProd,
  whenTest,
  ESLINT_MODES,
  POSTCSS_MODES,
} = require('@craco/craco');
const path = require('path');
const CracoAntDesignPlugin = require('craco-antd');

module.exports = {
  plugins: [
    {
      plugin: CracoAntDesignPlugin,
      options: {
        customizeThemeLessPath: './src/styles/antd.customize.less',
        // customizeTheme: {
        //   '@primary-color': '#1DA57A',
        //   '@link-color': '#1DA57A',
        // },
      },
    },
  ],
  webpack: {
    alias: {},
    plugins: [],
    configure: {
      /* Any webpack configuration options: https://webpack.js.org/configuration */
    },
    configure: (webpackConfig, { env, paths }) => {
      //html template
      //   webpackConfig.plugins[0].options.template = path.resolve(
      //     'public/home.html',
      //   );
      if (env === 'production') {
        webpackConfig.plugins[0].options.filename = 'templates/home.html';
      }

      //Css
      webpackConfig.plugins[5].options.chunkFilename =
        '' + webpackConfig.plugins[5].options.chunkFilename;
      webpackConfig.plugins[5].options.filename =
        '' + webpackConfig.plugins[5].options.filename; // 'static/css/[name].[contenthash:8].css'
      //Manifest

      webpackConfig.output.chunkFilename =
        '' + webpackConfig.output.chunkFilename;
      webpackConfig.output.filename = '' + webpackConfig.output.filename;
      return webpackConfig;
    },
  },
};
