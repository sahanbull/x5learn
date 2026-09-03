import styled from 'styled-components/macro';
import { Helmet } from 'react-helmet-async';
import axios from 'axios';
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
  InputNumber,
  Select,
  Modal,
  message,
  Space,
  Alert,
} from 'antd';
import { AppLayout } from 'app/containers/Layout/AppLayout';
import {
  ArrowLeftOutlined,
  CheckCircleOutlined,
  DeleteOutlined,
  EyeOutlined,
  FilePdfOutlined,
  LinkOutlined,
  PlayCircleOutlined,
  PlusOutlined,
  SearchOutlined,
  UploadOutlined,
} from '@ant-design/icons';
import { useDispatch, useSelector } from 'react-redux';
import { RootState } from 'types';
import { useEffect, useState } from 'react';
import { fetchPlaylistLicensesThunk } from 'app/containers/Layout/ducks/playlistLicenseSlice';
import {
  createTempPlaylistThunk,
  fetchMyPlaylistsMenuThunk,
} from 'app/containers/Layout/ducks/myPlaylistsMenuSlice';
import { AsyncThunkAction, unwrapResult } from '@reduxjs/toolkit';
import { useHistory } from 'react-router-dom';
import { ROUTES } from 'routes/routes';
import { PlaylistPublishFormWidget } from './PlaylistPublishFormWidget';
import { PlaylistItemSortWidget } from '../PlaylistItemSortWidget/PlaylistItemSortWidget';
import { updateTempPlaylistThunk } from 'app/containers/Layout/ducks/myPlaylistMenu/updateTempPlaylist';
import { useTranslation } from 'react-i18next';
import { PlaylistOptimizeConfirmationWidget } from './PlaylistOptimizeConfirmationWidget';

const { Option } = Select;
const { TextArea } = Input;
const { Title, Text } = Typography;

const layout = {
  labelCol: { span: 24 },
  wrapperCol: { span: 24 },
};

const tailLayout = {
  wrapperCol: { offset: 0, span: 16 },
};

const StickyPlaylistActions = styled(Col)`
  position: sticky !important;
  top: 0;
  z-index: 50;

  margin-bottom: 22px;
  padding: 14px 0 !important;

  background: rgba(255, 255, 255, 0.96);
  border-bottom: 1px solid #e8ecf3;
  box-shadow: 0 6px 16px rgba(35, 48, 79, 0.06);
  backdrop-filter: blur(8px);

  > .ant-row {
    padding: 0 2px;
  }

  .ant-space {
    display: flex;
    flex-wrap: wrap;
    justify-content: flex-end;
  }

  @media (max-width: 767px) {
    padding: 12px 0 !important;

    > .ant-row {
      justify-content: flex-start;
    }

    .ant-space {
      width: 100%;
      justify-content: flex-start;
    }

    .ant-btn {
      flex: 1 1 auto;
    }
  }
`;

const YouTubeModalTitle = styled.div`
  padding: 3px 0;

  strong {
    display: block;
    color: #202939;
    font-size: 18px;
    font-weight: 700;
    line-height: 1.35;
  }

  span {
    display: block;
    margin-top: 3px;
    color: #7a8497;
    font-size: 12px;
    font-weight: 400;
  }
`;

const YouTubeModalContent = styled.div`
  .youtube-search-header {
    margin-bottom: 22px;
  }

  .youtube-search-heading {
    margin-bottom: 14px;
  }

  .youtube-search-heading h3 {
    margin: 0 0 4px;
    color: #202939;
    font-size: 18px;
    font-weight: 650;
  }

  .youtube-search-heading p {
    margin: 0;
    color: #697386;
    font-size: 13px;
  }

  .youtube-search-bar {
    display: flex;
    align-items: stretch;
    gap: 10px;
  }

  .youtube-search-input.ant-input-affix-wrapper {
    height: 46px;
    padding: 0 15px;
    border-color: #dce2eb;
    border-radius: 12px;
    box-shadow: 0 2px 7px rgba(35, 48, 79, 0.04);
  }

  .youtube-search-input.ant-input-affix-wrapper-focused,
  .youtube-search-input.ant-input-affix-wrapper:focus {
    border-color: #7f98d8;
    box-shadow: 0 0 0 3px rgba(49, 87, 200, 0.1);
  }

  .youtube-search-button.ant-btn {
    min-width: 126px;
    height: 44px;
    border-radius: 12px;
    font-weight: 600;
    box-shadow: 0 4px 12px rgba(49, 87, 200, 0.18);
  }

  .youtube-results-heading {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin: 0 2px 12px;
  }

  .youtube-results-heading strong {
    color: #344054;
    font-size: 14px;
  }

  .youtube-results-heading span {
    color: #8b95a5;
    font-size: 12px;
  }

  .youtube-results {
    max-height: 58vh;
    overflow-x: hidden;
    overflow-y: auto;
    padding: 2px 6px 8px 2px;
  }

  .youtube-result-card.ant-card {
    height: 100%;
    overflow: hidden;
    border: 1px solid #e5e9f0;
    border-radius: 12px;
    box-shadow: 0 3px 12px rgba(35, 48, 79, 0.06);
  }

  .youtube-result-card.ant-card:hover {
    border-color: #b9c8ec;
    box-shadow: 0 8px 22px rgba(35, 48, 79, 0.12);
    transform: translateY(-2px);
  }

  .youtube-result-card .ant-card-body {
    padding: 14px;
  }

  .youtube-result-thumbnail {
    position: relative;
    display: block;
    width: 100%;
    height: 168px;
    padding: 0;
    overflow: hidden;
    background: #eef1f5;
    border: 0;
    cursor: pointer;
  }

  .youtube-result-thumbnail img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .youtube-thumbnail-overlay {
    position: absolute;
    inset: 0;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    flex-direction: column;
    gap: 5px;
    color: #ffffff;
    font-size: 12px;
    font-weight: 600;
    background: rgba(16, 24, 40, 0.18);
    opacity: 0;
    transition: opacity 0.18s ease, background 0.18s ease;
  }

  .youtube-thumbnail-overlay .anticon {
    font-size: 34px;
    filter: drop-shadow(0 2px 5px rgba(0, 0, 0, 0.35));
  }

  .youtube-result-thumbnail:hover .youtube-thumbnail-overlay,
  .youtube-result-thumbnail:focus .youtube-thumbnail-overlay,
  .youtube-selected-preview:hover .youtube-thumbnail-overlay,
  .youtube-selected-preview:focus .youtube-thumbnail-overlay {
    background: rgba(16, 24, 40, 0.48);
    opacity: 1;
  }

  .youtube-result-title {
    display: -webkit-box;
    min-height: 42px;
    margin-bottom: 5px;
    overflow: hidden;
    color: #273142;
    font-size: 14px;
    font-weight: 650;
    line-height: 1.45;
    -webkit-box-orient: vertical;
    -webkit-line-clamp: 2;
  }

  .youtube-result-channel {
    display: block;
    min-height: 20px;
    overflow: hidden;
    color: #7a8497;
    font-size: 12px;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .youtube-select-button.ant-btn {
    width: 100%;
    margin-top: 12px;
    border-radius: 8px;
  }

  .youtube-empty-state {
    display: flex;
    min-height: 270px;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 32px;
    color: #7a8497;
    text-align: center;
    background: #fafbfc;
    border: 1px dashed #d9dfe8;
    border-radius: 12px;
  }

  .youtube-empty-state .anticon {
    margin-bottom: 14px;
    color: #9aa5b5;
    font-size: 30px;
  }

  .youtube-load-more {
    margin-top: 20px;
    text-align: center;
  }

  .youtube-details-intro {
    margin-bottom: 20px;
    padding: 15px 18px;
    background: #f7f9fc;
    border: 1px solid #e7ebf2;
    border-radius: 10px;
  }

  .youtube-details-intro strong {
    display: block;
    margin-bottom: 3px;
    color: #273142;
  }

  .youtube-details-intro span {
    color: #697386;
    font-size: 13px;
  }

  .youtube-selected-preview {
    position: relative;
    display: block;
    width: 100%;
    max-width: 480px;
    margin: 10px 0 24px;
    padding: 0;
    overflow: hidden;
    background: #eef1f5;
    border: 1px solid #e2e7ef;
    border-radius: 12px;
    cursor: pointer;
  }

  .youtube-selected-preview img {
    display: block;
    width: 100%;
    aspect-ratio: 16 / 9;
    object-fit: cover;
  }

  .youtube-selected-preview .youtube-thumbnail-overlay {
    opacity: 1;
    background: rgba(16, 24, 40, 0.2);
  }

  .youtube-back-button.ant-btn {
    height: auto;
    margin: 0 0 14px -8px;
    padding: 4px 8px;
    color: #445b95;
    font-weight: 600;
  }

  .youtube-form-section {
    margin-bottom: 18px;
    padding: 20px;
    background: #ffffff;
    border: 1px solid #e5eaf1;
    border-radius: 14px;
    box-shadow: 0 3px 12px rgba(35, 48, 79, 0.04);
  }

  .youtube-section-heading {
    margin-bottom: 18px;
    padding-bottom: 13px;
    border-bottom: 1px solid #edf0f4;
  }

  .youtube-section-heading h4 {
    margin: 0 0 3px;
    color: #273142;
    font-size: 15px;
    font-weight: 700;
  }

  .youtube-section-heading p {
    margin: 0;
    color: #8490a2;
    font-size: 12px;
  }

  .youtube-details .ant-form-item {
    margin-bottom: 18px;
  }

  .youtube-details .ant-form-item:last-child {
    margin-bottom: 0;
  }

  .youtube-details .ant-form-item-label {
    padding-bottom: 7px;
  }

  .youtube-details .ant-form-item-label > label {
    color: #344054;
    font-size: 13px;
    font-weight: 600;
  }

  .youtube-details .ant-input,
  .youtube-details .ant-input-affix-wrapper,
  .youtube-details .ant-input-number {
    border-color: #dce2eb;
    border-radius: 11px;
  }

  .youtube-details input.ant-input,
  .youtube-details .ant-input-number {
    min-height: 43px;
  }

  .youtube-details .ant-input-number-input {
    height: 41px;
  }

  .youtube-details textarea.ant-input {
    min-height: 112px;
    padding: 11px 13px;
    resize: vertical;
  }

  .youtube-details .ant-input:hover,
  .youtube-details .ant-input-number:hover {
    border-color: #91a5d8;
  }

  .youtube-details .ant-input:focus,
  .youtube-details .ant-input-focused,
  .youtube-details .ant-input-number-focused {
    border-color: #738dce;
    box-shadow: 0 0 0 3px rgba(49, 87, 200, 0.09);
  }

  @media (max-width: 767px) {
    .youtube-search-bar {
      flex-direction: column;
    }

    .youtube-search-button.ant-btn {
      width: 100%;
    }

    .youtube-results {
      max-height: 54vh;
    }

    .youtube-form-section {
      padding: 16px;
    }
  }
`;

const PDFModalContent = styled.div`
  .pdf-intro {
    display: flex;
    align-items: flex-start;
    gap: 13px;
    margin-bottom: 20px;
    padding: 16px 18px;
    color: #566176;
    background: linear-gradient(135deg, #f8faff 0%, #f5f7fb 100%);
    border: 1px solid #e4e9f2;
    border-radius: 13px;
  }

  .pdf-intro .anticon {
    margin-top: 2px;
    color: #d14343;
    font-size: 25px;
  }

  .pdf-intro strong {
    display: block;
    margin-bottom: 3px;
    color: #273142;
    font-size: 14px;
  }

  .pdf-intro span {
    display: block;
    font-size: 12px;
    line-height: 1.55;
  }

  .pdf-form-section {
    margin-bottom: 18px;
    padding: 20px;
    background: #ffffff;
    border: 1px solid #e5eaf1;
    border-radius: 14px;
    box-shadow: 0 3px 12px rgba(35, 48, 79, 0.04);
  }

  .pdf-section-heading {
    margin-bottom: 18px;
    padding-bottom: 13px;
    border-bottom: 1px solid #edf0f4;
  }

  .pdf-section-heading h4 {
    margin: 0 0 3px;
    color: #273142;
    font-size: 15px;
    font-weight: 700;
  }

  .pdf-section-heading p {
    margin: 0;
    color: #8490a2;
    font-size: 12px;
  }

  .pdf-url-row {
    display: flex;
    align-items: flex-start;
    gap: 10px;
  }

  .pdf-url-field {
    flex: 1;
  }

  .pdf-url-row .ant-btn {
    height: 43px;
    margin-top: 30px;
    border-radius: 10px;
    font-weight: 600;
  }

  .pdf-status.ant-alert {
    margin: -4px 0 18px;
    border-radius: 10px;
  }

  .pdf-status .ant-alert-content {
    flex: 1;
  }

  .pdf-status-content {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    width: 100%;
  }

  .pdf-status-content > span {
    color: #275c3c;
    font-weight: 600;
  }

  .pdf-status-content .ant-btn {
    flex: 0 0 auto;
    height: 30px;
    padding: 0 10px;
    color: #3157c8;
    background: #ffffff;
    border: 1px solid #cfe1d5;
    border-radius: 8px;
    font-weight: 600;
  }

  .pdf-form-section .ant-form-item {
    margin-bottom: 18px;
  }

  .pdf-form-section .ant-form-item:last-child {
    margin-bottom: 0;
  }

  .pdf-form-section .ant-form-item-label > label {
    color: #344054;
    font-size: 13px;
    font-weight: 600;
  }

  .pdf-form-section .ant-input,
  .pdf-form-section .ant-input-affix-wrapper,
  .pdf-form-section .ant-input-number {
    border-color: #dce2eb;
    border-radius: 11px;
  }

  .pdf-form-section input.ant-input,
  .pdf-form-section .ant-input-number {
    min-height: 43px;
  }

  .pdf-form-section .ant-input-number-input {
    height: 41px;
  }

  .pdf-form-section textarea.ant-input {
    min-height: 112px;
    padding: 11px 13px;
    resize: vertical;
  }

  @media (max-width: 640px) {
    .pdf-url-row {
      display: block;
    }

    .pdf-url-row .ant-btn {
      width: 100%;
      margin: -6px 0 18px;
    }

    .pdf-form-section {
      padding: 16px;
    }

  }
`;

type PDFFormValues = {
  pdf_url: string;
  pdf_title: string;
  pdf_description?: string;
  start_page: number;
};

const buildPDFUrlWithStartingPage = (url: string, startingPage: number) => {
  const urlWithoutFragment = url.split('#')[0];
  return `${urlWithoutFragment}#page=${Math.max(1, Math.floor(startingPage))}`;
};

const isPublicHttpUrl = (value: string) => {
  try {
    const parsedUrl = new URL(value);
    return parsedUrl.protocol === 'http:' || parsedUrl.protocol === 'https:';
  } catch (error) {
    return false;
  }
};

// Temporary client-side API. Replace this function with axios.post when the
// PDF endpoint is available; the modal and payload can remain unchanged.
const savePDFToDummyAPI = async (payload: any) => {
  await new Promise(resolve => window.setTimeout(resolve, 600));
  return {
    data: {
      id: `temporary-pdf-${Date.now()}`,
      ...payload,
    },
  };
};

export function PlaylistEditFormWidget(props: { formData? }) {
  const [form] = Form.useForm();
  const [pdfForm] = Form.useForm();
  const history = useHistory();
  const { t } = useTranslation();
  const [isAddYTModalVisible, setIsAddYTModalVisible] = useState(false);
  const [isAddPDFModalVisible, setIsAddPDFModalVisible] = useState(false);
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [isOptimizeModalVisible, setIsOptimizeModalVisible] = useState(false);
  const [isUpdating, setIsUpdating] = useState(false);
  const { playlist } = props.formData;
  const [items, setItems] = useState(props.formData.playlist_items || []);
  const dispatch = useDispatch();
  const path = window.location.pathname;
  const tempPlaylistName = path.substring(path.lastIndexOf('/') + 1);
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState<any[]>([]);
  const [modalStep, setModalStep] = useState<'search' | 'details'>('search');
  const [isSearching, setIsSearching] = useState(false);
  const [isSavingVideo, setIsSavingVideo] = useState(false);
  const [selectedVideoId, setSelectedVideoId] = useState<string | null>(null);
  const [selectedVideoThumbnail, setSelectedVideoThumbnail] = useState('');
  const [selectedVideoDurationSeconds, setSelectedVideoDurationSeconds] = useState(0);
  const [nextPageToken, setNextPageToken] = useState<string | null>(null);
  const [isLoadingMore, setIsLoadingMore] = useState(false);
  const [isValidatingPDF, setIsValidatingPDF] = useState(false);
  const [isPDFValidated, setIsPDFValidated] = useState(false);
  const [isSavingPDF, setIsSavingPDF] = useState(false);
  const [validatedPDFUrl, setValidatedPDFUrl] = useState('');



  const addYTvideo = () => {
    setSearchQuery('');
    setSearchResults([]);
    setNextPageToken(null);
    setSelectedVideoId(null);
    setSelectedVideoThumbnail('');
    setSelectedVideoDurationSeconds(0);
    setModalStep('search');
    form.resetFields();
    setIsAddYTModalVisible(true);
  };

  const closeYTModal = () => {
    setIsAddYTModalVisible(false);
    setSearchQuery('');
    setSearchResults([]);
    setNextPageToken(null);
    setSelectedVideoId(null);
    setSelectedVideoThumbnail('');
    setSelectedVideoDurationSeconds(0);
    setModalStep('search');
    form.resetFields();
  };

  const addPDF = () => {
    setIsPDFValidated(false);
    setValidatedPDFUrl('');
    pdfForm.resetFields();
    pdfForm.setFieldsValue({ start_page: 1 });
    setIsAddPDFModalVisible(true);
  };

  const closePDFModal = () => {
    setIsAddPDFModalVisible(false);
    setIsPDFValidated(false);
    setValidatedPDFUrl('');
    pdfForm.resetFields();
  };

  const YOUTUBE_API_KEY = 'AIzaSyD4x08r9s_7QZJih2MlpDF3BG7EPnau5bg';

  const getYouTubeVideoId = (url: string) => {
    const match = url.match(
      /(?:youtube\.com\/(?:.*[?&]v=|shorts\/|embed\/)|youtu\.be\/)([^&?/]+)/,
    );
    return match?.[1] || null;
  };

  const buildYouTubeUrlWithStartTime = (
    url: string,
    startFrom: number,
  ) => {
    const videoId = getYouTubeVideoId(url);
    if (!videoId) return url;

    const normalizedUrl = `https://www.youtube.com/watch?v=${videoId}`;
    return startFrom > 0
      ? `${normalizedUrl}&t=${Math.floor(startFrom)}s`
      : normalizedUrl;
  };

  const isoDurationToSeconds = (isoDuration: string) => {
    const match = isoDuration.match(/PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?/);
    if (!match) return 0;

    const hours = parseInt(match[1] || '0', 10);
    const minutes = parseInt(match[2] || '0', 10);
    const seconds = parseInt(match[3] || '0', 10);
    return hours * 3600 + minutes * 60 + seconds;
  };

  const formatSecondsAsTime = (totalSeconds: number) => {
    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const seconds = totalSeconds % 60;

    return hours > 0
      ? `${hours}:${minutes.toString().padStart(2, '0')}:${seconds
          .toString()
          .padStart(2, '0')}`
      : `${minutes}:${seconds.toString().padStart(2, '0')}`;
  };

  const populateVideoForm = async (videoId: string) => {
    const response = await axios.get(
      'https://www.googleapis.com/youtube/v3/videos',
      {
        params: {
          part: 'snippet,contentDetails',
          id: videoId,
          key: YOUTUBE_API_KEY,
        },
      },
    );

    const video = response.data.items?.[0];
    if (!video) {
      throw new Error('No video data found');
    }

    const { title, description, thumbnails, publishedAt } = video.snippet;
    const durationISO = video.contentDetails.duration;
    const thumbnail =
      thumbnails?.maxres?.url ||
      thumbnails?.high?.url ||
      thumbnails?.medium?.url ||
      thumbnails?.default?.url ||
      '';

    setSelectedVideoId(videoId);
    setSelectedVideoThumbnail(thumbnail);
    setSelectedVideoDurationSeconds(isoDurationToSeconds(durationISO));
    form.setFieldsValue({
      url: `https://www.youtube.com/watch?v=${videoId}`,
      title,
      description,
      thumbnail_url: thumbnail,
      date: publishedAt?.split('T')[0],
      duration: durationISO,
      start_from: 0,
    });
  };

  const handleUrlChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const url = e.target.value;
    form.setFieldsValue({ url });
    const videoId = getYouTubeVideoId(url);

    if (videoId) {
      try {
        await populateVideoForm(videoId);
      } catch (error) {
        console.error(error);
        message.error('Failed to fetch video data');
      }
    }
  };

  const formatISODuration = (isoDuration: string): string => {
    const matches = isoDuration.match(/PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?/);
    if (!matches) return '00:00:00';

    const hours = parseInt(matches[1] || '0', 10);
    const minutes = parseInt(matches[2] || '0', 10);
    const seconds = parseInt(matches[3] || '0', 10);
    const padded = (num: number) => num.toString().padStart(2, '0');
    return `${padded(hours)}:${padded(minutes)}:${padded(seconds)}`;
  };

  const saveYTVideo = async () => {
    try {
      const values = await form.validateFields();
      const startFrom = Number(values.start_from || 0);
      const payload = {
        url: buildYouTubeUrlWithStartTime(values.url, startFrom),
        title: values.title,
        description: values.description,
        thumbnail_url: values.thumbnail_url,
        date: values.date,
        duration: formatISODuration(values.duration),
        start_from: startFrom,
      };

      setIsSavingVideo(true);
      const response = await axios.post(
        `/api/v1/playlist/${tempPlaylistName}/yt_items`,
        payload,
        {
          headers: {
            'Content-Type': 'application/json',
          },
        }
      );
  
      const newItem = response.data;
      setItems(prevItems => [...prevItems, newItem]);

      message.success('YouTube video added successfully');
      closeYTModal();
      window.location.reload();
    } catch (error: any) {
      if (error.response) {
        console.error('Error response:', error.response);
      } else {
        console.error('Validation or request error:', error);
      }
      if (error?.errorFields) return;
      message.error('Failed to add YouTube video');
    } finally {
      setIsSavingVideo(false);
    }
  };

  const handleCardClick = async (item: any) => {
    try {
      const payload = {
        action_type_id: 1,
        params: JSON.stringify({ oerId: item.id }),
        is_bundled: false,
      };
      await fetch(`${process.env.REACT_APP_BASE_URL}/action/`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
        },
        body: JSON.stringify(payload),
        credentials: 'include',
      });

      console.log(`Action logged for item ID: ${item.id}`);
    } catch (err) {
      console.error('Failed to log action', err);
    }
  };


  const { data: licenseData, loading, error } = useSelector(
    (state: RootState) => {
      return state.playlistLicenses;
    },
  );

  useEffect(() => {
    if (!licenseData) {
      dispatch(fetchPlaylistLicensesThunk());
    }
  }, [licenseData, dispatch]);

  const showModal = () => {
    setIsModalVisible(true);
  };

  const onItemsReorder = async newOrder => {
    try {
      const oerIdsArray = newOrder.map(item => {
        return parseInt(item.data);
      });
      setIsUpdating(true);
      const updateOrderCall = (await dispatch(
        updateTempPlaylistThunk({
          ...playlist,
          temp_title: playlist.title,
          playlist_items: oerIdsArray,
        }),
      )) as any;
      const updateOrderResult = await unwrapResult(updateOrderCall);
      setIsUpdating(false);
      message.info(t('alerts.lbl_playlist_update_success'));
    } catch (e) {
      setIsUpdating(false);
      message.error(t('alerts.lbl_playlist_update_error'));
    }
  };

  const optimizeLearningPath = async () => {
    setIsOptimizeModalVisible(true);
  };

  const handleYTSearch = async (isLoadMore = false) => {
    if (!searchQuery.trim()) return;

    const encodedQuery = encodeURIComponent(searchQuery.trim());
    const pageParam =
      isLoadMore && nextPageToken ? `&pageToken=${nextPageToken}` : '';
    const url = `https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=9&q=${encodedQuery}${pageParam}&key=${YOUTUBE_API_KEY}`;

    try {
      if (isLoadMore) {
        setIsLoadingMore(true);
      } else {
        setIsSearching(true);
        setSearchResults([]);
        setNextPageToken(null);
      }

      const res = await fetch(url);
      const data = await res.json();

      if (!res.ok) {
        throw new Error(data?.error?.message || 'YouTube search failed');
      }

      const videos = Array.isArray(data.items) ? data.items : [];
      setSearchResults(prev => {
        const existingIds = new Set(prev.map(video => video.id.videoId));
        const newItems = videos.filter(
          video => !existingIds.has(video.id.videoId),
        );
        return isLoadMore ? [...prev, ...newItems] : newItems;
      });
      setNextPageToken(data.nextPageToken || null);
    } catch (err) {
      console.error('YouTube Search Error:', err);
      message.error('Unable to search YouTube. Please try again.');
    } finally {
      setIsSearching(false);
      setIsLoadingMore(false);
    }
  };

  const handleVideoSelect = async (videoId: string) => {
    try {
      await populateVideoForm(videoId);
      setModalStep('details');
    } catch (err) {
      console.error('Failed to fetch video details:', err);
      message.error('Unable to load this video. Please try another one.');
    }
  };

  const previewVideo = (videoId: string, startFrom = 0) => {
    Modal.info({
      title: 'Video Preview',
      width: 800,
      okText: 'Close',
      content: (
        <div
          style={{
            marginTop: 16,
            overflow: 'hidden',
            background: '#000000',
            borderRadius: 12,
            lineHeight: 0,
          }}
        >
          <iframe
            width="100%"
            height="400"
            src={`https://www.youtube.com/embed/${videoId}?autoplay=1&start=${Math.max(
              0,
              Math.floor(startFrom),
            )}`}
            title="YouTube video preview"
            frameBorder="0"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
            allowFullScreen
          />
        </div>
      ),
    });
  };

  const returnToSearch = () => {
    setModalStep('search');
    setSelectedVideoId(null);
    setSelectedVideoThumbnail('');
    setSelectedVideoDurationSeconds(0);
    form.resetFields();
  };

  const validatePDFUrl = async () => {
    try {
      const { pdf_url: pdfUrl } = await pdfForm.validateFields(['pdf_url']);

      if (!isPublicHttpUrl(pdfUrl)) {
        throw new Error('Enter a publicly accessible HTTP or HTTPS URL');
      }

      const parsedUrl = new URL(pdfUrl);
      const hasPDFExtension = /\.pdf$/i.test(parsedUrl.pathname);

      setIsValidatingPDF(true);

      let response: Response | null = null;
      try {
        response = await fetch(pdfUrl, { method: 'HEAD' });
      } catch (requestError) {
        // Some public S3 buckets permit viewing but block browser HEAD requests.
        // In that case, a URL whose path ends in .pdf can still be previewed.
        if (!hasPDFExtension) {
          throw requestError;
        }
      }

      if (response) {
        if (!response.ok) {
          throw new Error(`The PDF server returned ${response.status}`);
        }

        const contentType = (response.headers.get('content-type') || '')
          .split(';')[0]
          .trim()
          .toLowerCase();
        const isPDFContentType = contentType === 'application/pdf';
        const isGenericContentType =
          !contentType ||
          contentType === 'application/octet-stream' ||
          contentType === 'binary/octet-stream';

        if (!isPDFContentType && !(hasPDFExtension && isGenericContentType)) {
          throw new Error('The URL does not return a PDF document');
        }
      }

      setValidatedPDFUrl(pdfUrl);
      setIsPDFValidated(true);
      message.success('PDF link validated successfully');
      return true;
    } catch (error: any) {
      setValidatedPDFUrl('');
      setIsPDFValidated(false);

      if (!error?.errorFields) {
        message.error(error?.message || 'Unable to validate this PDF link');
      }
      return false;
    } finally {
      setIsValidatingPDF(false);
    }
  };

  const previewPDF = async () => {
    const isValid = isPDFValidated || (await validatePDFUrl());
    if (!isValid) return;

    try {
      const values = await pdfForm.validateFields(['pdf_url', 'start_page']);
      const previewUrl = buildPDFUrlWithStartingPage(
        values.pdf_url,
        Number(values.start_page),
      );

      Modal.info({
        title: 'PDF Preview',
        width: 960,
        okText: 'Close Preview',
        maskClosable: true,
        content: (
          <div
            style={{
              height: '70vh',
              marginTop: 16,
              overflow: 'hidden',
              background: '#f3f5f8',
              border: '1px solid #e1e6ee',
              borderRadius: 12,
            }}
          >
            <iframe
              src={previewUrl}
              title="PDF preview"
              style={{ width: '100%', height: '100%', border: 0 }}
            />
          </div>
        ),
      });
    } catch (error) {
      // Ant Design displays the relevant field validation messages.
    }
  };

  const savePDF = async () => {
    try {
      const values = (await pdfForm.validateFields()) as PDFFormValues;

      if (!isPDFValidated || validatedPDFUrl !== values.pdf_url) {
        const isValid = await validatePDFUrl();
        if (!isValid) return;
      }

      const startingPage = Math.floor(Number(values.start_page));
      const payload = {
        url: buildPDFUrlWithStartingPage(values.pdf_url, startingPage),
        title: values.pdf_title.trim(),
        description: values.pdf_description?.trim() || '',
        start_page: startingPage,
        mediatype: 'pdf',
        provider: 'X5Learn',
        playlist: tempPlaylistName,
      };

      setIsSavingPDF(true);
      const response = await savePDFToDummyAPI(payload);
      console.log('Dummy PDF API response:', response.data);
      message.success('PDF saved successfully (temporary API)');
      closePDFModal();
    } catch (error: any) {
      if (error?.errorFields) return;
      console.error('Unable to save PDF:', error);
      message.error('Unable to save the PDF');
    } finally {
      setIsSavingPDF(false);
    }
  };


  return (
    <Form
      {...layout}
      form={form}
      name="basic"
      initialValues={{ remember: true }}
    >
      <Row gutter={[16, 16]}>

        <StickyPlaylistActions span={24}>
          <Row justify="end">
            <Space>
              <Button
                type="primary"
                htmlType="button"
                size="large"
                icon={<PlusOutlined />}
                onClick={addYTvideo}
                disabled={isUpdating}
              >
                {t('Add youTube video to playlist')}
              </Button>

              <Button
                htmlType="button"
                size="large"
                icon={<FilePdfOutlined />}
                onClick={addPDF}
                disabled={isUpdating}
              >
                {t('Add PDF to playlist')}
              </Button>

              <Button
                type="primary"
                htmlType="button"
                size="large"
                onClick={showModal}
                disabled={isUpdating}
              >
                {t('playlist.lbl_publish_playlist')} <UploadOutlined />
              </Button>
            </Space>
          </Row>
        </StickyPlaylistActions>

        <Col span={24}>
          <PlaylistItemSortWidget
            playlist_items={items}
            onItemsReorder={onItemsReorder}
            isUpdating={isUpdating}
            tempPlaylistName={tempPlaylistName}
            onItemClick={handleCardClick}
          />
        </Col>
        <Col span={24}>
          <Form.Item {...tailLayout}>
            {/* <Button type="primary" htmlType="submit" size="large">
          Save <UploadOutlined />
        </Button> */}
            <Space wrap>
             {/* <Button
                type="primary"
                htmlType="button"
                size="large"
                onClick={optimizeLearningPath}
                disabled={isUpdating}
              >
                {t('playlist.btn_optimize_learning_path')}
              </Button>*/}

            </Space>
          </Form.Item>
        </Col>
      </Row>

      <>
        {isModalVisible && (
          <PlaylistPublishFormWidget
            visible={isModalVisible}
            setIsModalVisible={setIsModalVisible}
            formData={props.formData}
          />
        )}

        <Modal
          visible={isAddYTModalVisible}
          title={
            <YouTubeModalTitle>
              <strong>
                {modalStep === 'search'
                  ? t('Search YouTube Videos')
                  : t('YouTube Video Details')}
              </strong>
              <span>
                {modalStep === 'search'
                  ? 'Find and preview a video before selecting it.'
                  : 'Review the selected video and configure playback.'}
              </span>
            </YouTubeModalTitle>
          }
          onCancel={closeYTModal}
          width={modalStep === 'search' ? 1120 : 760}
          destroyOnClose
          footer={
            modalStep === 'search'
              ? [
                  <Button key="cancel" onClick={closeYTModal}>
                    Cancel
                  </Button>,
                ]
              : [
                  <Button key="cancel" onClick={closeYTModal}>
                    Cancel
                  </Button>,
                  <Button
                    key="add"
                    type="primary"
                    loading={isSavingVideo}
                    onClick={saveYTVideo}
                  >
                    Add Video
                  </Button>,
                ]
          }
        >
          <YouTubeModalContent>
            {modalStep === 'search' && (
              <>
                <div className="youtube-search-header">
                  <div className="youtube-search-heading">
                    <h3>Find a video</h3>
                    <p>
                      Search YouTube, preview any result, then select the video
                      you want to add.
                    </p>
                  </div>

                  <div className="youtube-search-bar">
                    <Input
                      className="youtube-search-input"
                      size="large"
                      allowClear
                      prefix={<SearchOutlined />}
                      placeholder="Search YouTube videos"
                      value={searchQuery}
                      onChange={event => {
                        const value = event.target.value;
                        setSearchQuery(value);
                        if (!value) {
                          setSearchResults([]);
                          setNextPageToken(null);
                        }
                      }}
                      onPressEnter={() => handleYTSearch(false)}
                    />
                    <Button
                      className="youtube-search-button"
                      type="primary"
                      size="large"
                      icon={<SearchOutlined />}
                      loading={isSearching}
                      disabled={!searchQuery.trim()}
                      onClick={() => handleYTSearch(false)}
                    >
                      Search
                    </Button>
                  </div>
                </div>

                {searchResults.length > 0 ? (
                  <div className="youtube-results">
                    <div className="youtube-results-heading">
                      <strong>Search results</strong>
                      <span>
                        {searchResults.length}{' '}
                        {searchResults.length === 1 ? 'video' : 'videos'}
                      </span>
                    </div>
                    <Row gutter={[16, 16]}>
                      {searchResults.map(video => {
                        const { videoId } = video.id;
                        const { title, thumbnails, channelTitle } =
                          video.snippet;
                        const thumbnail =
                          thumbnails?.high?.url ||
                          thumbnails?.medium?.url ||
                          thumbnails?.default?.url;

                        return (
                          <Col xs={24} sm={12} lg={8} key={videoId}>
                            <Card
                              className="youtube-result-card"
                              hoverable
                              cover={
                                <button
                                  type="button"
                                  className="youtube-result-thumbnail"
                                  aria-label={`Preview ${title}`}
                                  onClick={event => {
                                    event.stopPropagation();
                                    previewVideo(videoId);
                                  }}
                                >
                                  <img src={thumbnail} alt={title} />
                                  <span className="youtube-thumbnail-overlay">
                                    <PlayCircleOutlined />
                                    <span>Preview video</span>
                                  </span>
                                </button>
                              }
                              onClick={() => handleVideoSelect(videoId)}
                            >
                              <div className="youtube-result-title" title={title}>
                                {title}
                              </div>
                              <span
                                className="youtube-result-channel"
                                title={channelTitle}
                              >
                                {channelTitle}
                              </span>
                              <Button
                                className="youtube-select-button"
                                type="primary"
                                onClick={event => {
                                  event.stopPropagation();
                                  handleVideoSelect(videoId);
                                }}
                              >
                                Select Video
                              </Button>
                            </Card>
                          </Col>
                        );
                      })}
                    </Row>

                    {nextPageToken && (
                      <div className="youtube-load-more">
                        <Button
                          loading={isLoadingMore}
                          onClick={() => handleYTSearch(true)}
                        >
                          Load More
                        </Button>
                      </div>
                    )}
                  </div>
                ) : (
                  <div className="youtube-empty-state">
                    <SearchOutlined />
                    <strong>
                      {isSearching
                        ? 'Searching YouTube…'
                        : 'Search for a YouTube video'}
                    </strong>
                    <span>
                      Results will appear here and can be previewed before
                      selection.
                    </span>
                  </div>
                )}
              </>
            )}

            {modalStep === 'details' && (
              <div className="youtube-details">
                <Button
                  className="youtube-back-button"
                  type="link"
                  icon={<ArrowLeftOutlined />}
                  onClick={returnToSearch}
                >
                  Back to Search
                </Button>

                {/* <div className="youtube-details-intro">
                  <strong>Video selected</strong>
                  <span>
                    Review the video information and choose where playback
                    should begin.
                  </span>
                </div> */}

                <section className="youtube-form-section">
                  {/* <div className="youtube-section-heading">
                    <h4>Video source</h4>
                    <p>Confirm the YouTube link and thumbnail.</p>
                  </div> */}

                  <Form.Item
                    name="url"
                    label="YouTube URL"
                    rules={[
                      { required: true, message: 'Please input the video URL' },
                    ]}
                  >
                    <Input onChange={handleUrlChange} />
                  </Form.Item>

                  {selectedVideoThumbnail && selectedVideoId && (
                    <button
                      type="button"
                      className="youtube-selected-preview"
                      aria-label="Preview selected video"
                      onClick={() =>
                        previewVideo(
                          selectedVideoId,
                          Number(form.getFieldValue('start_from') || 0),
                        )
                      }
                    >
                      <img
                        src={selectedVideoThumbnail}
                        alt="Selected YouTube video thumbnail"
                      />
                      <span className="youtube-thumbnail-overlay">
                        <PlayCircleOutlined />
                        <span>Play preview</span>
                      </span>
                    </button>
                  )}

                  {/* <Form.Item name="thumbnail_url" label="Thumbnail URL">
                    <Input
                      onChange={event =>
                        setSelectedVideoThumbnail(event.target.value)
                      }
                    />
                  </Form.Item> */}
                </section>

                <section className="youtube-form-section">
                  <div className="youtube-section-heading">
                    <h4>Video information</h4>
                    <p>Edit the title, description, and upload date.</p>
                  </div>

                  <Form.Item
                    name="title"
                    label="Title"
                    rules={[
                      { required: true, message: 'Please enter a title' },
                    ]}
                  >
                    <Input />
                  </Form.Item>

                  <Form.Item name="description" label="Description">
                    <TextArea rows={4} />
                  </Form.Item>

                  <Form.Item name="date" label="Upload Date">
                    <Input placeholder="e.g., 2019-10-07" />
                  </Form.Item>
                </section>

                <section className="youtube-form-section">
                  <div className="youtube-section-heading">
                    <h4>Playback settings</h4>
                    <p>Choose the point where the video should begin.</p>
                  </div>

                  <Form.Item
                    name="start_from"
                    label="Start From (seconds)"
                    extra={`Video length: ${formatSecondsAsTime(
                      selectedVideoDurationSeconds,
                    )}`}
                    rules={[
                      {
                        required: true,
                        message: 'Please enter the starting time',
                      },
                      {
                        validator: (_, value) => {
                          const startFrom = Number(value);

                          if (!Number.isFinite(startFrom) || startFrom < 0) {
                            return Promise.reject(
                              new Error('Starting time must be 0 or greater'),
                            );
                          }

                          if (startFrom > selectedVideoDurationSeconds) {
                            return Promise.reject(
                              new Error(
                                `Starting time cannot exceed ${selectedVideoDurationSeconds} seconds`,
                              ),
                            );
                          }

                          return Promise.resolve();
                        },
                      },
                    ]}
                  >
                    <InputNumber
                      min={0}
                      precision={0}
                      style={{ width: '100%' }}
                    />
                  </Form.Item>
                </section>

                <Form.Item name="duration" style={{ display: 'none' }}>
                  <Input />
                </Form.Item>
              </div>
            )}
          </YouTubeModalContent>
        </Modal>

        <Modal
          visible={isAddPDFModalVisible}
          title={
            <YouTubeModalTitle>
              <strong>{t('Add PDF')}</strong>
              <span>
                Add a publicly accessible PDF link, including an S3 URL.
              </span>
            </YouTubeModalTitle>
          }
          onCancel={closePDFModal}
          width={780}
          destroyOnClose
          footer={[
            <Button key="cancel" onClick={closePDFModal}>
              Cancel
            </Button>,
            <Button
              key="preview"
              icon={<EyeOutlined />}
              disabled={!isPDFValidated}
              onClick={previewPDF}
            >
              Preview PDF
            </Button>,
            <Button
              key="save"
              type="primary"
              icon={<PlusOutlined />}
              loading={isSavingPDF}
              disabled={!isPDFValidated}
              onClick={savePDF}
            >
              Add PDF
            </Button>,
          ]}
        >
          <PDFModalContent>
            <div className="pdf-intro">
              <FilePdfOutlined />
              <div>
                <strong>Link a PDF from the web</strong>
                <span>
                  The document must be publicly accessible. Signed or public
                  S3 links are supported when the browser is allowed to read
                  them.
                </span>
              </div>
            </div>

            <Form
              form={pdfForm}
              layout="vertical"
              initialValues={{ start_page: 1 }}
            >
              <section className="pdf-form-section">
                <div className="pdf-section-heading">
                  <h4>PDF source</h4>
                  <p>Paste and validate the public document URL.</p>
                </div>

                <div className="pdf-url-row">
                  <Form.Item
                    className="pdf-url-field"
                    name="pdf_url"
                    label="Public PDF URL"
                    rules={[
                      {
                        required: true,
                        message: 'Please enter a PDF URL',
                      },
                      {
                        validator: (_, value) =>
                          !value || isPublicHttpUrl(value)
                            ? Promise.resolve()
                            : Promise.reject(
                                new Error('Enter a valid HTTP or HTTPS URL'),
                              ),
                      },
                    ]}
                  >
                    <Input
                      allowClear
                      prefix={<LinkOutlined />}
                      placeholder="https://example.com/document.pdf"
                      onChange={() => {
                        setIsPDFValidated(false);
                        setValidatedPDFUrl('');
                      }}
                    />
                  </Form.Item>

                  <Button
                    type="primary"
                    icon={<CheckCircleOutlined />}
                    loading={isValidatingPDF}
                    onClick={validatePDFUrl}
                  >
                    Validate PDF
                  </Button>
                </div>

                {isPDFValidated && (
                  <Alert
                    className="pdf-status"
                    type="success"
                    showIcon
                    message={
                      <div className="pdf-status-content">
                        <span>PDF link validated</span>
                        <Button
                          size="small"
                          icon={<EyeOutlined />}
                          onClick={previewPDF}
                        >
                          Preview PDF
                        </Button>
                      </div>
                    }
                  />
                )}
              </section>

              <section className="pdf-form-section">
                <div className="pdf-section-heading">
                  <h4>Document information</h4>
                  <p>Add the title and an optional description.</p>
                </div>

                <Form.Item
                  name="pdf_title"
                  label="Title"
                  rules={[
                    { required: true, message: 'Please enter a PDF title' },
                    {
                      whitespace: true,
                      message: 'The title cannot be empty',
                    },
                  ]}
                >
                  <Input placeholder="Enter a clear document title" />
                </Form.Item>

                <Form.Item name="pdf_description" label="Description">
                  <TextArea
                    rows={4}
                    placeholder="Describe what this PDF contains (optional)"
                  />
                </Form.Item>
              </section>

              <section className="pdf-form-section">
                <div className="pdf-section-heading">
                  <h4>Reading settings</h4>
                  <p>Choose the page that should open first.</p>
                </div>

                <Form.Item
                  name="start_page"
                  label="Starting page"
                  extra="Use a whole page number starting from 1."
                  rules={[
                    {
                      required: true,
                      message: 'Please enter the starting page',
                    },
                    {
                      validator: (_, value) => {
                        const startingPage = Number(value);
                        return Number.isInteger(startingPage) && startingPage >= 1
                          ? Promise.resolve()
                          : Promise.reject(
                              new Error(
                                'Starting page must be a whole number of 1 or greater',
                              ),
                            );
                      },
                    },
                  ]}
                >
                  <InputNumber
                    min={1}
                    precision={0}
                    style={{ width: '100%' }}
                  />
                </Form.Item>
              </section>
            </Form>
          </PDFModalContent>
        </Modal>
        
        {isOptimizeModalVisible && (
          <PlaylistOptimizeConfirmationWidget
            visible={isOptimizeModalVisible}
            setIsModalVisible={setIsOptimizeModalVisible}
            formData={props.formData}
          />
        )}
      </>
    </Form>
  );
  
}
