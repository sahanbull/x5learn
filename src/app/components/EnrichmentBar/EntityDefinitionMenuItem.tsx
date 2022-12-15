import { Menu, Spin, Popover } from 'antd';
import { selectEntityDefinition } from 'app/containers/Layout/ducks/allEntityDefinitionsSlice';
import { useTranslation } from 'react-i18next';

import { useSelector } from 'react-redux';
import { Link } from 'react-router-dom';
import { ROUTES } from 'routes/routes';
import { selectUnveilAi } from 'app/containers/Header/HeaderSlice';
import { AppstoreOutlined } from '@ant-design/icons';

export const EntityDefinitionMenuItem = ({ entity, ...props }) => {
  const unveilAi = useSelector(selectUnveilAi);
  const { data, loading, error } = useSelector(state => {
    return selectEntityDefinition(state, entity.id);
  });
  const { t } = useTranslation();
  return (
    <div
      style={{
        border: unveilAi ? '2px solid red' : 'none',
        width: 'fit-content',
      }}
    >
      {unveilAi && (
        <Popover
          title=""
          content={
            <div style={{ width: '175px' }}>
              <p>
                The JSI Wikifier is a web service that takes a text document as
                input and annotates it with links to relevant Wikipedia
                concepts.
              </p>
              <a href="https://wikifier.org" target="blank">
                Try it yourself
              </a>
            </div>
          }
          trigger="hover"
        >
          <p style={{ textAlign: 'center' }}>
            <AppstoreOutlined />
          </p>
        </Popover>
      )}
      {error && <>{error}</>}
      {loading && <Spin spinning={loading} delay={500}></Spin>}
      {data && (
        <Menu.Item
          {...props}
          style={{ whiteSpace: 'normal', height: 'auto', width: '200px' }}
          key={'item_detail' + entity.title}
        >
          {data}
        </Menu.Item>
      )}

      <Menu.Item {...props} key={'item_search' + entity.title}>
        <Link to={`${ROUTES.SEARCH}/?q=${entity.title}`}>
          {t('generic.lbl_search')}
        </Link>
      </Menu.Item>
      <Menu.Item {...props} key={'item_url' + entity.title}>
        <a
          onClick={evt => {
            evt.preventDefault();
            window.open(entity.url, '_blank');
          }}
          href={`${entity.url}`}
          target="_blank"
        >
          {t('generic.lbl_wikipedia')}
        </a>
      </Menu.Item>
    </div>
  );
};
