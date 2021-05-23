import {
  Button,
  Col,
  Empty,
  Input,
  message,
  Row,
  Select,
  Space,
  Typography,
} from 'antd';
import {
  fetchOerNotesThunk,
  selectOerNotes,
} from 'app/pages/ResourcesPage/ducks/fetchOerNotesThunk';
import Title from 'antd/lib/typography/Title';
import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useDispatch, useSelector } from 'react-redux';
import {
  BugOutlined,
  CheckOutlined,
  CloseOutlined,
  DeleteFilled,
  DeleteOutlined,
  EditOutlined,
  SmileOutlined,
} from '@ant-design/icons';
import { addOerNoteThunk } from 'app/pages/ResourcesPage/ducks/addOerNoteThunk';
import { unwrapResult } from '@reduxjs/toolkit';
import { deleteOerNoteThunk } from 'app/pages/ResourcesPage/ducks/deleteOerNoteThunk';
import { updateOerNoteThunk } from 'app/pages/ResourcesPage/ducks/updateOerNoteThunk';

const { Option } = Select;
const { TextArea } = Input;
const { Paragraph } = Typography;

function useNotes(oerID) {
  const dispatch = useDispatch();

  const data = useSelector(state => {
    return selectOerNotes(state, oerID);
  });

  useEffect(() => {
    if (!data?.data) {
      dispatch(fetchOerNotesThunk({ oerID }));
    }
  }, []);
  return data;
}

function EditableNote({ note }) {
  const { text, id, oer_id } = note;
  const dispatch = useDispatch();
  const { t } = useTranslation();
  const [isDeleting, setIsDeleting] = useState(false);
  const [isEditing, setIsEditing] = useState(false);
  const [editedText, setEditedText] = useState(text);
  const [isSaving, setIsSaving] = useState(false);

  const onDeleteClick = async () => {
    setIsDeleting(true);
    try {
      const deleteResponse = await dispatch(
        deleteOerNoteThunk({ noteID: id, oerID: oer_id }),
      );
      const deleteResult = unwrapResult(deleteResponse as any);
      message.success(t('alerts.lbl_note_delete_success'));
    } catch (err) {
      message.error(t('alerts.lbl_note_delete_error'));
    } finally {
      setIsDeleting(false);
    }
  };
  const onEditClick = async () => {
    setIsEditing(true);
  };

  const onEditSuccessClick = async () => {
    setIsSaving(true);
    try {
      const updateResponse = await dispatch(
        updateOerNoteThunk({ oerID: oer_id, noteID: id, noteText: editedText }),
      );
      const updateResult = unwrapResult(updateResponse as any);
      message.success(t('alerts.lbl_note_update_success'));
      setIsEditing(false);
    } catch (err) {
      message.error(t('alerts.lbl_note_update_error'));
    } finally {
      setIsSaving(false);
    }
  };
  const onEditCancelClick = async () => {
    setEditedText(text);
    setIsEditing(false);
  };

  return (
    <Col>
      <span hidden={!isEditing}>
        <TextArea
          placeholder={t('inspector.lbl_enter_your_notes')}
          autoSize={{ minRows: 2, maxRows: 6 }}
          defaultValue={editedText}
          onChange={({ target: { value } }) => {
            setEditedText(value);
          }}
          value={editedText}
        />
        <Button
          onClick={onEditSuccessClick}
          loading={isSaving}
          icon={<CheckOutlined />}
        ></Button>
        <Button
          onClick={onEditCancelClick}
          loading={isSaving}
          icon={<CloseOutlined />}
        ></Button>
      </span>
      <span hidden={isEditing}>
        <span>{text}</span>
        <Button
          onClick={onEditClick}
          loading={isEditing}
          hidden={isDeleting}
          icon={<EditOutlined />}
        ></Button>
        <Button
          onClick={onDeleteClick}
          loading={isDeleting}
          icon={<DeleteOutlined />}
        ></Button>
      </span>
    </Col>
  );
}

export function NotesWidget({ oerID }) {
  const items = [];
  const { t } = useTranslation();
  const dispatch = useDispatch();
  const [inputText, setInputText] = useState('');
  const { data, loading, error } = useNotes(oerID);
  const [{ isAdding, isAddingError }, setIsAddingState] = useState({
    isAdding: false,
    isAddingError: false,
  });
  const predefinedTextArr = [
    'inspector.btn_material_rating_inspiring',
    'inspector.btn_material_rating_outstanding',
    'inspector.btn_material_rating_outdated',
    'inspector.btn_material_rating_language_errors',
    'inspector.btn_material_rating_poor_content',
    'inspector.btn_material_rating_poor_image',
    'inspector.btn_material_rating_poor_audio',
  ];

  const addNoteToOer = async (noteText, _oerID) => {
    setIsAddingState({
      isAdding: true,
      isAddingError: false,
    });
    try {
      const addResult = await dispatch(
        addOerNoteThunk({ oerID: _oerID, noteText }),
      );
      unwrapResult(addResult as any);
      setInputText('');
      setIsAddingState({
        isAdding: false,
        isAddingError: false,
      });
      message.success(t('alerts.lbl_add_note_success_message'));
    } catch (err) {
      setIsAddingState({
        isAdding: false,
        isAddingError: true,
      });
      message.error(t('alerts.lbl_add_note_fail_message'));
    }
  };
  const onAddNoteClick = event => {
    addNoteToOer(inputText, oerID);
  };

  return (
    <>
      <Row justify="center">
        <Col span={20}>
          <Row justify="space-between">
            <Col>
              <Title level={4}>{t('inspector.lbl_notes')}</Title>
            </Col>
            <Col>
              <Button icon={<SmileOutlined />} />
              <Select
                value={t('generic.lbl_notes_add_a_reaction', 'Add a Reaction')}
                // style={{ width: 120 }}
                bordered={false}
                onSelect={item => {
                  setInputText(value => {
                    return `${value} ${t(String(item).toString())}`;
                  });
                }}
              >
                {predefinedTextArr.map(item => {
                  return (
                    <Option key={item} value={item}>
                      {t(item)}
                    </Option>
                  );
                })}
              </Select>
            </Col>
          </Row>
        </Col>
        <Col span={20}>
          <Space direction="vertical" size={5} style={{ width: '100%' }}>
            <TextArea
              placeholder={t('inspector.lbl_enter_your_notes')}
              autoSize={{ minRows: 2, maxRows: 6 }}
              defaultValue={inputText}
              onChange={({ target: { value } }) => {
                setInputText(value);
              }}
              value={inputText}
            />
            <Button
              type="primary"
              disabled={!inputText}
              loading={isAdding}
              onClick={onAddNoteClick}
            >
              {t('playlist.btn_submit')}
            </Button>

            <Space direction="vertical" size={20} style={{ width: '100%' }}>
              {!data ||
                (!data.length && (
                  <Empty
                    description={
                      <span>
                        {t('alerts.lbl_note_empty_message', 'No notes found')}
                      </span>
                    }
                  />
                ))}
              {data?.map(item => {
                return <EditableNote key={item.id} note={item} />;
              })}
            </Space>
          </Space>
        </Col>
      </Row>
    </>
  );
}
