import {
  Button,
  Card,
  Col,
  Empty,
  Input,
  message,
  Row,
  Select,
  Typography,
} from 'antd';

import Title from 'antd/lib/typography/Title';
import { fetchRelatedOers } from 'app/api/api';
import {
  fetchRelatedOersThunk,
  selectRelatedOers,
} from 'app/pages/ResourcesPage/ducks/fetchRelatedOersThunk';
import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useDispatch, useSelector } from 'react-redux';
import { Link } from 'react-router-dom';
import { ROUTES } from 'routes/routes';

const { Option } = Select;
const { TextArea } = Input;
const { Paragraph } = Typography;

function useRelatedOers(oerID) {
  const dispatch = useDispatch();

  const data = useSelector(state => {
    return selectRelatedOers(state, oerID);
  });

  useEffect(() => {
    if (!data?.data) {
      dispatch(fetchRelatedOersThunk({ oerID }));
    }
  }, []);
  return data;
}

export function RelatedOersWidget({ oerID }) {
  const items = [];
  const { t } = useTranslation();
  const dispatch = useDispatch();
  const { loading, data, error } = useRelatedOers(oerID);

  return (
    <>
      <Row justify="center">
        <Col span={20}>
          <Row justify="space-between">
            <Col>
              <Title level={4}>{t('inspector.btn_related')}</Title>
            </Col>
          </Row>
        </Col>
        <Col span={20}>
          {!data && <Empty />}
          <Row gutter={[20, 20]}>
            {data?.map(item => {
              const {
                id,
                title,
                images,
                durationInSeconds,
                description,
              } = item;
              let pathToNavigateTo = `${ROUTES.RESOURCES}/${id}`;
              const imageBaseURL = process.env.REACT_APP_IMAGE_BASE_URL;
              let imgSrc = `/static/img/thumbnail_unavailable.jpg`;
              if (images[0]) {
                imgSrc = `${imageBaseURL}/${images[0]}`;
              }
              return (
                <Col lg={6} md={12}>
                  <Link key={id} to={pathToNavigateTo}>
                    <Card
                      hoverable
                      // style={{ width: 240 }}
                      cover={<img alt={title} src={imgSrc} />}
                    >
                      <Card.Meta
                        title={title}
                        // description={description}
                      />
                    </Card>
                  </Link>
                </Col>
              );
            })}
          </Row>
        </Col>
      </Row>
    </>
  );
}
