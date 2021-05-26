import styled from 'styled-components/macro';
import { Helmet } from 'react-helmet-async';
import {
  Row,
  Col,
  Card,
  Typography,
  Button,
  Progress,
  Spin,
  Form,
  Input,
  Select,
  message,
  Modal,
  List,
  Skeleton,
} from 'antd';
import { useDispatch, useSelector } from 'react-redux';
import { useEffect, useState } from 'react';
import { AsyncThunkAction, unwrapResult } from '@reduxjs/toolkit';
import { useTranslation } from 'react-i18next';
import {
  optimizeTempPlaylistPathThunk,
  acceptOptimizedSequenceAction,
} from 'app/containers/Layout/ducks/myPlaylistMenu/optimizeTempPlaylistPath';
import { updateTempPlaylistThunk } from 'app/containers/Layout/ducks/myPlaylistMenu/updateTempPlaylist';
import { RootState } from 'types';
import { selectOerByID } from '../PlaylistItemSortWidget/PlaylistItemSortWidget';
import Avatar from 'antd/lib/avatar/avatar';

const { Option } = Select;
const { TextArea } = Input;
const { Title, Text, Paragraph } = Typography;

const layout = {
  labelCol: { span: 24 },
  wrapperCol: { span: 24 },
};

const tailLayout = {
  wrapperCol: { offset: 0, span: 16 },
};

const OerRow = ({ oerId, mark = false, ...props }) => {
  const cardData = useSelector((state: RootState) => {
    return selectOerByID(state, oerId);
  });
  debugger;
  const loading = useSelector((state: RootState) => {
    return state.allOERs.loading;
  });
  debugger;
  return (
    <List.Item>
      <Paragraph ellipsis={{ rows: 2 }} mark={mark}>
        {cardData?.title}
      </Paragraph>
    </List.Item>
  );
  // return <OerSortableView loading={loading} card={cardData} />;
};

export function PlaylistOptimizeConfirmationWidget(props: {
  formData?;
  visible: boolean;
  setIsModalVisible: (a: boolean) => void;
}) {
  const { t } = useTranslation();

  const [isLoading, setIsLoading] = useState(false);
  const [isUndoing, setIsUndoing] = useState(false);
  // const [isUpdating, setIsUpdating] = useState(false);
  const { playlist, playlist_items } = props.formData;

  const dispatch = useDispatch();

  const oerMap = playlist_items.reduce((accumulator, oer) => {
    accumulator[oer.oer_id] = oer;
    return accumulator;
  }, {});

  const [unOptimizedOedIdOrder, setUnOptimizedOedIdOrder] = useState(
    playlist_items.map(oer => {
      return oer.oer_id;
    }),
  );
  const [optimizedOedIdOrder, setOptimizedOedIdOrder] = useState([]);

  const optimizeLearningPath = async () => {
    try {
      setIsLoading(true);

      const oerIds = playlist_items.map(oer => {
        return oer.oer_id;
      });

      const optimizeCall = (await dispatch(
        optimizeTempPlaylistPathThunk({
          tempPlaylistName: playlist.title,
          oerIds,
        }),
      )) as any;
      const orderedResult = await unwrapResult(optimizeCall);
      setOptimizedOedIdOrder(orderedResult);

      if (
        JSON.stringify(unOptimizedOedIdOrder) === JSON.stringify(orderedResult)
      ) {
        message.warn(t('alerts.lbl_learning_path_already_optimized'));
      }
      setIsLoading(false);
    } catch (e) {
      setIsLoading(false);
      message.error(t('alerts.lbl_optimize_learning_path_error'));
    }
  };

  const handleOk = async () => {
    message.info(t('alerts.lbl_optimize_learning_path_success'));
    dispatch(
      acceptOptimizedSequenceAction({
        tempPlaylistName: playlist.title,
        optimizedOedIdOrder,
      }),
    );
    props.setIsModalVisible(false);
  };

  const handleCancel = async () => {
    setIsUndoing(true);
    try {
      const undoOrder = (await dispatch(
        updateTempPlaylistThunk({
          ...playlist,
          temp_title: playlist.title,
          playlist_items: unOptimizedOedIdOrder,
        }),
      )) as any;
      const undoOrderResult = unwrapResult(undoOrder);
      setIsUndoing(false);
      props.setIsModalVisible(false);
    } catch (err) {
      setIsUndoing(false);
    }
  };

  useEffect(() => {
    if (props.visible) {
      optimizeLearningPath();
    }
  }, [props.visible]);

  return (
    <Modal
      title={t('playlist.btn_optimize_learning_path')}
      visible={props.visible}
      confirmLoading={isLoading}
      cancelButtonProps={{ disabled: isLoading, loading: isUndoing }}
      okText={t('generic.btn_save')}
      cancelText={t('playlist.btn_undo_optimize_learning_path')}
      onOk={handleOk}
      onCancel={handleCancel}
      destroyOnClose={true}
    >
      <Row>
        <Col span={12}>
          <List
            header={<b>{t('playlist.lbl_current_path', 'Current Path')}</b>}
            itemLayout="horizontal"
            dataSource={unOptimizedOedIdOrder.map(item => {
              return { oerId: item };
            })}
            renderItem={item => <OerRow {...(item as any)} />}
          />
        </Col>
        <Col span={12}>
          {isLoading && (
            <List
              header={
                <b>{t('playlist.lbl_optimized_path', 'Optimized Path')}</b>
              }
              itemLayout="horizontal"
              dataSource={unOptimizedOedIdOrder}
              renderItem={item => <Skeleton paragraph={false} active={true} />}
            />
          )}
          {!isLoading && (
            <List
              header={
                <b>{t('playlist.lbl_optimized_path', 'Optimized Path')}</b>
              }
              itemLayout="horizontal"
              dataSource={optimizedOedIdOrder.map((item, idx) => {
                const mark = item !== unOptimizedOedIdOrder[idx];
                debugger;
                return { oerId: item, mark };
              })}
              renderItem={item => <OerRow {...item} />}
            />
          )}
        </Col>
      </Row>
    </Modal>
  );
}
