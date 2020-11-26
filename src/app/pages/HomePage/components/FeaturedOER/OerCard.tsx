import React, { ReactComponentElement, ReactElement } from 'react';
import { Card, Skeleton, Typography } from 'antd';
import Avatar from 'antd/lib/avatar/avatar';
import Meta from 'antd/lib/card/Meta';
import styled from 'styled-components';

const { Text } = Typography;

interface OerDao {
  date?: string;
  description?: string;
  duration?: string;
  durationInSeconds: number;
  id: number;
  images: string[];
  material_id: string;
  mediatype: 'video' | 'audio' | 'pdf';
  provider: string;
  title: string;
  url: string;
}

const imageBaseURL = 'https://qa.x5learn.org/files/thumbs/';

const MusicIconSVG = () => (
  <svg
    className="anticon"
    width="1.25em"
    height="1.25em"
    viewBox="0 0 1024 1024"
  >
    <path
      d="M923.733333 95.573333a42.666667 42.666667 0 0 0-34.133333-9.813333l-554.666667 85.333333A42.666667 42.666667 0 0 0 298.666667 213.333333v441.6A147.2 147.2 0 0 0 234.666667 640 149.333333 149.333333 0 1 0 384 789.333333v-325.973333l469.333333-72.106667v178.346667a147.2 147.2 0 0 0-64-14.933333 149.333333 149.333333 0 1 0 149.333334 149.333333V128a42.666667 42.666667 0 0 0-14.933334-32.426667zM234.666667 853.333333A64 64 0 1 1 298.666667 789.333333 64 64 0 0 1 234.666667 853.333333z m554.666666-85.333333a64 64 0 1 1 64-64 64 64 0 0 1-64 64zM853.333333 304.64L384 376.746667v-128l469.333333-70.826667z"
      p-id="2194"
    ></path>
  </svg>
);

const DocumentIconSVG = () => (
  <svg
    className="anticon"
    width="1.25em"
    height="1.25em"
    viewBox="0 0 1024 1024"
  >
    <path
      d="M224 831.936V192.096L223.808 192H576v159.936c0 35.328 28.736 64.064 64.064 64.064h159.712c0.032 0.512 0.224 1.184 0.224 1.664L800.256 832 224 831.936zM757.664 352L640 351.936V224.128L757.664 352z m76.064-11.872l-163.872-178.08C651.712 142.336 619.264 128 592.672 128H223.808A64.032 64.032 0 0 0 160 192.096v639.84A64 64 0 0 0 223.744 896h576.512A64 64 0 0 0 864 831.872V417.664c0-25.856-12.736-58.464-30.272-77.536zM640 512h-256a32 32 0 0 0 0 64h256a32 32 0 0 0 0-64M640 672h-256a32 32 0 0 0 0 64h256a32 32 0 0 0 0-64"
      p-id="9959"
    ></path>
  </svg>
);

const VideoIconSVG = () => (
  <svg
    className="anticon"
    width="1.25em"
    height="1.25em"
    viewBox="0 0 1024 1024"
  >
    <path
      d="M918.613333 305.066667a42.666667 42.666667 0 0 0-42.666666 0L725.333333 379.306667A128 128 0 0 0 597.333333 256H213.333333a128 128 0 0 0-128 128v256a128 128 0 0 0 128 128h384a128 128 0 0 0 128-123.306667l151.893334 75.946667A42.666667 42.666667 0 0 0 896 725.333333a42.666667 42.666667 0 0 0 22.613333-6.4A42.666667 42.666667 0 0 0 938.666667 682.666667V341.333333a42.666667 42.666667 0 0 0-20.053334-36.266666zM640 640a42.666667 42.666667 0 0 1-42.666667 42.666667H213.333333a42.666667 42.666667 0 0 1-42.666666-42.666667V384a42.666667 42.666667 0 0 1 42.666666-42.666667h384a42.666667 42.666667 0 0 1 42.666667 42.666667z m213.333333-26.453333l-128-64v-75.093334l128-64z"
      p-id="18161"
    ></path>
  </svg>
);

const Duration = styled.span`
  padding: 0px 6px 2px 6px;
  border-radius: 4px;
  background-color: #000d32;
  font-size: 12px;
  font-weight: 600;
  font-stretch: normal;
  font-style: normal;
  line-height: 1.33;
  letter-spacing: 0.3px;
  text-align: center;
  color: #ffffff;
  position: absolute;
  top: 8px;
  right: 8px;
`;

export function OerCard(props: { loading?: boolean; card?: OerDao }) {
  const { loading, card } = props;
  if (loading) {
    return (
      <Card>
        <Skeleton active></Skeleton>
      </Card>
    );
  }

  let icon = <DocumentIconSVG />;

  switch (card?.mediatype) {
    case 'audio':
      icon = <MusicIconSVG />;
      break;
    case 'pdf':
      icon = <DocumentIconSVG />;
      break;
    case 'video':
      icon = <VideoIconSVG />;
      break;
  }

  return (
    <Card
      hoverable
      bordered={false}
      cover={<img alt="example" src={`${imageBaseURL}/${card?.images[0]}`} />}
    >
      <Meta
        avatar={
          <Avatar
            shape="circle"
            size={32}
            icon={icon}
            style={{ borderRadius: '50%', backgroundColor: '#f7f8f9' }}
          />
        }
        title={card?.title}
        description={
          <>
            <Text strong>By: </Text>
            {card?.provider}
            <br />
            <Text strong>Type: </Text>
            {card?.mediatype}
            <br />
            <Text strong>Date: </Text>
            {card?.date}
          </>
        }
      />
      <Duration>{card?.duration}</Duration>
    </Card>
  );
}
