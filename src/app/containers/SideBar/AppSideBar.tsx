import React, { useState } from 'react';
import {
  Layout,
  Menu,
  Breadcrumb,
  Space,
  Row,
  Col,
  Typography,
  Button,
} from 'antd';
import Icon, {
  MailOutlined,
  AppstoreOutlined,
  SettingOutlined,
} from '@ant-design/icons';
import './AppSideBar.less';

const { SubMenu } = Menu;
const { Header, Content, Sider } = Layout;
const { Text } = Typography;

function X5MenuTitle(props) {
  return (
    <>
      <Row justify="space-between" align="middle">
        <Col>
          <strong> {props.children}</strong>
        </Col>
        <Col>{props.icon}</Col>
      </Row>
    </>
  );
}

const PlayListSVG = () => (
  <svg
    className="anticon"
    width="1.25em"
    height="1.25em"
    viewBox="0 0 1024 1024"
  >
    <path
      d="M938.666667 768v85.333333H85.333333v-85.333333h853.333334zM85.333333 149.333333l341.333334 213.333334-341.333334 213.333333v-426.666667zM938.666667 469.333333v85.333334H512v-85.333334h426.666667zM170.666667 303.274667v118.784L265.642667 362.666667 170.666667 303.274667zM938.666667 170.666667v85.333333H512V170.666667h426.666667z"
      p-id="2588"
    ></path>
  </svg>
);
const NotesSVG = () => (
  <svg
    className="anticon"
    width="1.25em"
    height="1.25em"
    viewBox="0 0 1024 1024"
  >
    <path
      d="M720.713143 955.355429c29.988571 0 47.140571-21.430857 47.140571-54.436572v-111.414857h20.150857c127.707429 0 196.278857-70.290286 196.278858-196.297143V264.923429c0-125.988571-68.571429-196.278857-196.278858-196.278858H235.995429c-127.268571 0-196.278857 70.710857-196.278858 196.278858v328.283428c0 125.586286 68.992 196.297143 196.278858 196.297143h275.145142l148.297143 131.565714c25.709714 23.149714 40.283429 34.285714 61.275429 34.285715z m-17.554286-78.427429l-136.722286-136.283429c-16.292571-16.713143-28.708571-20.150857-52.717714-20.150857H236.434286c-86.582857 0-127.725714-44.141714-127.725715-127.707428v-327.862857c0-83.565714 41.142857-127.268571 127.725715-127.268572h551.570285c87.003429 0 127.268571 43.702857 127.268572 127.268572v327.862857c0 83.565714-40.265143 127.707429-127.268572 127.707428h-52.297142c-23.570286 0-32.548571 8.996571-32.548572 32.146286z"
      p-id="10162"
    ></path>
  </svg>
);
const BookmarkSVG = () => (
  <svg
    className="anticon"
    width="1.25em"
    height="1.25em"
    viewBox="0 0 1024 1024"
  >
    <path
      d="M804.571 146.286H219.43V855.99L512 575.415l50.834 48.567L804.571 855.99V146.286z m6.876-73.143q13.166 0 25.161 5.12 18.87 7.46 29.989 23.406t11.117 35.4v736.55q0 19.455-11.117 35.4t-29.989 23.406q-10.825 4.535-25.161 4.535-27.429 0-47.397-18.286L512.073 676.352 260.096 918.674q-20.553 18.871-47.397 18.871-13.165 0-25.16-5.12-18.872-7.46-29.99-23.406t-11.117-35.4v-736.55q0-19.455 11.118-35.4t29.988-23.406q11.996-5.12 25.161-5.12H811.52z"
      p-id="3396"
    ></path>
  </svg>
);
const HistorySVG = () => (
  <svg
    className="anticon"
    width="1.25em"
    height="1.25em"
    viewBox="0 0 1024 1024"
  >
    <path
      d="M938.666667 512a384 384 0 0 1-384 384 379.306667 379.306667 0 0 1-220.16-69.546667 21.76 21.76 0 0 1-8.96-15.786666 21.333333 21.333333 0 0 1 5.973333-16.64l30.72-31.146667a21.333333 21.333333 0 0 1 26.88-2.56A294.826667 294.826667 0 0 0 554.666667 810.666667a298.666667 298.666667 0 1 0-298.666667-298.666667h100.693333a20.906667 20.906667 0 0 1 15.36 6.4l8.533334 8.533333a21.333333 21.333333 0 0 1 0 30.293334L229.973333 708.266667a21.76 21.76 0 0 1-30.293333 0l-150.613333-151.04a21.333333 21.333333 0 0 1 0-30.293334l8.533333-8.533333a20.906667 20.906667 0 0 1 15.36-6.4H170.666667a384 384 0 0 1 768 0z m-367.786667-213.333333h-32.426667a21.333333 21.333333 0 0 0-21.333333 21.333333v198.826667a22.613333 22.613333 0 0 0 6.4 14.933333l140.373333 140.373333a21.333333 21.333333 0 0 0 30.293334 0l22.613333-22.613333a21.333333 21.333333 0 0 0 0-30.293333l-124.586667-124.586667V320a21.333333 21.333333 0 0 0-21.333333-21.333333z"
      p-id="11141"
    ></path>
  </svg>
);
const ProfileSVG = () => (
  <svg className="anticon" width="1em" height="1em" viewBox="0 0 1024 1024">
    <path
      d="M1006.87952 873.984c-0.224-2.432-0.544-4.768-0.544-7.008 0-94.784-131.52-204.8-325.312-246.72A271.36 271.36 0 0 0 751.77552 443.264V256.512C751.77552 110.272 648.83152 0 511.77552 0S271.77552 110.272 271.77552 256.512v186.752a259.936 259.936 0 0 0 62.432 184.192C168.73552 670.176 19.23152 763.488 19.23152 868.064c0 2.208-2.176 4.576-2.432 6.944a66.144 66.144 0 0 0 35.776 74.144C142.71952 996.032 313.95152 1024 511.35952 1024s368.896-27.968 459.104-74.848a67.904 67.904 0 0 0 36.416-75.168zM335.77552 443.264V256.512c0-109.28 75.424-191.68 176-191.68S687.77552 147.2 687.77552 256.512v186.752c0 109.28-75.488 191.68-176 191.68s-176-82.4-176-191.68z m605.12 448.224c-80.32 41.6-245.088 67.648-429.984 67.648s-349.632-25.92-429.952-67.616c-1.472-0.8-2.432-1.44-2.848-1.568 0-2.048 0.32-5.696 0.608-8.288 0.48-4.64 0.864-9.216 0.864-13.6 0-57.6 128-159.264 316.096-190.88a239.264 239.264 0 0 0 209.792-3.36c199.328 27.104 336.768 133.792 336.768 193.12 0 4.288 0.384 8.832 0.864 13.536a57.024 57.024 0 0 0 1.184 8.736 13.44 13.44 0 0 1-3.424 2.272z"
      p-id="13682"
    ></path>
  </svg>
);

export function AppSideBar(props) {
  const rootSubmenuKeys = ['sub1', 'sub2', 'sub4'];
  const [openKeys, setOpenKeys] = useState(['sub1']);

  const onOpenChange = openKeys => {
    const latestOpenKey = openKeys.find(key => openKeys.indexOf(key) === -1);
    if (rootSubmenuKeys.indexOf(latestOpenKey) === -1) {
      setOpenKeys(openKeys);
    } else {
      setOpenKeys(latestOpenKey ? [latestOpenKey] : []);
    }
  };

  return (
    <Sider width={252} className="site-layout-background">
      <Row
        style={{ flexDirection: 'column', minHeight: '75vh' }}
        justify="space-between"
        align="middle"
      >
        <Menu
          className="x5-main-menu"
          mode="inline"
          inlineIndent={32}
          openKeys={openKeys}
          onOpenChange={onOpenChange}
          style={{ borderRight: 0 }}
        >
          <SubMenu
            key="sub1"
            title={
              <X5MenuTitle icon={<PlayListSVG />}>My Playlists</X5MenuTitle>
            }
          >
            <Menu.Item key="1">Option 1</Menu.Item>
            <Menu.Item key="2">Option 2</Menu.Item>
            <Menu.Item key="3">Option 3</Menu.Item>
            <Menu.Item key="4">Option 4</Menu.Item>
          </SubMenu>
          <Menu.Divider />
          <SubMenu
            key="sub2"
            title={<X5MenuTitle icon={<BookmarkSVG />}>Bookmarks</X5MenuTitle>}
          >
            <Menu.Item key="5">Option 5</Menu.Item>
            <Menu.Item key="6">Option 6</Menu.Item>
            <SubMenu
              key="sub3"
              title={<X5MenuTitle icon={<NotesSVG />}>Notes</X5MenuTitle>}
            >
              <Menu.Item key="7">Option 7</Menu.Item>
              <Menu.Item key="8">Option 8</Menu.Item>
            </SubMenu>
          </SubMenu>
          <Menu.Divider />
          <SubMenu
            key="sub4"
            title={<X5MenuTitle icon={<NotesSVG />}>Notes</X5MenuTitle>}
          >
            <Menu.Item key="9">Option 9</Menu.Item>
            <Menu.Item key="10">Option 10</Menu.Item>
            <Menu.Item key="11">Option 11</Menu.Item>
            <Menu.Item key="12">Option 12</Menu.Item>
          </SubMenu>
          <Menu.Divider />
          <SubMenu
            key="sub5"
            title={<X5MenuTitle icon={<HistorySVG />}>History</X5MenuTitle>}
          >
            <Menu.Item key="13">Option 9</Menu.Item>
            <Menu.Item key="14">Option 10</Menu.Item>
            <Menu.Item key="15">Option 11</Menu.Item>
            <Menu.Item key="16">Option 12</Menu.Item>
          </SubMenu>
          <Menu.Divider />
          <SubMenu
            key="sub6"
            title={<X5MenuTitle icon={<ProfileSVG />}>My Profile</X5MenuTitle>}
          >
            <Menu.Item key="17">Option 9</Menu.Item>
            <Menu.Item key="18">Option 10</Menu.Item>
            <Menu.Item key="19">Option 11</Menu.Item>
            <Menu.Item key="20">Option 12</Menu.Item>
          </SubMenu>
          <Menu.Divider />
        </Menu>
        <Col flex="auto"></Col>
        <Button type="primary">New Playlist +</Button>
        <Col flex="20px"></Col>
      </Row>
    </Sider>
  );
}
