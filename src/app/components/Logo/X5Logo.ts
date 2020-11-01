import styled, { css } from 'styled-components';
// import logo from './img/x5learn_logo_new.png';
// import white_logo from './img/x5learn_logo_new_white.png';

export const X5Logo = styled.div<{ white?: boolean }>`
  background-image: url('/static/img/x5learn_logo_new.png');
  float: left;
  width: 120px;
  height: 31px;
  margin: 16px 24px 16px 0;
  background-repeat: no-repeat;
  background-size: contain;
  ${props =>
    props.white &&
    css`
      background-image: url('/static/img/x5learn_logo_new_white.png');
    `}
`;
