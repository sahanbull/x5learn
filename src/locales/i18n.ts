import i18next from 'i18next';
import { initReactI18next } from 'react-i18next';

import LanguageDetector from 'i18next-browser-languagedetector';
import HttpApi from 'i18next-http-backend';

import en from './en/translation.json';
import de from './de/translation.json';
import { ConvertedToObjectType } from './types';
import { getTranslations } from 'app/api/api';

const translationsJson = {
  en: {
    translation: en,
  },
  de: {
    translation: de,
  },
};

export type TranslationResource = typeof en;
export type LanguageKey = keyof TranslationResource;

export const translations: ConvertedToObjectType<TranslationResource> = {} as any;

/*
 * Converts the static JSON file into an object where keys are identical
 * but values are strings concatenated according to syntax.
 * This is helpful when using the JSON file keys and still have the intellisense support
 * along with type-safety
 */
const convertLanguageJsonToObject = (obj: any, dict: {}, current?: string) => {
  Object.keys(obj).forEach(key => {
    const currentLookupKey = current ? `${current}.${key}` : key;
    if (typeof obj[key] === 'object') {
      dict[key] = {};
      convertLanguageJsonToObject(obj[key], dict[key], currentLookupKey);
    } else {
      dict[key] = currentLookupKey;
    }
  });
};

const backendOptions = {
  // path where resources get loaded from, or a function
  // returning a path:
  // function(lngs, namespaces) { return customPath; }
  // the returned path will interpolate lng, ns if provided like giving a static path
  //
  // If allowMultiLoading is false, lngs and namespaces will have only one element each,
  // If allowMultiLoading is true, lngs and namespaces can have multiple elements
  // loadPath: '/locales/{{lng}}/{{ns}}.json',
  loadPath: '{{lng}}',
  // loadPath: '/api/v1/localization/?language={{lng}}',
  // loadPath: (lngs, namespaces) => {
  //   debugger

  //   return '/api/v1/localization/?language={{lng}}';
  // },

  // path to post missing resources, or a function
  // function(lng, namespace) { return customPath; }
  // the returned path will interpolate lng, ns if provided like giving a static path
  addPath: '/locales/add/{{lng}}/{{ns}}',

  // your backend server supports multiloading
  // /locales/resources.json?lng=de+en&ns=ns1+ns2
  // Adapter is needed to enable MultiLoading https://github.com/i18next/i18next-multiload-backend-adapter
  // Returned JSON structure in this case is
  // {
  //  lang : {
  //   namespaceA: {},
  //   namespaceB: {},
  //   ...etc
  //  }
  // }
  allowMultiLoading: false, // set loadPath: '/locales/resources.json?lng={{lng}}&ns={{ns}}' to adapt to multiLoading

  // parse data after it has been fetched
  // in example use https://www.npmjs.com/package/json5
  // here it removes the letter a from the json (bad idea)
  parse: function (data) {
    return data.replace(/a/g, '');
  },

  //parse data before it has been sent by addPath
  parsePayload: function (namespace, key, fallbackValue) {
    return { key };
  },

  // allow cross domain requests
  crossDomain: false,

  // allow credentials on cross domain requests
  withCredentials: false,

  // overrideMimeType sets request.overrideMimeType("application/json")
  overrideMimeType: false,

  // custom request headers sets request.setRequestHeader(key, value)
  customHeaders: {
    authorization: 'foo',
    // ...
  },

  requestOptions: {
    // used for fetch, can also be a function (payload) => ({ method: 'GET' })
    mode: 'cors',
    credentials: 'same-origin',
    cache: 'default',
  },

  // define a custom request function
  // can be used to support XDomainRequest in IE 8 and 9
  //
  // 'options' will be this entire options object
  // 'url' will be passed the value of 'loadPath'
  // 'payload' will be a key:value object used when saving missing translations
  // 'callback' is a function that takes two parameters, 'err' and 'res'.
  //            'err' should be an error
  //            'res' should be an object with a 'status' property and a 'data' property
  //            containing a stringified object instance beeing the key:value translation pairs for the
  //            requested language and namespace, or null in case of an error.
  request: async (options, url, payload, callback) => {
    try {
      const translationData = await getTranslations(url);
      callback(null, {
        status: '200',
        data: translationData.dictionary,
      });
    } catch (err) {
      callback(err);
    }
  },

  // adds parameters to resource URL. 'example.com' -> 'example.com?v=1.3.5'
  queryStringParams: { v: '1.3.5' },

  reloadInterval: false, // can be used to reload resources in a specific interval (useful in server environments)
};
export const i18n = i18next
  // pass the i18n instance to react-i18next.
  .use(initReactI18next)
  // detect user language
  // learn more: https://github.com/i18next/i18next-browser-languageDetector
  .use(LanguageDetector)
  .use(HttpApi)
  // init i18next
  // for all options read: https://www.i18next.com/overview/configuration-options
  .init(
    {
      load: 'languageOnly',
      backend: backendOptions,
      // resources: translationsJson,
      fallbackLng: 'en',
      debug:
        process.env.NODE_ENV !== 'production' &&
        process.env.NODE_ENV !== 'test',

      interpolation: {
        escapeValue: false, // not needed for react as it escapes by default
      },
    },
    // () => {
    //   convertLanguageJsonToObject(en, translations);
    // },
  );
