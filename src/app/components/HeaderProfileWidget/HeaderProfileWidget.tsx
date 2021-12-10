
import React from 'react';
import { useSelector } from 'react-redux';
import { Button, Popover, Image, Typography } from 'antd';
import { sliceKey as loggedInUserDetailsSliceKey } from 'app/containers/Layout/ducks/loggedInUserDetailsSlice';
import { Link } from 'react-router-dom';

const { Text } = Typography;

export function HeaderProfileWidget(props) {
  const loggedInUser = useSelector(
    state => state[loggedInUserDetailsSliceKey].loggedInUser,
  );
  let fullName = 'Please add your name';
  if (
    loggedInUser &&
    loggedInUser.userProfile &&
    (loggedInUser.userProfile.firstName || loggedInUser.userProfile.lastName)
  ) {
    fullName = `${loggedInUser.userProfile.firstName || ''} ${
      loggedInUser.userProfile.lastName || ''
    }`;
  }
  return (
    <>
      <Popover
        placement="bottomLeft"
        title={
          <>
            <Text strong>{fullName}</Text>
            <br />
            <Text>
              {loggedInUser && loggedInUser.userProfile
                ? loggedInUser.userProfile.email
                : ''}
            </Text>
          </>
        }
        content={
          <>
            <Link to="/profile">My Profile</Link>
            <br />
            <Link to="/logout">Logout</Link>
          </>
        }
        trigger="click"
      >
        <Button
          style={{ alignItems: 'stretch' }}
          size="large"
          icon={
            <Image preview={false} width={40} src="/static/favicon.ico"></Image>
          }
        />
      </Popover>
    </>
  );
}
