import styled, { css } from 'styled-components';
// import logo from './img/x5learn_logo_new.png';
// import white_logo from './img/x5learn_logo_new_white.png';

export const X5Logo = styled.div<{ white?: boolean }>`
  background-image: url('/static/img/x5learn_logo_new.png');
  width: 120px;
  height: 24px;
  background-repeat: no-repeat;
  background-size: contain;
  ${props =>
    props.white &&
    css`
      background-image: url('/static/img/x5learn_logo_new_white.png');
    `}
`;
