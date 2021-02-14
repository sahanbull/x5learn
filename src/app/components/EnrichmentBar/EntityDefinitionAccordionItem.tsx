import { Menu, Dropdown, Spin } from 'antd';
import { selectEntityDefinition } from 'app/containers/Layout/ducks/allEntityDefinitionsSlice';

import { useDispatch, useSelector } from 'react-redux';
import { Link, useHistory, useLocation } from 'react-router-dom';
import { ROUTES } from 'routes/routes';

export const EntityDefinitionAccordionItem = ({ entity, ...props }) => {
  const { data, loading, error } = useSelector(state => {
    return selectEntityDefinition(state, entity.id);
  });
  const history = useHistory();
  return (
    <>
      {error && <>{error}</>}
      {loading && <Spin spinning={loading} delay={500}></Spin>}
      {data && <p style={{ width: '200px' }}>{data}</p>}

      <div>
        <a
          onClick={evt => {
            evt.preventDefault();
            window.open(entity.url, '_blank');
          }}
          href={`${entity.url}`}
          target="_blank"
        >
          Wikipedia
        </a>
      </div>
      <div>
        <Link to={`${ROUTES.SEARCH}/?q=${entity.title}`}>Search</Link>
      </div>
    </>
  );
};
