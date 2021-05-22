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
import Title from 'antd/lib/typography/Title';
import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useDispatch, useSelector } from 'react-redux';
import { SmileOutlined } from '@ant-design/icons';
import { addOerNoteThunk } from 'app/pages/ResourcesPage/ducks/addOerNoteThunk';
import { unwrapResult } from '@reduxjs/toolkit';
import { getSupportedLangs } from 'app/api/api';

const { Option } = Select;

export function LanguageSwitcher() {
  const items = [];
  const { t, i18n } = useTranslation();

  const dispatch = useDispatch();
  const [isLoading, setIsLoading] = useState(false);
  const [supportedLangs, setSupportedLangs] = useState([]);

  const loadLangs = async () => {
    try {
      setIsLoading(true);
      const allLangs = await getSupportedLangs();
      setSupportedLangs(allLangs);
    } catch (err) {
      setSupportedLangs([]);
    } finally {
      setIsLoading(false);
    }
    debugger;
  };
  useEffect(() => {
    loadLangs();
  }, []);

  const onLangChange = lang => {
    i18n.changeLanguage(lang)
  };
  return (
    <>
      <Select
        defaultValue="EN"
        style={{ width: 60 }}
        loading={isLoading}
        onChange={onLangChange}
      >
        {supportedLangs.map((item: string) => {
          return (
            <Option key={item} value={item}>
              {item.toUpperCase()}
            </Option>
          );
        })}
      </Select>
    </>
  );
}
