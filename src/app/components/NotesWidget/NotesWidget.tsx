import { Input, Select } from 'antd';
import {
  fetchOerNotesThunk,
  selectOerNotes,
} from 'app/pages/ResourcesPage/ducks/fetchOerNotesThunk';
import { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';

const { Option } = Select;
const { TextArea } = Input;

export function NotesWidget({ oerID }) {
  const items = [];
  const dispatch = useDispatch();

  const { data, loading, error } = useSelector(state => {
    return selectOerNotes(state, oerID);
  });
  useEffect(() => {
    dispatch(fetchOerNotesThunk({ oerID }));
  }, []);
  return (
    <>
      <TextArea
        placeholder="Your note..."
        autoSize={{ minRows: 2, maxRows: 6 }}
      />
      <Select mode="tags" style={{ width: '100%' }} tokenSeparators={[',']}>
        {items}
      </Select>
      ,
    </>
  );
}
