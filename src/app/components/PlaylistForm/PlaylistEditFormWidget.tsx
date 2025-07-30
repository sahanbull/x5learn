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
  Select,
  Modal,
  message,
  Space,
} from 'antd';
import { AppLayout } from 'app/containers/Layout/AppLayout';
import { DeleteOutlined, UploadOutlined ,PlusOutlined} from '@ant-design/icons';
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
import { PlayCircleOutlined } from '@ant-design/icons';
import { Tooltip } from 'antd';

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

export function PlaylistEditFormWidget(props: { formData? }) {
  const [form] = Form.useForm();
  const history = useHistory();
  const { t } = useTranslation();
  const [isAddYTModalVisible, setIsAddYTModalVisible] = useState(false);
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [isOptimizeModalVisible, setIsOptimizeModalVisible] = useState(false);
  const [isUpdating, setIsUpdating] = useState(false);
  const { playlist } = props.formData;
  const [items, setItems] = useState(props.formData.playlist_items || []);
  const dispatch = useDispatch();
  const path = window.location.pathname;
  const tempPlaylistName = path.substring(path.lastIndexOf('/') + 1);
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState([]);
  const [showSearchBtn, setShowSearchBtn] = useState(false);
  const [hoveredVideo, setHoveredVideo] = useState<string | null>(null);
  const [selectedVideoId, setSelectedVideoId] = useState<string | null>(null);
  const [nextPageToken, setNextPageToken] = useState<string | null>(null);
const [isLoadingMore, setIsLoadingMore] = useState(false);



  const addYTvideo = () => {
    setIsAddYTModalVisible(true);
     setSearchQuery('');
    setSearchResults([]);
    setNextPageToken(null);
    setSelectedVideoId(null);
    form.resetFields();
    setIsAddYTModalVisible(true);
  };

  const YOUTUBE_API_KEY = 'AIzaSyCuzC9mi7rmUDIRTQamTWmNnkRfyY2Dt90';
  const handleUrlChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const url = e.target.value;
    form.setFieldsValue({ url }); // set URL immediately
    const videoIdMatch = url.match(
      /(?:youtube\.com\/.*v=|youtu\.be\/)([^&?/]+)/
    );
    if (videoIdMatch && videoIdMatch[1]) {
      const videoId = videoIdMatch[1];

      try {
        const response = await axios.get(
          `https://www.googleapis.com/youtube/v3/videos`,
          {
            params: {
              part: 'snippet,contentDetails',
              id: videoId,
              key: YOUTUBE_API_KEY,
            },
          }
        );

        const video = response.data.items[0];
        if (video) {
          const snippet = video.snippet;
          const duration = video.contentDetails.duration; // ISO 8601 format

          form.setFieldsValue({
            title: snippet.title,
            description: snippet.description,
            thumbnail_url: snippet.thumbnails?.default?.url,
            date: snippet.publishedAt?.split('T')[0], // e.g., 2023-10-05
            duration: duration, // You can parse ISO duration to HH:MM:SS if needed
          });
        } else {
          message.error('No video data found for this URL');
        }
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
      const payload = {
        url: values.url,
        title: values.title,
        description: values.description,
        thumbnail_url: values.thumbnail_url,
        date: values.date,
        duration: formatISODuration(values.duration),
      };
  
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
      setIsAddYTModalVisible(false);
      form.resetFields();
      window.location.reload();
    } catch (error: any) {
      if (error.response) {
        console.error('Error response:', error.response);
      } else {
        console.error('Validation or request error:', error);
      }
      message.error('Failed to add YouTube video');
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

  const API_KEY = YOUTUBE_API_KEY;
  const encodedQuery = encodeURIComponent(searchQuery);
  const pageParam = isLoadMore && nextPageToken ? `&pageToken=${nextPageToken}` : '';
  const url = `https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=8&q=${encodedQuery}${pageParam}&key=${API_KEY}`;

  try {
    if (!isLoadMore) {
      setSearchResults([]); // clear old results before new search
      setNextPageToken(null); // reset pagination
    }

    const res = await fetch(url);
    const data = await res.json();

  setSearchResults((prev) => {
    const existingIds = new Set(prev.map(v => v.id.videoId));
    const newItems = data.items.filter(v => !existingIds.has(v.id.videoId));
    return isLoadMore ? [...prev, ...newItems] : newItems;
  });
    setNextPageToken(data.nextPageToken || null);
  } catch (err) {
    console.error('YouTube Search Error:', err);
  }
};

  const handleVideoSelect = async (videoId: string) => {
  if (selectedVideoId === videoId) {
    // Remove selected video
    setSelectedVideoId(null);
    form.resetFields();
    return;
  }

  const API_KEY = YOUTUBE_API_KEY;
  const url = `https://www.googleapis.com/youtube/v3/videos?part=snippet,contentDetails&id=${videoId}&key=${API_KEY}`;

  try {
    const res = await fetch(url);
    const data = await res.json();
    const video = data.items[0];

    if (video) {
      const { title, description, thumbnails, publishedAt } = video.snippet;
      const durationISO = video.contentDetails.duration;
      const duration = parseISODuration(durationISO);

      form.setFieldsValue({
        url: `https://www.youtube.com/watch?v=${videoId}`,
        title,
        description,
        thumbnail_url: thumbnails.medium.url,
        date: publishedAt.slice(0, 10),
       duration: durationISO,
      });

      setSelectedVideoId(videoId); // Mark as selected
      message.success('Video added!');
    }
  } catch (err) {
    console.error('Failed to fetch video details:', err);
  }
};
 
const parseISODuration = (iso) => {
  const match = iso.match(/PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?/);
  const [, hours, minutes, seconds] = match.map((v) => parseInt(v || '0', 10));
  const totalMinutes = hours * 60 + minutes;
  return `${totalMinutes}:${seconds.toString().padStart(2, '0')}`;
};

const previewVideo = (videoId) => {
  Modal.info({
    title: 'Video Preview',
    width: 800,
    content: (
      <iframe
        width="100%"
        height="400"
        src={`https://www.youtube.com/embed/${videoId}`}
        frameBorder="0"
        allowFullScreen
      />
    ),
  });
};


  return (
    <Form
      {...layout}
      form={form}
      name="basic"
      initialValues={{ remember: true }}
    >
      <Row gutter={[16, 16]}>

    <Col span={24}>
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
        </Col>

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
          title={t('Add YouTube Video')}
          onCancel={() => setIsAddYTModalVisible(false)}
          onOk={() => {saveYTVideo();}}
          okText="Add Video"
           width={1500}
        >
          
          <Form layout="vertical" form={form}>


            {/* Search Input */}
                <Form.Item label="Search in YouTube">
                  <Input
                    placeholder="Search for a video"
                    value={searchQuery}
                    onChange={(e) => {
                      const value = e.target.value;
                      setSearchQuery(value);
                      setShowSearchBtn(!!value);
                      if (!value) {
                        setSearchResults([]); // clear when input is cleared
                        setNextPageToken(null);
                      }
                    }}
                    onPressEnter={() => handleYTSearch(false)}
                  />
                  {showSearchBtn && (
                    <Button
                      onClick={() => handleYTSearch(false)}  // Pass false explicitly
                      style={{ marginTop: '8px' }}
                    >
                      Search
                    </Button>
                  )}
                </Form.Item>

                {/* Search Results */}
               <Row gutter={[16, 16]}>
                  {searchResults.map((video) => {
                    const { videoId } = video.id;
                    const { title, description, thumbnails } = video.snippet;
                    const isSelected = selectedVideoId === videoId;

                    return (
                      <Col xs={24} sm={12} md={8} lg={8} xl={6} key={videoId}>
                        <Card
                          hoverable
                          style={{
                            border: isSelected ? '2px solid #1890ff' : '1px solid #f0f0f0',
                            borderRadius: '8px',
                            overflow: 'hidden',
                            height: '100%',
                          }}
                          cover={
                            <div style={{ position: 'relative' }}>
                              <img
                                src={thumbnails.medium.url}
                                alt="thumbnail"
                                style={{ width: '100%', height: '150px', objectFit: 'cover', cursor: 'pointer' }}
                                onClick={() => previewVideo(videoId)}
                              />
                              <Button
                                type="primary"
                                shape="circle"
                                icon={<PlayCircleOutlined />}
                                size="small"
                                onClick={() => previewVideo(videoId)}
                                style={{
                                  position: 'absolute',
                                  top: '50%',
                                  left: '50%',
                                  transform: 'translate(-50%, -50%)',
                                  background: 'rgba(0,0,0,0.6)',
                                  border: 'none',
                                }}
                              />
                            </div>
                          }
                          actions={[
                            isSelected ? (
                              <Tooltip title="Remove Video">
                                <Button
                                  type="text"
                                  danger
                                  icon="✖"
                                  onClick={() => handleVideoSelect(videoId)}
                                />
                              </Tooltip>
                            ) : (
                              <Tooltip title="Add Video">
                                <Button
                                  shape="circle"
                                  icon={<PlusOutlined />}
                                  onClick={() => handleVideoSelect(videoId)}
                                />
                              </Tooltip>
                            ),
                          ]}
                        >
                          <Card.Meta
                            title={<div style={{ fontSize: '14px', fontWeight: 600 }}>{title}</div>}
                            description={
                              <div
                                style={{
                                  fontSize: '12px',
                                  color: '#555',
                                  maxHeight: '3em',
                                  overflow: 'hidden',
                                  textOverflow: 'ellipsis',
                                }}
                                title={description}
                              >
                                {description}
                              </div>
                            }
                          />
                        </Card>
                      </Col>
                    );
                  })}
                </Row>

                {nextPageToken && (
                  <div style={{ textAlign: 'center', marginTop: '16px' }}>
                    <Button
                      loading={isLoadingMore}
                      onClick={async () => {
                        setIsLoadingMore(true);
                        await handleYTSearch(true); // load more flag
                        setIsLoadingMore(false);
                      }}
                    >
                      Load More
                    </Button>
                  </div>
                )}



            <Form.Item
              name="url"
              label="YouTube URL"
              rules={[{ required: true, message: 'Please input the video URL' }]}
            >
              <Input onChange={handleUrlChange} />
         </Form.Item>
            <Form.Item name="title" label="Title">
              <Input />
            </Form.Item>
            <Form.Item name="description" label="Description">
              <TextArea rows={3} />
            </Form.Item>
            <Form.Item name="thumbnail_url" label="Thumbnail URL">
              <Input />
            </Form.Item>
            <Form.Item name="date" label="Upload Date">
              <Input placeholder="e.g., 2019-10-07" />
            </Form.Item>
            <Form.Item name="duration" label="Duration" style={{ display: 'none' }}>
            <Input />
          </Form.Item>
          </Form>
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
