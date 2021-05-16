import { Menu, Dropdown, Spin } from 'antd';
import { selectEntityDefinition } from 'app/containers/Layout/ducks/allEntityDefinitionsSlice';
import { useTranslation } from 'react-i18next';

import { useDispatch, useSelector } from 'react-redux';
import { Link, useHistory, useLocation } from 'react-router-dom';
import { ROUTES } from 'routes/routes';

export const EntityDefinitionMenuItem = ({ entity, ...props }) => {
  const { data, loading, error } = useSelector(state => {
    return selectEntityDefinition(state, entity.id);
  });
  const history = useHistory();
  const { t } = useTranslation();
  return (
    <>
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
    </>
  );
};
