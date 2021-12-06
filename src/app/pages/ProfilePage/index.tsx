import React, { useEffect, useState } from 'react';
import { Helmet } from 'react-helmet-async';
import { Button } from 'antd';
import { AppLayout } from 'app/containers/Layout/AppLayout';
import { useInjectReducer } from 'redux-injectors';
import { useDispatch, useSelector } from 'react-redux';
import {
  sliceKey as loggedInUserDetailsSliceKey,
  reducer as loggedInUserDetailsReducer,
  fetchLoggedInUserDetailsThunk,
} from 'app/containers/Layout/ducks/loggedInUserDetailsSlice';
import { useTranslation } from 'react-i18next';
import { Image } from 'antd';
import { Form, Input, Switch, Typography } from 'antd';
import {
  updateProfileThunk,
  sliceKey as updateProfileSliceKey,
  reducer as updateProfileReducer,
} from './ducks/ProfilePageSlice';

const { Text } = Typography;

export function ProfilePage() {
  const dispatch = useDispatch();

  useInjectReducer({
    key: loggedInUserDetailsSliceKey,
    reducer: loggedInUserDetailsReducer,
  });
  useInjectReducer({
    key: updateProfileSliceKey,
    reducer: updateProfileReducer,
  });

  const loggedInUser = useSelector(
    state => state[loggedInUserDetailsSliceKey].loggedInUser,
  );
  const isSaving = useSelector(state => state[updateProfileSliceKey].loading);
  const error = useSelector(state => state[updateProfileSliceKey].error);

  const [initialValues, setInitialValues] = useState({
    isDataCollectionConsent: false,
    firstName: '',
    lastName: '',
    loaded: false,
  });
  const [isDirty, setIsDirty] = useState(false);

  useEffect(() => {
    if (loggedInUser && loggedInUser.userProfile) {
      setInitialValues({
        isDataCollectionConsent:
          loggedInUser.userProfile.isDataCollectionConsent,
        firstName: loggedInUser.userProfile.firstName,
        lastName: loggedInUser.userProfile.lastName,
        loaded: true,
      });
    }
  }, [loggedInUser]);

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
  const { t } = useTranslation();

  const onFinish = async (values: any) => {
    values.email = loggedInUser.userProfile.email;
    await dispatch(updateProfileThunk(values));
    await dispatch(fetchLoggedInUserDetailsThunk());
    setIsDirty(false);
  };

  return (
    <>
      <Helmet>
        <title>{fullName}</title>
      </Helmet>
      <AppLayout className="profile-page">
        <div style={{ padding: '25px' }}>
          <h2>My profile</h2>
          <div style={{ display: 'flex', alignItems: 'center' }}>
            <Image
              width={150}
              src="https://www.kindpng.com/picc/m/24-248253_user-profile-default-image-png-clipart-png-download.png"
            />
            <div style={{ marginLeft: '25px' }}>
              <h3>{fullName}</h3>
              {loggedInUser && loggedInUser.userProfile && (
                <p>{loggedInUser.userProfile.email}</p>
              )}
            </div>
          </div>
          {initialValues && initialValues.loaded && (
            <div style={{ marginTop: '25px' }}>
              <Form
                name="profileDetails"
                initialValues={initialValues}
                onFinish={onFinish}
                onValuesChange={() => setIsDirty(true)}
                wrapperCol={{ span: 16 }}
                autoComplete="off"
              >
                <Form.Item
                  label="First Name"
                  name="firstName"
                  rules={[
                    {
                      required: true,
                      message: 'Please input your first name!',
                    },
                  ]}
                >
                  <Input />
                </Form.Item>

                <Form.Item
                  label="Last Name"
                  name="lastName"
                  rules={[
                    { required: true, message: 'Please input your last name!' },
                  ]}
                >
                  <Input />
                </Form.Item>

                <Form.Item
                  name="isDataCollectionConsent"
                  valuePropName="checked"
                  label="Allow X5GON to collect data about my activity on this site for research"
                >
                  <Switch />
                </Form.Item>
                {!isDirty && error && (
                  <Text type="danger">
                    Something went wrong. Please try again.
                  </Text>
                )}
                <Form.Item>
                  <Button
                    type="primary"
                    htmlType="submit"
                    disabled={!isDirty || isSaving}
                    loading={isSaving}
                  >
                    Save
                  </Button>
                </Form.Item>
              </Form>
            </div>
          )}
        </div>
      </AppLayout>
    </>
  );
}
